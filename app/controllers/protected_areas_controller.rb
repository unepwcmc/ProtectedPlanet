class ProtectedAreasController < ApplicationController
  after_filter :enable_caching

  def show
    id = params[:id]
    @protected_area = ProtectedArea.
      without_geometry.
      where("slug = ? OR wdpa_id = ?", id, id.to_i).
      first

    return render_404 if @protected_area.blank?

    @country = @protected_area.countries.first
    @region  = @country.region

    @wikipedia_article = @protected_area.try(:wikipedia_article)
  end

  private

  def render_404
    render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
  end
end
