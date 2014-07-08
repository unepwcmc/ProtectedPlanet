class SearchController < ApplicationController
  def index
    return unless @query = params[:q]

    pagination_opts = {page: params[:page], per_page: 10}
    @search = Search.search(@query)
    @protected_areas = @search.results.paginate(pagination_opts)

    if @protected_areas.length == 0
      @similar_search = true
      @search = Search.search_similar_to(@query)
      @protected_areas = @search.results
    end
  end
end
