module AssetGenerator
  class AssetGenerationFailedError < StandardError; end;

  def self.protected_area_tile protected_area, opts={size: {x: 128, y: 256}}
    tile_url = if protected_area.images.any?
      panoramio_url protected_area.images.first.url
    else
      mapbox_url protected_area.geojson, opts[:size]
    end

    request_tile tile_url[:host], tile_url[:path]
  end

  private

  def self.panoramio_url url
    uri = URI(url)
    {host: uri.host, path: uri.path}
  end

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
end
