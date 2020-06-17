class SearchAreasController < ApplicationController
  include Concerns::Searchable

  after_action :enable_caching

  before_action :check_db_type, only: [:index, :search_results]
  before_action :load_search, only: [:search_results]
  before_action :load_filters, only: [:index, :search_results]

  def index
    placeholder = @db_type == 'all' ? 'oecm-wdpa' : @db_type
    @config_search_areas = {
      id: @db_type,
      placeholder: I18n.t("global.placeholder.search-#{placeholder}")
    }.to_json

    @tabs = []

    I18n.t('search.geo-types').each_with_index.map do |type, i|
      @tabs << { id: "geo-type-#{i}", title: type } #FERDI update the ids here to what you need
    end

    @tabs.to_json
  end

  def search_results
    @query = search_params[:search_term]
    @db_type = search_params[:db_type]
    geo_type = search_params[:geo_type]
    @results = Search::AreasSerializer.new(@search, geo_type).serialize

    render json: { areas: @results, filters: @filter_groups }.to_json
  end

  private

  def search_params
    params.permit(:search_term, :filters, :db_type, :geo_type, :items_per_page, :requested_page)
  end
end
