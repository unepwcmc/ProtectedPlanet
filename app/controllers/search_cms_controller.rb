class SearchCmsController < ApplicationController
  include Concerns::Searchable

  before_action :load_search, only: [:index]

  def index
    _options = {
      page: search_params[:requested_page],
      per_page: search_params[:items_per_page]
    }
    @results = Search::FullSerializer.new(@search, _options).serialize

    render json: @results
  end

  private

  def search_params
    params.permit(:search_term, :type, :requested_page, :items_per_page, :filters)
  end
end