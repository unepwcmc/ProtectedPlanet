class SearchAreasController < ApplicationController
  include Concerns::Searchable
  include MapHelper

  after_action :enable_caching

  before_action :check_db_type, only: [:index, :search_results]
  before_action :load_search, only: [:search_results]
  before_action :load_search_from_query_string, only: [:index]
  before_action :load_filters, only: [:index, :search_results]

  TABS = %w(region country site).freeze
  def index
    placeholder = @db_type ? @db_type : 'oecm-wdpa'
    
    @config_search_areas = {
      id: @db_type || 'all',
      placeholder: I18n.t("global.placeholder.search-#{placeholder}")
    }.to_json

    @download_options = helpers.download_options(['csv', 'shp', 'gdb'], 'search', 'all')

    @tabs = []

    TABS.each do |tab|
      @tabs << { id: tab, title: I18n.t("search.geo-types.#{tab}") }
    end

    geo_type = search_params[:geo_type] || 'site'
    @filters = @db_type ? { db_type: @db_type } : {}
    @results = Search::AreasSerializer.new(@search, geo_type).serialize

    @map = {
      areFiltersHidden: true,
      overlays: MapOverlaysSerializer.new(search_overlays, map_yml).serialize,
      type: 'all'
    }
  end

  def search_results
    geo_type = search_params[:geo_type]
    @results = Search::AreasSerializer.new(@search, geo_type).serialize

    render json: { areas: @results, filters: @filter_groups }.to_json
  end

  private

  def search_overlays
    overlays(['marine_wdpa', 'terrestrial_wdpa'])
  end

  def search_params
    params.permit(
      :search_term, :geo_type, :items_per_page, :requested_page, :search_index, :filters,
      filters: [
        db_type: [], is_type: [], special_status: [],
        designation: [], governance: [], location: [:type, options: []],
        is_whs:[]
      ]
    )
  end
end
