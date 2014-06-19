class Download::Shapefile
  SHAPEFILE_PARTS = ['shp', 'shx',  'dbf', 'prj', 'cpg']

  BASE_QUERY = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"
  QUERY_CONDITIONS = {
    polygons: "WHERE ST_GeometryType(the_geom) LIKE '%Poly'",
    points:   "WHERE ST_GeometryType(the_geom) LIKE '%Point'"
  }

  def self.generate zip_path
    download_shapefile = new zip_path
    download_shapefile.generate

    download_shapefile
  end

  def initialize zip_path
    @path = File.dirname(zip_path)
    @filename = File.basename(zip_path, File.extname(zip_path))
  end

  def generate
    shapefile_paths = []

    QUERY_CONDITIONS.each do |name, condition|
      query = "#{BASE_QUERY} #{condition}"
      component_paths = shapefile_components(name)

      export_success = Ogr::Postgres.export :shapefile, component_paths.first, query
      return false unless export_success

      shapefile_paths |= component_paths
    end

    system("zip -j #{zip_path} #{shapefile_paths.join(' ')}")
  end

  private

  def zip_path
    File.join(@path, "#{@filename}.zip")
  end

  def shapefile_components name
    SHAPEFILE_PARTS.collect do |ext|
      File.join(@path, "#{@filename}-#{name}.#{ext}")
    end
  end
end
