class SearchController < ApplicationController
  RESULTS_LIMIT = 10

  def index
    if @query = params[:q]
      @protected_areas_count = Search.count @query

      @page_number = page_number
      @page_count = (@protected_areas_count / RESULTS_LIMIT.to_f).ceil

      @protected_areas = Search.search @query, pagination_options
    end
  end

  private

  def page_number
    (params[:page] || 1).to_i
  end

  def pagination_options
    {
      page: page_number,
      limit: RESULTS_LIMIT
    }
  end
end
