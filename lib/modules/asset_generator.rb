module AssetGenerator
  class AssetGenerationFailedError < StandardError; end;
  FALLBACK_PATH = Rails.root.join('app/assets/images', 'search-placeholder-country.png')

  def self.protected_area_tile protected_area
    raise AssetGenerationFailedError if protected_area.nil?

    tile_url = mapbox_url protected_area.geojson
    request_tile tile_url
  rescue AssetGenerationFailedError
    ''#fallback_tile
  end

  def self.country_tile country
    raise AssetGenerationFailedError if country.nil?

    tile_url = mapbox_url country.geojson({"fill-opacity" => 0, "stroke-width" => 0})
    request_tile tile_url

  rescue AssetGenerationFailedError
    ''#fallback_tile
  end

  def self.region_tile region
    raise AssetGenerationFailedError if region.nil?

    tile_url = mapbox_url region.geojson({"fill-opacity" => 0, "stroke-width" => 0})
    request_tile tile_url
  rescue AssetGenerationFailedError
    ''#fallback_tile
  end

  private

  def self.mapbox_url geojson
    mapbox_config = Rails.application.secrets.mapbox
    access_token = mapbox_config[:access_token] || mapbox_config['access_token']
    base_url = mapbox_config[:base_url] || mapbox_config['base_url']
    size = {y: 138, x: 304}

    raise AssetGenerationFailedError unless geojson.present?
    
    tile_url = base_url + "geojson(#{geojson})/auto/#{size[:x]}x#{size[:y]}@2x"
    tile_url << "?access_token=#{access_token}"
  end

  def self.request_tile tile_url
    uri = URI(URI.encode(tile_url, '[]'))
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.get(uri.request_uri)
    
    raise AssetGenerationFailedError if response.code != '200'
    
    response.body
  end

  def self.fallback_tile
    @fallback_tile ||= File.read(FALLBACK_PATH)
  end
end
