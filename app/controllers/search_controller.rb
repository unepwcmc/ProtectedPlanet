class SearchController < ApplicationController
  def index
    if @query = params[:q]
      @protected_areas = Search.search @query
    end
  end
end
