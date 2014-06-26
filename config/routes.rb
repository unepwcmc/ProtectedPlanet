Rails.application.routes.draw do
  root to: 'home#index'
  get '/', to: 'home#index'

  get '/downloads/:iso_3', to: 'downloads#show'

  get '/search', to: 'search#index'
  get '/:id', to: 'protected_areas#show'
end
