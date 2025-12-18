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

    image = Rails.cache.fetch(cache_key, expires_in: 20.days) do
      AssetGenerator.send(method_name, record)
    end

    if image.blank?
      redirect_to ActionController::Base.helpers.asset_path('search-placeholder-country.png', type: :image)
      return
    end

    expires_in 5.days, public: true

    send_data image, type: 'image/png', disposition: 'inline'
  rescue AssetGenerator::AssetGenerationFailedError
    redirect_to ActionController::Base.helpers.asset_path('search-placeholder-country.png', type: :image)
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
