Rails.application.routes.draw do
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

  require 'sidekiq/web'
  mount Sidekiq::Web => '/admin/sidekiq'

  get '/terms', to: redirect("/c/terms-and-conditions")

  get '/country/:iso', to: 'country#show', as: 'country'
  get '/country/:iso/pdf', to: 'country#pdf', as: 'country_pdf'
  get '/country/:iso/compare(/:iso_to_compare)', to: 'country#compare', as: 'compare_countries'
  get '/country/:iso/protected_areas', to: 'country#protected_areas', as: 'country_protected_areas'

  get '/downloads/poll', to: 'downloads#poll', as: 'download_poll'
  resources :downloads, only: [:show, :create, :update]

  get '/search', to: 'search#index'
  get '/search/map', to: 'search#map'
  get '/search/autocomplete', to: 'search#autocomplete'
  post '/search', to: 'search#create'

  get '/sites/:id', to: 'sites#show'
  get '/sites/:id/*other', to: 'sites#show'

  get '/country_codes', to: 'country#codes', as: 'country_codes'

  get '/resources', to: 'cms/resources#index'

  get '/marine', to: 'marine#index'

  comfy_route :cms_admin, path: '/admin'
  comfy_route :cms, path: '/c', sitemap: false

  get '/:id', to: 'protected_areas#show', as: 'protected_area'
  get '/green_list/:id', to: 'green_list#show', as: 'green_list'
end
