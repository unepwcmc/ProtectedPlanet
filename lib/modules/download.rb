class Download
  BASE_QUERY = "SELECT * FROM #{Wdpa::Release::IMPORT_VIEW_NAME}"

  TYPES = {
    csv: {
      driver: :csv,
      query: BASE_QUERY,
      file_extension: 'csv'
    },
    shapefile_polygons: {
      driver: :shapefile,
      query: [BASE_QUERY, "WHERE ST_GeometryType(the_geom) ILIKE '%poly%'"].join(' '),
      file_extension: 'shp'
    },
    shapefile_points: {
      driver: :shapefile,
      query: [BASE_QUERY, "WHERE ST_GeometryType(the_geom) ILIKE '%point%'"].join(' '),
      file_extension: 'shp'
    },
    kml: {
      driver: :kml,
      query: BASE_QUERY,
      file_extension: 'kml'
    }
  }

  def self.generate
    download = self.new
    download.generate
    download
  end

  def initialize
    @start_time = Time.now
  end

  def generate
    TYPES.each do |type, _|
      generate type
    end
  end

  private

  def generate type
    query = TYPES[type][:query]
    driver = TYPES[type][:driver]
    Ogr::Postgres.export(driver, path_for(type), query.squish)
  end

  def path_for type
    File.join(tmp_path, "all_#{type}_#{start_time}.#{TYPES[type][:file_extension]}")
  end

  def tmp_path
    File.join(Rails.root, 'tmp')
  end

  def start_time
    @start_time.strftime("%Y-%m-%d-%H%M")
  end
end
