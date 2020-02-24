class SearchController < ApplicationController
  after_action :enable_caching

  # before_action :ignore_empty_query, only: [:index, :map] ## FERDI - I commented this out so the page would load
  before_action :load_search, only: [:index, :map]

  def index
    #render partial: 'grid' if request.xhr? ## FERDI - I think we can delete this?
  end

  def search_results
    search = Search.search(params['params']['search_term'])
    results = search.results
    @results = {
      search_term: 'My search',
      categories: [
        { id: 0, title: 'All' }, # Pull id from CMS
        { id: 0, title: 'News & Stories' }, # Pull id and title from CMS
        { id: 0, title: 'Resources' } # Pull id and title from CMS
      ],
      current_page: 1,
      page_items_start: results.page_items_start(page: 1, for_display: true),
      page_items_end: results.page_items_end(page: 1, for_display: true),
      total_items: results.count , # Total items for selected category
      results: results.paginate(page: 1).map do |record|
        {
          title: record.title || 'title',
          url: 'url',
          summary: record.content || 'content',
          image: 'image url'
        }
      end
    }.to_json

    render json: @results
  end

  def map
    render :index
  end

  def autocomplete
    @results = Autocompletion.lookup params[:q] ## TODO Ferdi this needs to return // [ { title: String, url: String } ]

    # render partial: 'search/autocomplete'
    render json: @results
  end

  def search_results_areas
    #for searching for OECMs or WDPAs - hooked it up with the front end - if it is working the page should requeste these results on first load

    @results = [
      {
        geoType: 'region',
        title: I18n.t('global.geo-types.regions'),
        total: 10,
        areas: [
          {
            title: 'Asia & Pacific',
            url: 'url to page'
          }
        ]
      },
      {
        geoType: 'country',
        title: I18n.t('global.geo-types.countries'),
        total: 10,
        areas: [
          {
            areas: 5908,
            imageFlag: ActionController::Base.helpers.image_url('flags/united-states-of-america.svg'),
            region: 'America',
            title: 'United States of America',
            url: 'url to page'
          },
          {
            areas: 508,
            imageFlag: ActionController::Base.helpers.image_url('flags/united-kingdom.svg'),
            region: 'Europe',
            title: 'United Kingdom',
            url: 'url to page'
          },
          {
            areas: 508,
            imageFlag: ActionController::Base.helpers.image_url('flags/germany.svg'),
            region: 'Europe',
            title: 'Germany',
            url: 'url to page'
          },
          {
            areas: 508,
            imageFlag: ActionController::Base.helpers.image_url('flags/germany.svg'),
            region: 'Europe',
            title: 'Germany',
            url: 'url to page'
          }
        ]
      },
      {
        geoType: 'site',
        title: I18n.t('global.area-types.wdpa'), ## OR I18n.t('global.area_types.oecm')
        total: 30,
        areas: [
          {
            country: 'Germany',
            image: '/assets/tiles/FR?type=country&version=1', ##TODO Ferdi fill in with correct image url
            imageFlag: ActionController::Base.helpers.image_url('flags/germany.svg'),
            region: 'Europe',
            title: 'Avenc De Fra Rafel',
            url: 'url to page'
          }
        ]
      }
    ].to_json

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
    @query = params[:q]
    redirect_to :root if @query.blank? && filters.empty?
  end

  def load_search
    begin
      @search = Search.search(@query, search_options)
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

  def filters
    params.stringify_keys.slice(*Search::ALLOWED_FILTERS)
  end
end
