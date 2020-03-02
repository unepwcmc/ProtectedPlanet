class SearchController < ApplicationController
  include Concerns::Searchable
  after_action :enable_caching

  before_action :ignore_empty_query, only: [:search_results, :search_results_areas]
  before_action :load_search, only: [:search_results, :search_results_areas]

  def index
    categories = Comfy::Cms::Page.where(parent_id: Comfy::Cms::Page.root.id)
    @categories = categories.map do |c|
      { id: c.id, title: c.label }
    end.to_json

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
end
