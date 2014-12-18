module AssetGenerator
  class AssetGenerationFailedError < StandardError; end;
  FALLBACK_PATH = Rails.root.join('app/assets/images', 'search-placeholder-country.png')

  def self.protected_area_tile protected_area, opts={size: {x: 128, y: 256}}
    tile_url = mapbox_url protected_area.geojson, opts[:size]

    request_tile tile_url[:host], tile_url[:path]
  rescue AssetGenerationFailedError
    fallback_tile
  end

  def self.link_to asset_id
    file_name = "tiles/#{asset_id}"
    S3.link_to file_name
  end

  private

  def self.mapbox_url geojson, size
    access_token = Rails.application.secrets.mapbox['access_token']
    uri = URI(Rails.application.secrets.mapbox['base_url'])

    path = uri.path
    path << "geojson(#{geojson})/auto/#{size[:x]}x#{size[:y]}@2x.png"
    path << "?access_token=#{access_token}"

    {host: uri.host, path: path}
  end

  def self.request_tile host, path
    res = Net::HTTP.get_response(host, path)
    raise AssetGenerationFailedError if res.code != '200'

    res.body
  end

  def self.fallback_tile
    @fallback_tile ||= File.read(FALLBACK_PATH)
  end
end
