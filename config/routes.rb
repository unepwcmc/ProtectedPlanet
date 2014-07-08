Rails.application.routes.draw do
  root to: 'home#index'
  get '/', to: 'home#index'

  get '/stats/global', to: 'stats/global#index', as: 'global_stats'
  get '/stats/regional/:iso', to: 'stats/regional#show', as: 'regional_stats'
  get '/stats/country/:iso', to: 'stats/country#show', as: 'country_stats'

  get '/downloads/:iso_3', to: 'downloads#show'

  get '/search', to: 'search#index'
  get '/:id', to: 'protected_areas#show'
end
