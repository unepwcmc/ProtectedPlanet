class SearchController < ApplicationController
  RESULTS_LIMIT = 10

  def index
    if @query = params[:q]
      @protected_areas = Search.
        search(@query).
        paginate(:page => params[:page], :per_page => 10)
    end
  end
end
