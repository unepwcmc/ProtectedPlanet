Rails.application.routes.draw do
  namespace :admin do
    resources :home_carousel_slides
    resources :call_to_actions
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/admin/sidekiq'

  devise_for :users

  get '/en', to: 'home#index'
  get '/', to: redirect('/en')
  get '/admin', to: redirect('/admin/sites')

  #TODO
  get '/:id', to: 'protected_areas#show', as: 'protected_area'

  get '/assets/tiles/:id', to: 'assets#tiles', as: 'tiles'

  scope "(:locale)", locale: /en|es|fr/ do

    root to: 'home#index'
    get '/', to: 'home#index'

    put '/admin/maintenance', as: 'maintenance'
    put '/admin/clear_cache', as: 'clear_cache'

    ## Non-CMS routes
    get '/region/:iso', to: 'region#show', as: 'region'

    get '/country/:iso', to: 'country#show', as: 'country'
    get '/country/:iso/pdf', to: 'country#pdf', as: 'country_pdf'
    get '/country/:iso/compare(/:iso_to_compare)', to: 'country#compare', as: 'compare_countries'
    get '/country/:iso/protected_areas', to: 'country#protected_areas', as: 'country_protected_areas'

    get '/global_statistics_download', to: 'global_statistics#download'

    # JSON endpoints
    get '/downloads/poll', to: 'downloads#poll', as: 'download_poll'
    resources :downloads, only: [:show, :create, :update]

    namespace :api do
      namespace :v3 do
        resources :protected_areas, only: [:show] do
          member do
            get 'geojson'
            get 'overlap/:comparison_wdpa_id', to: 'protected_areas#overlap'
          end
        end

        get '/networks/:id/bounds', to: 'networks#bounds'
        get '/search/by_point', to: 'search#by_point'
      end
    end
    
    ## Only CMS routes are present below

    get '/marine/download_designations', to: 'marine#download_designations'

    get '/target-11-dashboard/load-countries', to: 'target_dashboard#load_countries',
      as: 'target_dashboard_load_countries'

    get '/terms', to: redirect("/c/terms-and-conditions")

    get '/country_codes', to: 'country#codes', as: 'country_codes'

    get '/thematic-areas/green-list', to: 'green_list#index'
    get '/thematic-areas/oecms', to: 'oecm#index'
    get '/thematic-areas/protected-areas-management-effectiveness-pame', to: 'pame#index'
    get '/thematic-areas/marine-protected-areas', to: 'marine#index'
    get '/thematic-areas/global-partnership-on-aichi-target-11', to: 'target_dashboard#index'
    get '/thematic-areas/wdpa', to: 'wdpa#index'

    # JSON endpoints - CMS
    post '/pame/download', to: 'pame#download'
    post '/pame/list', to: 'pame#list'

    # Used for site-wide search
    post '/search/autocomplete', to: 'search#autocomplete'
    get '/search-results', to: 'search#search_results', as: :search_results

    # Used to fetch news articles/resources
    get '/search-cms', to: 'search_cms#index', as: :search_cms

    # Used for PA/region/country search
    get '/search-areas', to: 'search_areas#index', as: :search_areas
    get '/search-areas-results', to: 'search_areas#search_results', as: :search_areas_results
    get '/search', to: 'search#index'

    # Ensure that this route is defined last

    comfy_route :cms_admin, path: "/admin"
    comfy_route :cms, path: "/", sitemap: false
  end

end
