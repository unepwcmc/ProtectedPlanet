Rails.application.routes.draw do
  namespace :admin do
    resources :home_carousel_slides
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/admin/sidekiq'

  devise_for :users

  root to: 'home#index'
  get '/', to: 'home#index'

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

  resources :projects, only: [:create, :index, :update, :destroy]

  get '/resources', to: 'cms/resources#index'

  get '/marine', to: 'marine#index'
  get '/marine/download_designations', to: 'marine#download_designations'
  get '/green_list/:id', to: 'green_list#show', as: 'green_list'
  get '/target-11-dashboard', to: 'target_dashboard#index', as: 'target_dashboard'
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

  comfy_route :cms_admin, path: "/admin"
  comfy_route :cms, path: "/:locale/"
end
