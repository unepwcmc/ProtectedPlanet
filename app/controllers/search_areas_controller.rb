class SearchAreasController < ApplicationController
  include Concerns::Searchable
  include Concerns::Filterable

  before_action :check_area_type, only: [:index]
  before_action :ignore_empty_query, only: [:search_results]
  before_action :load_search, only: [:search_results]
  before_action :load_filters, only: [:index]

  def index
    @query = search_params[:search_term]
  end

  def search_results
    @query = search_params[:search_term]
    @area_type = search_params[:area_type]
    @results = Search::AreasSerializer.new(@search).serialize

    render json: @results
  end

  private

  def search_params
    params.permit(:search_term, :filters, :area_type)
  end
end
