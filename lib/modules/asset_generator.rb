module AssetGenerator
  class AssetGenerationFailedError < StandardError; end;
  FALLBACK_PATH = Rails.root.join('app/assets/images', 'search-placeholder-country.png')

  def self.protected_area_tile protected_area
    raise AssetGenerationFailedError if protected_area.nil?

    # Try original detailed geometry first
    begin
      tile_url = mapbox_url protected_area.geojson
      return request_tile tile_url
    rescue AssetGenerationFailedError
      # If original fails, try simplified version
      begin
        tile_url = mapbox_url protected_area.geojson_for_tile
        return request_tile tile_url
      rescue AssetGenerationFailedError
        # If simplified also fails, return empty string to trigger placeholder
        return ''
      end
    end
  end

  def self.country_tile country
    raise AssetGenerationFailedError if country.nil?

    geo_properties = {"fill-opacity" => 0, "stroke-width" => 0}

    # Try original detailed geometry first
    begin
      tile_url = mapbox_url country.geojson(geo_properties)
      return request_tile tile_url
    rescue AssetGenerationFailedError
      # If original fails, try simplified version
      begin
        tile_url = mapbox_url country.geojson_for_tile(geo_properties)
        return request_tile tile_url
      rescue AssetGenerationFailedError
        # If simplified also fails, return empty string to trigger placeholder
        return ''
      end
    end
  end

  def self.region_tile region
    raise AssetGenerationFailedError if region.nil?

    geo_properties = {"fill-opacity" => 0, "stroke-width" => 0}

    # Try original detailed geometry first
    begin
      tile_url = mapbox_url region.geojson(geo_properties)
      return request_tile tile_url
    rescue AssetGenerationFailedError
      # If original fails, try simplified version
      begin
        tile_url = mapbox_url region.geojson_for_tile(geo_properties)
        return request_tile tile_url
      rescue AssetGenerationFailedError
        # If simplified also fails, return empty string to trigger placeholder
        return ''
      end
    end
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

    request = Net::HTTP::Get.new(uri)
    # As we have set whitelist to only allow pp server/urls to use the mapbox token
    # so we need to set referer header so mapbox knows the request comes from pp server
    # see https://docs.mapbox.com/accounts/guides/tokens/#url-restrictions
    # and https://console.mapbox.com/account/access-tokens/
    request['Referer'] = Rails.application.routes.url_helpers.root_url

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    response = http.request(request)
    raise AssetGenerationFailedError if response.code != '200'

    response.body
  rescue StandardError
    # fall back to a placeholder.
    raise AssetGenerationFailedError
  end

  def self.fallback_tile
    @fallback_tile ||= File.read(FALLBACK_PATH)
  end
end
