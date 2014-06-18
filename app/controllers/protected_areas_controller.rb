class ProtectedAreasController < ApplicationController
  def show
    id = params[:id]
    @protected_area = ProtectedArea.where("slug = ? OR wdpa_id = ?", id, id.to_i).first
    @wikipedia_article = @protected_area.try(:wikipedia_article)
  end
end
