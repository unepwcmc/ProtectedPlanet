Rails.application.routes.draw do
  root to: 'home#index'
  get '/', to: 'home#index'

  get 'terms', to: 'static_pages#terms', as: 'wcmc_terms'
  get 'wdpa-terms', to: 'static_pages#wdpa_terms', as: 'wdpa_terms'

  get '/stats/global', to: 'stats/global#index', as: 'global_stats'
  get '/stats/regional/:iso', to: 'stats/regional#show', as: 'regional_stats'
  get '/stats/country/:iso', to: 'stats/country#show', as: 'country_stats'

  get '/downloads/:iso_3', to: 'downloads#show'

  get '/search', to: 'search#index'

  get '/sites/:id', to: 'sites#show'
  get '/sites/:id/*other', to: 'sites#show'

  get '/:id', to: 'protected_areas#show', as: 'protected_area'
end
