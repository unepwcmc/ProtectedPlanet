class CartoDb::Importer
  def initialize cartodb_options, logger = Logger.new(STDOUT)
    @username = cartodb_options[:username]
    @api_key = cartodb_options[:api_key]
    @logger = logger
  end

  def import filename, layer_name
    @logger.info "Splitting file..."
    ogr_split = Ogr::Split.new
    shapefiles = ogr_split.split filename, layer_name, 5, ['wdpaid', 'SHAPE']
    shapefiles.map! { |path| Shapefile.new path }

    shapefiles.each do |shapefile|
      @logger.info "Uploading #{shapefile.path}..."
      cartodb_uploader = CartoDb::Uploader.new @username, @api_key
      upload_successful = cartodb_uploader.upload shapefile.compress

      @logger.info upload_successful
      unless upload_successful
        @logger.error "Failed to upload #{shapefile.path}"
        return
      end
    end

    @logger.info "Merging files..."
    cartodb_merger = CartoDb::Merger.new @username, @api_key

    table_names = shapefiles.map { |s| s.filename }
    @logger.info cartodb_merger.merge table_names, ['wdpaid', 'the_geom']
  end
end
