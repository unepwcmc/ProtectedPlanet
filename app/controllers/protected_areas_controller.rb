class ProtectedAreasController < ApplicationController
  after_filter :enable_caching

  def show
    id = params[:id]
    @protected_area = ProtectedArea.
      without_geometry.
      where("slug = ? OR wdpa_id = ?", id, id.to_i).
      first

    @country = @protected_area.countries.first
    @region  = @country.region

    @wikipedia_article = @protected_area.try(:wikipedia_article)
  end
end
