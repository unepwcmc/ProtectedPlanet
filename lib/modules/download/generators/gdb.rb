class Download::Generators::Gdb < Download::Generators::Base
  QUERY_CONDITIONS = {
    multipolygons: {
      select: Download::Utils.download_columns,
      where: %("TYPE" = 'Polygon')
    },
    multipoints: {
      select: Download::Utils.download_columns(reject: %i[gis_area gis_m_area]),
      where: %("TYPE" = 'Point')
    }
  }.freeze

  def initialize(zip_path, site_ids)
    super(zip_path, site_ids)
    @path = File.dirname(zip_path)
    @filename = File.basename(zip_path, File.extname(zip_path))
  end

  def generate
    return false if @site_ids.is_a?(Array) && @site_ids.empty?

    clean_up_after do
      QUERY_CONDITIONS.each do |name, props|
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
    view_name = create_view query(props[:select], props[:where])

    return [] if ActiveRecord::Base.connection.select_value("
      SELECT COUNT(*) FROM #{view_name}
    ").to_i.zero?

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
