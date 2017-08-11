class GreenListController < ApplicationController
  # Show page for green listed protected areas
  # Will only show if that area is a green listed area, otherwise redirects to wdpa page
  before_filter :find_protected_area
  before_filter :redirect_if_not_green_listed
  after_filter :record_visit
  after_filter :enable_caching

  def show
    @presenter = ProtectedAreaPresenter.new @protected_area
    @countries = @protected_area.countries.without_geometry
    @other_designations = []
    @networks = []

    @wikipedia_article = @protected_area.try(:wikipedia_article)
  end

  def record_visit
    return if @protected_area.nil?

    year_month = DateTime.now.strftime("%m-%Y")
    $redis.zincrby(year_month, 1, @protected_area.wdpa_id)
  end

  private
    def redirect_if_not_green_listed
      redirect_to protected_area_path(@protected_area) unless @protected_area.is_green_list
    end

    def find_protected_area
      id = params[:id]
      @protected_area = ProtectedArea.
        where("slug = ? OR wdpa_id = ?", id, id.to_i).
        first

      @protected_area or raise_404
    end
end
