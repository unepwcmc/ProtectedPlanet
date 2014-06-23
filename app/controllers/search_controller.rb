class SearchController < ApplicationController
  RESULTS_LIMIT = 10

  def index
    if @query = params[:q]
      @protected_areas_count = Search.count @query
      @protected_areas = Search.search @query, pagination_options
    end
  end

  private

  def pagination_options
    {
      page: params[:page] || 1,
      limit: RESULTS_LIMIT
    }
  end
end
