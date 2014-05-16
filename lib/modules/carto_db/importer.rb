class CartoDb::Importer
  include HTTMultiParty
  require 'gdal-ruby/ogr'

  def initialize username, api_key
    @username = username
    @api_key = api_key
    self.class.base_uri "https://#{username}.cartodb.com/api/v1/imports/"
    @options = { query: { api_key: api_key } }
  end

  def import filename
    import_id = start_import filename
    return import_complete import_id
  end

  def check tablename
    ogr_feature_count = shp_feature_count tablename
    cartodb_feature_count = cartodb_count tablename
    ogr_feature_count == ogr_feature_count 
  end

  private

  def status import_id
    response = self.class.get("/#{import_id}", @options)
    return JSON.parse(response.body)["state"]
  end

  def import_complete import_id
    while state = status(import_id) do
      if ['complete', 'failure'].include? state
        return state == 'complete'
      end
    end
  end

  def start_import filename
    options = @options.merge({
      file: File.open(filename, 'r'),
      detect_mime_type: true
    })

    response = self.class.post("/", options)
    return JSON.parse(response.body)["item_queue_id"]
  end

  def cartodb_count tablename
    count_query = count_query tablename
    count_options = { query: { q: count_query, api_key: @api_key } }
    self.class.get("https://#{@username}.cartodb.com/api/v1", count_options)
    return JSON.parse(response.body)["rows"][0]["count"]
  end

  def shp_feature_count tablename
    ogr_driver = Gdal::Ogr.open("#{tablename}.shp")
    layer = ogr_driver.get_layer(0)
    return layer.get_feature_count
  end

  def count_query tablename
    "SELECT COUNT(*) FROM #{tablename}"
  end

end
