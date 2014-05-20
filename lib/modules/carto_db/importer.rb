class CartoDb::Importer
  def initialize cartodb_options, logger = Logger.new(STDOUT)
    @username = cartodb_options[:username]
    @api_key = cartodb_options[:api_key]
    @logger = logger
  end

  def import
    @logger.info "Splitting file..."
    ogr_split = Ogr::Split.new
    shapefiles = ogr_split.split '/Users/adammulligan/tmp/pp/WDPA_Apr2014.gdb', 'WDPA_poly_Apr2014', 5
    shapefiles.map! { |path| Shapefile.new path }

    shapefiles.each do |shapefile|
      @logger.info "Uploading #{shapefile.path}..."
      cartodb_uploader = CartoDb::Uploader.new @username, @api_key
      @logger.info cartodb_uploader.upload shapefile.compress
    end

    @logger.info "Merging files..."
    cartodb_merger = CartoDb::Merger.new @username, @api_key

    table_names = shapefiles.map { |s| s.filename }
    @logger.info cartodb_merger.merge table_names, shapefiles.first.columns
  end
end
