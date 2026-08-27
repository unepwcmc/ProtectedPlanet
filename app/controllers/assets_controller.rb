class AssetsController < ApplicationController
  TYPES = %w[protected_area country region].freeze

  def tiles
    area_type = params[:type]
    raise_404 unless TYPES.include?(area_type)
    method_name = "#{area_type}_tile"
    record = send(area_type)
    raise_404 if record.nil?

    cache_key = [
      'tiles',
      'image',
      area_type,
      params[:id].to_s,
      (record.respond_to?(:updated_at) && record.updated_at ? record.updated_at.to_i : 'na')
    ].join(':')

    image = Rails.cache.fetch(cache_key, expires_in: CACHE_FETCH_TTL) do
      AssetGenerator.send(method_name, record)
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

  def protected_area
    @protected_area ||= ProtectedArea.where(site_id: params[:id]).first
  end

  def country
    @country ||= Country.where(iso: params[:id]).first
  end

  def region
    @region ||= Region.where(iso: params[:id]).first
  end
end
