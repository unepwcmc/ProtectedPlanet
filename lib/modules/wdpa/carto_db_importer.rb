class Wdpa::CartoDbImporter
  def self.import wdpa_release
    importer = new(wdpa_release)
    importer.import
  end

  def initialize wdpa_release
    @wdpa_release = wdpa_release
    @shapefiles = {}
    @cartodb_username = Rails.application.secrets.cartodb_username
    @cartodb_api_key = Rails.application.secrets.cartodb_api_key
  end

  def import
    split and upload and merge
  end

  private

  STANDARD_COLUMNS = ['wdpaid', 'SHAPE']
  CARTODB_COLUMNS = ['wdpaid', 'the_geom']

  def split
    @wdpa_release.geometry_tables.each do |table, _|
      @shapefiles[table] =
        Ogr::Split.split(@wdpa_release.gdb_path, table, 5, STANDARD_COLUMNS)
    end
  end

  def upload
    @shapefiles.each do |table_name, shapefiles|
      shapefiles.each do |shapefile|
        cartodb_uploader = CartoDb::Uploader.new @cartodb_username, @cartodb_api_key

        upload_successful = cartodb_uploader.upload shapefile.compress
        return false unless upload_successful
      end
    end
  end

  def merge
    @shapefiles.each do |table_name, shapefiles|
      table_names = shapefiles.map(&:filename)
      cartodb_merger = CartoDb::Merger.new @cartodb_username, @cartodb_api_key
      cartodb_merger.merge table_names, CARTODB_COLUMNS
    end
  end
end
