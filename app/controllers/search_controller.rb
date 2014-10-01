class SearchController < ApplicationController
  def index
    return unless @query = params[:q]

    @search = Search.search(@query, search_options)
  end

  private

  def search_options
    options = {filters: filters}
    options[:page] = params[:page].to_i if params[:page].present?
    options
  end

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
