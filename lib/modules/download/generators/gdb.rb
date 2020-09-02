class Download::Generators::Gdb < Download::Generators::Base
  QUERY_CONDITIONS = {
    polygons: {
      select: Download::Utils.download_columns,
      where: %{"TYPE" = 'Polygon'}
    },
    points:   {
      select: Download::Utils.download_columns(reject: [:gis_area, :gis_m_area]),
      where: %{"TYPE" = 'Point'}
    }
  }

  def initialize zip_path, wdpa_ids
    @path = File.dirname(zip_path)
    @filename = File.basename(zip_path, File.extname(zip_path))
    @wdpa_ids = wdpa_ids
  end

  def generate
    return false if @wdpa_ids.is_a?(Array) && @wdpa_ids.empty?

    gdb_path = ''

    clean_up_after do
      QUERY_CONDITIONS.each do |name, props|
        gdb_path = export_component name, props
      end

      export_sources

      system("zip -ru #{zip_path} #{File.basename(sources_path)}", chdir: File.dirname(sources_path))
      system("zip -j #{zip_path} #{gdb_path}") and system("zip -ru #{zip_path} *", chdir: ATTACHMENTS_PATH)
    end
  rescue Ogr::Postgres::ExportError
    return false
  end

  private

  def export_component name, props
    component_path = gdb_component(name)
    view_name = create_view query(props[:select], props[:where])

    return [] if ActiveRecord::Base.connection.select_value("""
      SELECT COUNT(*) FROM #{view_name}
    """).to_i.zero?

    export_success = Ogr::Postgres.export(
      :gdb,
      component_path,
      "SELECT * FROM #{view_name}",
      name.singularize
    )

    raise Ogr::Postgres::ExportError unless export_success
    component_path
  end

  def query select, conditions=[]
    query = "SELECT #{select}"
    query << " FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}"
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

  def zip_path
    File.join(@path, "#{@filename}.zip")
  end

  def gdb_component(name)
    File.join(@path, "#{name}.gdb")
  end
end