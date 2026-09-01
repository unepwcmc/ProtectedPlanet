module AssetGenerator
  class AssetGenerationFailedError < StandardError; end;
  FALLBACK_PATH = Rails.root.join('public/images', 'search-placeholder-country.png')

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
    mapbox_config = AppSecrets.mapbox
    access_token = mapbox_config[:access_token] || mapbox_config['access_token']
    base_url = mapbox_config[:base_url] || mapbox_config['base_url']
    size = {y: 138, x: 304}

    raise AssetGenerationFailedError unless geojson.present?

    # The GeoJSON goes inside the URL path and always contains characters that are
    # not legal in a URI (notably {, }, [, ]), so it has to be escaped here. Escaping
    # the whole URL afterwards is not an option: it would also escape the ? and =
    # of the query string. URI::DEFAULT_PARSER.escape (nee URI.escape) only escapes
    # a narrow "unsafe" set and leaves reserved chars like [ ] : , untouched, which
    # the stricter RFC3986 URI parser on Ruby 3.3 then rejects as an invalid URI -
    # ERB::Util.url_encode percent-encodes everything outside RFC 3986 unreserved chars.
    tile_url = base_url + "geojson(#{ERB::Util.url_encode(geojson)})/auto/#{size[:x]}x#{size[:y]}@2x"
    tile_url << "?access_token=#{access_token}"
  end

  # URI::DEFAULT_PARSER.escape leaves [ and ] alone: its default unsafe pattern
  # treats them as safe because RFC 2396 reserves them for IPv6 literals in the
  # HOST component. Every GeoJSON geometry is full of them -- "coordinates":
  # [[[-61.8,17.1],...]] -- so they survived into the path, and URI() then
  # rejected the result outright:
  #
  #   URI::InvalidURIError (bad URI (is not URI?): "https://api.mapbox.com/...
  #     geojson(%7B..."coordinates":[[[-61.825,17.185],...]]]%7D%7D)/auto/304x138@2x...")
  #
  # so /assets/tiles/:id 500'd for every area type. This is the RFC 2396 default
  # unsafe set with \[ and \] removed, i.e. identical behaviour except brackets are
  # now percent-encoded. Verified against the live Mapbox API: the previous form
  # fails to parse, this one returns a 200 with real PNG bytes.
  UNSAFE_IN_PATH = /[^\-_.!~*'()a-zA-Z\d;\/?:@&=+$,]/

  def self.escape_for_path(value)
    URI::DEFAULT_PARSER.escape(value, UNSAFE_IN_PATH)
  end

  def self.request_tile tile_url
    # NB: URI.encode was removed in Ruby 3.0; the URL is escaped in mapbox_url.
    uri = URI(tile_url)
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
  end

  def self.fallback_tile
    @fallback_tile ||= File.read(FALLBACK_PATH)
  end
end
