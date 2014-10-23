Rails.application.routes.draw do
  root to: 'home#index'
  get '/', to: 'home#index'

  put '/admin/maintenance', as: 'maintenance'
  put '/admin/clear_cache', as: 'clear_cache'

  namespace :admin do
    resources :import, only: [] do
      get :confirm
      get :cancel
    end
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/admin/sidekiq'

  get '/terms', to: 'static_pages#terms', as: 'wcmc_terms'
  get '/wdpa-terms', to: 'static_pages#wdpa_terms', as: 'wdpa_terms'

  get '/stats/global', to: 'stats/global#index', as: 'global_stats'
  get '/stats/regional/:iso', to: 'stats/regional#show', as: 'regional_stats'
  get '/stats/country/:iso', to: 'stats/country#show', as: 'country_stats'

  get '/downloads/poll', to: 'downloads#poll', as: 'download_poll'
  resources :downloads, only: [:show, :create]

  get '/search', to: 'search#index'

  get '/sites/:id', to: 'sites#show'
  get '/sites/:id/*other', to: 'sites#show'

  get '/api/protected_areas', to: 'api/protected_areas#index', as: 'api'

  get '/:id', to: 'protected_areas#show', as: 'protected_area'

end
