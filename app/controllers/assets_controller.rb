class AssetsController < ApplicationController
  TYPES = %w(protected_area country region).freeze

  def tiles
    area_type = params[:type]
    raise_404 unless TYPES.include?(area_type)
    method_name = "#{area_type}_tile"
    image = AssetGenerator.send(method_name, send(area_type))

    send_data image, type: 'image/png', disposition: 'inline'
  rescue AssetGenerator::AssetGenerationFailedError
    redirect_to ActionController::Base.helpers.asset_path('search-placeholder-country.png', type: :image)
  end

  private

  def protected_area
    @protected_area ||= ProtectedArea.where(wdpa_id: params[:id]).first
  end

  def country
    @country ||= Country.where(iso: params[:id]).first
  end

  def region
    @region ||= Region.where(iso: params[:id]).first
  end
end
