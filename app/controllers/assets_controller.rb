class AssetsController < ApplicationController
  TYPES = %w[protected_area country region].freeze

  def tiles
    area_type = params[:type]
    raise_404 unless TYPES.include?(area_type)
    record = find_record(area_type)
    raise_404 if record.nil?

    cache_key = [
      'tiles',
      'image',
      area_type,
      params[:id].to_s,
      (record.respond_to?(:updated_at) && record.updated_at ? record.updated_at.to_i : 'na')
    ].join(':')

    image = Rails.cache.fetch(cache_key, expires_in: CACHE_FETCH_TTL) do
      generate_tile(area_type, record)
    end

    if image.blank?
      redirect_to '/images/search-placeholder-country.png'
      return
    end

    # Set here rather than in Middleware::CacheHeaders, which sits ABOVE
    # Rack::Cache: a header stamped there is applied after Rack::Cache has already
    # judged the response uncacheable, so tiles would never be stored and every
    # request would pay the record lookup above. The value stays shared.
    #
    # Guarded: false in dev without tmp/caching-dev.txt, where the tile is
    # regenerated every request anyway, so a year-long browser TTL only gets in
    # the way. Always true in staging/production.
    if perform_caching
      response.headers['Cache-Control'] = Middleware::CacheHeaders.long_lived
    end

    send_data image, type: 'image/png', disposition: 'inline'
  rescue AssetGenerator::AssetGenerationFailedError
    redirect_to '/images/search-placeholder-country.png'
  end

  private

  def find_record(area_type)
    case area_type
    when 'protected_area' then ProtectedArea.find_by(site_id: params[:id])
    when 'country' then Country.find_by(iso: params[:id])
    when 'region' then Region.find_by(iso: params[:id])
    end
  end

  def generate_tile(area_type, record)
    case area_type
    when 'protected_area' then AssetGenerator.protected_area_tile(record)
    when 'country' then AssetGenerator.country_tile(record)
    when 'region' then AssetGenerator.region_tile(record)
    end
  end
end
