class SearchAreasController < ApplicationController
  include Concerns::Searchable
  include Concerns::Filterable

  before_action :check_area_type, only: [:index]
  before_action :ignore_empty_query, only: [:index]
  before_action :load_search, only: [:index]
  before_action :load_filters, only: [:index]

  def index
    @results = Search::AreasSerializer.new(@search).serialize
    @query = params['search_term']
  end

  private

  def search_params
    params.permit(:search_term, :filters)
  end
end
