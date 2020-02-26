class SearchController < ApplicationController
  after_action :enable_caching

  before_action :ignore_empty_query, only: [:search_results]
  before_action :load_search, only: [:search_results]

  def index
    @categories = [
      { id: 0, title: 'All' }, # Pull id from CMS
      { id: 1, title: 'News & Stories' }, # Pull id and title from CMS
      { id: 2, title: 'Resources' } # Pull id and title from CMS
    ].to_json

    @query = params['search_term']
  end

  def search_results
    @results = Search::FullSerializer.new(@search, {page: params['requested_page']}).serialize

    render json: @results
  end

  def map
    render :index
  end

  def autocomplete
    @results = Autocompletion.lookup params['params']['search_term'] ## TODO Ferdi this needs to return // [ { title: String, url: String } ]

    # render partial: 'search/autocomplete'
    render json: @results
  end

  def search_results_areas 
    #for searching for OECMs or WDPAs - hooked it up with the front end - if it is working the page should request these results on first load
    @results = Search::AreasSerializer.new(@search).serialize

    render json: @results
  end

  def search_areas_pagination
    #for specific page of OECMs or WDPAs

    #if regions
    @results = [
      {
        title: 'Asia & Pacific',
        url: 'url to page'
      }
    ].to_json

    #if countries
    @results = [
      {
        areas: 5908,
        region: 'America',
        title: 'United States of America',
        url: 'url to page'
      }
    ]

    #if sites
    @results = [
      {
        country: 'France',
        image: 'url to generated map of PA location',
        region: 'Europe',
        title: 'Avenc De Fra Rafel',
        url: 'url to page'
      }
    ]

    render json: @results
  end

  private

  def ignore_empty_query
    @query = params['search_term'] rescue nil
    redirect_to :root if @query.blank? && filters.empty?
  end

  def load_search
    begin
      @search = Search.search(@query, search_options, search_index)
    rescue => e
      Rails.logger.warn("error in search controller: #{e.message}")
      @search = nil
    end

    @main_filter = params[:main]
  end

  def search_options
    options = {filters: filters}
    options[:page] = params[:page].to_i if params[:page].present?
    options
  end

  def search_index
    # TODO Define mapping for index between FE and BE
    Search::DEFAULT_INDEX_NAME
  end

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
