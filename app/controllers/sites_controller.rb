class SitesController < ApplicationController
  def show
    if protected_area.present?
      return redirect_to protected_area_url(protected_area.slug)
    end

    redirect_to root_url
  end

  private

  def protected_area
    ProtectedArea.where(
      wdpa_id: params[:id].to_i
    ).first
  end
end
