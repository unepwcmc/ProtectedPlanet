class AssetsController < ApplicationController
  def tiles
    image = AssetGenerator.protected_area_tile(protected_area)
    send_data image, type: 'image/png', disposition: 'inline'
  rescue AssetGenerator::AssetGenerationFailedError
    redirect_to ActionController::Base.helpers.asset_path('search-placeholder-country.png', type: :image)
  end

  private

  def protected_area
    @protected_area ||= ProtectedArea.where(wdpa_id: params[:id]).first
  end
end
