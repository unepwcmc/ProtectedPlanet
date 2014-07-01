class Download::Shapefile < Download::Generator
  SHAPEFILE_PARTS = ['shp', 'shx',  'dbf', 'prj', 'cpg']

  QUERY_CONDITIONS = {
    polygons: "ST_GeometryType(wkb_geometry) LIKE '%Poly%'",
    points:   "ST_GeometryType(wkb_geometry) LIKE '%Point%'"
  }

  def initialize zip_path, wdpa_ids
    @path = File.dirname(zip_path)
    @filename = File.basename(zip_path, File.extname(zip_path))
    @wdpa_ids = wdpa_ids
  end

  def generate
    shapefile_paths = []

    clean_up_after do
      QUERY_CONDITIONS.each do |name, condition|
        shapefile_paths |= export_component name, condition
      end

      system("zip -j #{zip_path} #{shapefile_paths.join(' ')}")
    end
  rescue Ogr::Postgres::ExportError
    return false
  end

  private

  def export_component name, condition
    component_paths = shapefile_components(name)

    export_success = nil
    with_view query(condition) do |view_name|
      export_success = Ogr::Postgres.export(
        :shapefile,
        component_paths.first,
        "SELECT * FROM #{view_name}"
      )
    end

    raise Ogr::Postgres::ExportError unless export_success

    component_paths
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

  def shapefile_components name
    SHAPEFILE_PARTS.collect do |ext|
      File.join(@path, "#{@filename}-#{name}.#{ext}")
    end
  end
end
