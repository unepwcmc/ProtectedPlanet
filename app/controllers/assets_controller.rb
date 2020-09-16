class AssetsController < ApplicationController
  def tiles
    if params[:type] == "protected_area"
      image = AssetGenerator.protected_area_tile(protected_area)
    elsif params[:type] == "country"
      image = AssetGenerator.country_tile(country)
    elsif params[:type] == "region"
      image = AssetGenerator.region_tile(region)
    else
      raise_404
    end

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
