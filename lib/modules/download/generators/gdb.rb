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

    gdb_paths = []

    clean_up_after do
      QUERY_CONDITIONS.each do |name, props|
        gdb_paths << export_component(name, props)
      end

      export_sources

      #system("zip -ru #{zip_path} #{File.basename(sources_path)}", chdir: File.dirname(sources_path))
      system("zip -r #{zip_path} #{gdb_filenames(gdb_paths)}", chdir: @path) and add_attachments
    end
  rescue Ogr::Postgres::ExportError
    return false
  end

  private

  def export_component name, props
    component_path = gdb_component
    view_name = create_view query(props[:select], props[:where])

    return [] if ActiveRecord::Base.connection.select_value("""
      SELECT COUNT(*) FROM #{view_name}
    """).to_i.zero?

    export_success = Ogr::Postgres.export(
      :gdb,
      component_path,
      "SELECT * FROM #{view_name}",
      name.to_s.singularize
    )

    raise Ogr::Postgres::ExportError unless export_success
    component_path
  end

  def query select, conditions=[]
    query = "SELECT #{select}"
    query << " FROM #{Wdpa::Release::DOWNLOADS_VIEW_NAME}"
    add_conditions(query, conditions).squish
  end

  def export_sources
    _query = <<-SQL
      SELECT #{Download::Utils.source_columns}
      FROM standard_sources
    SQL

    Ogr::Postgres.export(:gdb, gdb_component, _query, 'source')
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

  def gdb_filenames(gdb_paths)
    gdb_paths.flatten.compact.uniq.map { |p| p.split('/').last }.join(' ')
  end
end