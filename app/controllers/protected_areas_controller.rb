class ProtectedAreasController < ApplicationController
  def show
    id = params[:id]
    @protected_area = ProtectedArea.where("slug = ? OR wdpa_id = ?", id, id.to_i).first
  end
end
