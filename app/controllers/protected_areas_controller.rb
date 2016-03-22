class ProtectedAreasController < ApplicationController
  after_filter :record_visit
  after_filter :enable_caching

  def show
    id = params[:id]
    @protected_area = ProtectedArea.
      where("slug = ? OR wdpa_id = ?", id, id.to_i).
      first

    return render_404 if @protected_area.blank?

    @presenter = ProtectedAreaPresenter.new @protected_area
    @country = @protected_area.countries.without_geometry.first
    @region  = @country.try(:region)

    @wikipedia_article = @protected_area.try(:wikipedia_article)
  end

  private

  def render_404
    render :file => "#{Rails.root}/public/404.html", :layout => false, :status => :not_found
  end

  def record_visit
    return if @protected_area.nil?

    year_month = DateTime.now.strftime("%m-%Y")
    $redis.zincrby(year_month, 1, @protected_area.wdpa_id)
  end
end
