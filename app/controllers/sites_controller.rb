class SitesController < ApplicationController
  def show
    if legacy_protected_area.present? && new_protected_area.present?
      return redirect_to protected_area_url(new_protected_area.slug)
    end

    redirect_to root_url
  end

  private

  def new_protected_area
    ProtectedArea.where(
      wdpa_id: legacy_protected_area.wdpa_id
    ).first
  end

  def legacy_protected_area
    id = params[:id]

    LegacyProtectedArea.
      where("slug = ? OR wdpa_id = ?", id, id.to_i).
      first
  end
end
