class SearchAreasController < ApplicationController
  include Concerns::Searchable
  include Concerns::Filterable

  after_action :enable_caching

  before_action :check_area_type, only: [:index, :search_results]
  before_action :ignore_empty_query, only: [:search_results]
  before_action :load_search, only: [:search_results]
  before_action :load_filters, only: [:index, :search_results]

  def index
    @query = search_params[:search_term]
  end

  def search_results
    @query = search_params[:search_term]
    @area_type = search_params[:area_type]
    geo_type = search_params[:geo_type]
    @results = Search::AreasSerializer.new(@search, geo_type).serialize

    render json: @results
  end

  private

  def search_params
    params.permit(:search_term, :filters, :area_type, :geo_type, :items_per_page, :requested_page)
  end
end