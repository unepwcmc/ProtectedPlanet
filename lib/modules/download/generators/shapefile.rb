class Download::Generators::Shapefile < Download::Generators::Base
  TYPE = 'shapefile'.freeze
  SHAPEFILE_PARTS = %w[shp shx dbf prj cpg]

  QUERY_CONDITIONS = {
    polygons: {
      select: Download::Utils.download_columns,
      where: %("TYPE" = 'Polygon')
    },
    points: {
      select: Download::Utils.download_columns(reject: %i[gis_area gis_m_area]),
      where: %("TYPE" = 'Point')
    }
  }.freeze

  def initialize(zip_path, site_ids, number_of_pieces = 3)
    super(zip_path, site_ids)
    @path = File.dirname(zip_path)
    @filename = File.basename(zip_path, File.extname(zip_path))
    # If there are 2 areas involved max, generate just one shp
    @number_of_pieces = site_ids.size > 2 || site_ids.blank? ? number_of_pieces : 1
  end

  def generate
    return false if @site_ids.is_a?(Array) && @site_ids.empty?

    shapefile_paths = []

    @number_of_pieces.times do |i|
      clean_up_after do
        QUERY_CONDITIONS.each do |name, props|
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
    order_by = 'ORDER BY \""SITE_ID"\" ASC'
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
    query << " FROM #{Wdpa::Portal::Config::PortalImportConfig::PORTAL_VIEWS['downloads']}"
    add_conditions(query, conditions).squish
  end

  def clean_up_after
    return_value = yield
    clean_up

    return_value
  end

  def clean_up
    QUERY_CONDITIONS.each do |name, _|
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

    system("zip -j #{zip_path} #{files_paths}") and
      add_sources and
      add_attachments and
      add_shapefile_readme

    range.each { |i| FileUtils.rm_rf(zip_path(i)) }
  end
end
