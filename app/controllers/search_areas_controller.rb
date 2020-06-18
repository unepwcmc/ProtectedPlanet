class SearchAreasController < ApplicationController
  include Concerns::Searchable

  after_action :enable_caching

  before_action :check_db_type, only: [:index, :search_results]
  before_action :load_search, only: [:index, :search_results]
  before_action :load_filters, only: [:index, :search_results]

  TABS = %w(region country site).freeze
  def index
    placeholder = @db_type == 'all' ? 'oecm-wdpa' : @db_type
    @config_search_areas = {
      id: @db_type,
      placeholder: I18n.t("global.placeholder.search-#{placeholder}")
    }.to_json

    @tabs = []

    TABS.each do |tab|
      @tabs << { id: tab, title: I18n.t("search.geo-types.#{tab}") }
    end
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
