class Download::Generators::Shapefile < Download::Generators::Base
  TYPE = 'shapefile'.freeze
  SHAPEFILE_PARTS = %w[shp shx dbf prj cpg]

  # Built per call rather than frozen into a constant: the SELECT list comes from
  # Download::Utils.download_columns, which queries `releases`. As a constant it
  # ran at class-load time, so a portal release completing while the app was up
  # left downloads emitting the previous release's column list until restart.
  def self.query_conditions
    {
      polygons: {
        select: Download::Utils.download_columns,
        where: %("TYPE" = 'Polygon')
      },
      points: {
        select: Download::Utils.download_columns(reject: %i[gis_area gis_m_area]),
        where: %("TYPE" = 'Point')
      }
    }.freeze
  end

  def initialize(zip_path, selection_entries, number_of_pieces = 3)
    super(zip_path, selection_entries)
    @path = File.dirname(zip_path)
    @filename = File.basename(zip_path, File.extname(zip_path))
    # If there are 2 or fewer selected sites/parcels, generate just one shp
    selection_count = selection_entries.is_a?(Hash) ? (Array(selection_entries[:site_ids]).size + Array(selection_entries[:site_id_and_pid_pairs]).size) : 0
    @number_of_pieces = selection_count <= 2 && selection_count.positive? ? 1 : number_of_pieces
  end

  def generate
    return false if selection_entries_empty?

    shapefile_paths = []

    @number_of_pieces.times do |i|
      clean_up_after do
        self.class.query_conditions.each do |name, props|
          shapefile_paths |= export_component name, props, i
        end

        export_sources

        system("zip -j #{zip_path(i)} #{shapefile_paths.join(' ')}")
      end
    end
    merge_files
  rescue Ogr::Postgres::ExportError
    false
  end

  private

  def export_component(name, props, piece_index)
    component_paths = shapefile_components(name)
    view_name = create_view query(props[:select], props[:where])

    total_count = ActiveRecord::Base.connection.select_value("
      SELECT COUNT(*) FROM #{view_name}
    ").to_i

    return [] if total_count.zero?

    limit = (total_count / @number_of_pieces.to_f).ceil
    offset = limit * piece_index
    order_by = %(ORDER BY "#{Download::Config.download_view_column_names[:site_id]}" ASC)

    sql = "
      SELECT *
      FROM #{view_name}
      #{order_by if name.to_s == 'polygons'}
      LIMIT #{limit} OFFSET #{offset}
    ".squish

    export_success = Ogr::Postgres.export(
      :shapefile,
      component_paths.first,
      sql
    )

    raise Ogr::Postgres::ExportError unless export_success

    component_paths
  end

  def query(select, conditions = [])
    query = "SELECT #{select}"
    query << " FROM #{Download::Config.downloads_view}"
    add_conditions(query, conditions).squish
  end

  def clean_up_after
    return_value = yield
    clean_up

    return_value
  end

  def clean_up
    self.class.query_conditions.each do |name, _|
      FileUtils.rm_rf shapefile_components(name)
    end
  end

  def zip_path(index = '')
    base_filename = index.present? ? "#{@filename}_#{index}" : @filename
    File.join(@path, "#{base_filename}.zip")
  end

  def shapefile_components(name)
    SHAPEFILE_PARTS.collect do |ext|
      File.join(@path, "#{@filename}-#{name}.#{ext}")
    end
  end

  def merge_files
    range = (0..@number_of_pieces - 1)
    files_paths = range.map { |i| zip_path(i) }.join(' ')

    # Capture the result of the zip chain: it is this method's (and therefore
    # #generate's) success value. Previously the chain's result was discarded and
    # the trailing `range.each` (which returns the range, always truthy) was
    # returned instead, so a failed zip was reported as a successful download.
    zipped = system("zip -j #{zip_path} #{files_paths}") &&
      add_sources &&
      add_attachments &&
      add_shapefile_readme

    # Always clean up the piece zips, even if the merge failed.
    range.each { |i| FileUtils.rm_rf(zip_path(i)) }

    zipped
  end
end
