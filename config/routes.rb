Rails.application.routes.draw do
  namespace :admin do
    resources :home_carousel_slides
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/admin/sidekiq'

  devise_for :users

  scope "(:locale)", locale: /en|es|fr/ do

    get '/en', to: 'home#index'
    get '/', to: redirect('/en')
    root to: 'home#index'

    # root to: 'home#index'
    # get '/', to: 'home#index'

    put '/admin/maintenance', as: 'maintenance'
    put '/admin/clear_cache', as: 'clear_cache'

    get '/assets/tiles/:id', to: 'assets#tiles', as: 'tiles'

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

    # resources :projects, only: [:create, :index, :update, :destroy]

    get '/marine/download_designations', to: 'marine#download_designations'
    # get '/green_list/:id', to: 'green_list#show', as: 'green_list'
    
    get '/target-11-dashboard/load-countries', to: 'target_dashboard#load_countries',
      as: 'target_dashboard_load_countries'

    get '/region/:iso', to: 'region#show', as: 'region'

    get '/country/:iso', to: 'country#show', as: 'country'
    get '/country/:iso/pdf', to: 'country#pdf', as: 'country_pdf'
    get '/country/:iso/compare(/:iso_to_compare)', to: 'country#compare', as: 'compare_countries'
    get '/country/:iso/protected_areas', to: 'country#protected_areas', as: 'country_protected_areas'

    get '/:id', to: 'protected_areas#show', as: 'protected_area'
    get '/sites/:id', to: 'sites#show'
    get '/sites/:id/*other', to: 'sites#show'

    get '/terms', to: redirect("/c/terms-and-conditions")

    get '/downloads/poll', to: 'downloads#poll', as: 'download_poll'
    resources :downloads, only: [:show, :create, :update]

    get '/search', to: 'search#index'
    get '/search/map', to: 'search#map'
    get '/search/autocomplete', to: 'search#autocomplete'
    post '/search', to: 'search#create'

    get '/country_codes', to: 'country#codes', as: 'country_codes'

    get '/c/resources', to: 'resources#index'

    get '/c/thematical-areas/green-list', to: 'green_list#index'
    get '/c/thematical-areas/other-effective-area-based-conservation-measures', to: 'oecm#index'
    get '/c/thematical-areas/protected-areas-management-effectiveness-pame', to: 'pame#index'
    get '/c/thematical-areas/marine-protected-areas', to: 'marine#index'
    get '/c/thematical-areas/global-partnership-on-aichi-target-11', to: 'target_dashboard#index'
    get '/c/thematical-areas/world-database-on-protected-areas', to: 'wdpa#index'

    # Ensure that this route is defined last
    
    comfy_route :cms_admin, path: "/admin"
    comfy_route :cms, path: "/c"
  end

end
