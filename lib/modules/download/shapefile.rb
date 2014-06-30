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
        component_paths = shapefile_components(name)

        export_success = Ogr::Postgres.export :shapefile, component_paths.first, query(condition)
        return false unless export_success

        shapefile_paths |= component_paths
      end

      system("zip -j #{zip_path} #{shapefile_paths.join(' ')}")
    end
  end

  private

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
