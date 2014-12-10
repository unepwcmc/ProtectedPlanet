Rails.application.routes.draw do
  devise_for :users

  root to: 'home#index'
  get '/', to: 'home#index'

  put '/admin/maintenance', as: 'maintenance'
  put '/admin/clear_cache', as: 'clear_cache'

  get '/assets/tiles/:id', to: 'assets#tiles', as: 'tiles'

  namespace :api do
    namespace :v3 do
      resources :protected_areas, only: [:show]

      get '/search/points', to: 'search#points'
      get '/search/by_point', to: 'search#by_point'
    end
  end

  namespace :admin do
    resources :import, only: [] do
      get :confirm
      get :cancel
    end
  end

  resources :projects, only: [:create, :index, :update, :destroy]

  require 'sidekiq/web'
  mount Sidekiq::Web => '/admin/sidekiq'

  get '/terms', to: 'static_pages#terms', as: 'wcmc_terms'
  get '/wdpa-terms', to: 'static_pages#wdpa_terms', as: 'wdpa_terms'
  get '/about', to: 'static_pages#about', as: 'about'

  get '/stats/global', to: 'stats/global#index', as: 'global_stats'
  get '/stats/regional/:iso', to: 'stats/regional#show', as: 'regional_stats'
  get '/country/:iso', to: 'stats/country#show', as: 'country_stats'

  get '/country/:iso/compare', to: 'stats/country#new_comparison', as: 'new_countries_comparison'
  post '/country/:iso/compare', to: 'stats/country#compare', as: 'compare_countries'

  get '/downloads/poll', to: 'downloads#poll', as: 'download_poll'
  resources :downloads, only: [:show, :create, :update]

  get '/search', to: 'search#index'
  get '/search/map', to: 'search#map'
  post '/search', to: 'search#create'

  get '/sites/:id', to: 'sites#show'
  get '/sites/:id/*other', to: 'sites#show'

  get '/:id', to: 'protected_areas#show', as: 'protected_area'
end
