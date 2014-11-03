Rails.application.routes.draw do
  devise_for :users

  root to: 'home#index'
  get '/', to: 'home#index'

  put '/admin/maintenance', as: 'maintenance'
  put '/admin/clear_cache', as: 'clear_cache'

  namespace :api do
    get '/search/points', to: 'search#points'
  end

  namespace :admin do
    resources :import, only: [] do
      get :confirm
      get :cancel
    end
  end

  resources :projects, only: [:create, :index, :update]

  require 'sidekiq/web'
  mount Sidekiq::Web => '/admin/sidekiq'

  get '/terms', to: 'static_pages#terms', as: 'wcmc_terms'
  get '/wdpa-terms', to: 'static_pages#wdpa_terms', as: 'wdpa_terms'
  get '/about', to: 'static_pages#about', as: 'about'

  get '/stats/global', to: 'stats/global#index', as: 'global_stats'
  get '/stats/regional/:iso', to: 'stats/regional#show', as: 'regional_stats'
  get '/stats/country/:iso', to: 'stats/country#show', as: 'country_stats'

  get '/downloads/poll', to: 'downloads#poll', as: 'download_poll'
  resources :downloads, only: [:show, :create]

  get '/search', to: 'search#index'
  post '/search', to: 'search#create'

  get '/sites/:id', to: 'sites#show'
  get '/sites/:id/*other', to: 'sites#show'

  get '/:id', to: 'protected_areas#show', as: 'protected_area'
end
