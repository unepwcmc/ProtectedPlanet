class Download::Generators::Gdb < Download::Generators::Base
  # See Download::Generators::Shapefile.query_conditions -- built per call so the
  # column list reflects the current release rather than the one at class load.
  def self.query_conditions
    {
      multipolygons: {
        select: Download::Utils.download_columns,
        where: %("TYPE" = 'Polygon'),
        cast_geom_to_multi: true
      },
      multipoints: {
        select: Download::Utils.download_columns(reject: %i[gis_area gis_m_area]),
        where: %("TYPE" = 'Point')
      }
    }.freeze
  end

  def initialize(zip_path, selection_entries)
    super(zip_path, selection_entries)
    @path = File.dirname(zip_path)
    @filename = File.basename(zip_path, File.extname(zip_path))
  end

  def generate
    return false if selection_entries_empty?

    clean_up_after do
      self.class.query_conditions.each do |name, props|
        export_component(name, props)
      end

      export_sources

      system("zip -r #{zip_path} #{gdb_filename}", chdir: @path) and add_attachments
    end
  rescue Ogr::Postgres::ExportError
    false
  end

  private

  def export_component(name, props)
    component_path = gdb_component
    select = props[:cast_geom_to_multi] ? with_multi_geom(props[:select]) : props[:select]
    view_name = create_view query(select, props[:where])

    row_count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM #{view_name}").to_i
    # Rails.logger.info "[GDB export] #{name}: #{row_count} rows in view #{view_name}"
    return [] if row_count.zero?

    export_success = Ogr::Postgres.export(
      :gdb,
      component_path,
      "SELECT * FROM #{view_name}",
      name.to_s.singularize
    )

    raise Ogr::Postgres::ExportError unless export_success

    component_path
  end

  def query(select, conditions = [])
    query = "SELECT #{select}"
    query << " FROM #{Download::Config.downloads_view}"
    add_conditions(query, conditions).squish
  end

  # Wraps "WKB_GEOMETRY" in ST_Multi() so every polygon feature is MULTIPOLYGON
  # before it reaches the OpenFileGDB driver, preventing -skipfailures from silently
  # dropping features whose stored geometry type is POLYGON rather than MULTIPOLYGON.
  # Still required under OpenFileGDB: it writes the layer as Multi Polygon too.
  def with_multi_geom(select)
    select.sub('"WKB_GEOMETRY"', 'ST_Multi("WKB_GEOMETRY") AS "WKB_GEOMETRY"')
  end

  def export_sources
    query = <<-SQL
      SELECT #{Download::Utils.source_columns}
      FROM #{Download::Config.sources_view}
    SQL

    Ogr::Postgres.export(:gdb, gdb_component, query, 'source')
  end

  def clean_up_after
    return_value = yield
    clean_up

    return_value
  end

  def clean_up
    FileUtils.rm_rf gdb_component
  end

  def zip_path
    File.join(@path, "#{@filename}.zip")
  end

  def gdb_component
    File.join(@path, "#{@filename}.gdb")
  end

  def gdb_filename
    gdb_component.split('/').last
  end
end
