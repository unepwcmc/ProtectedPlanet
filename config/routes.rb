Rails.application.routes.draw do
  root to: 'home#index'
  get '/', to: 'home#index'

  get '/downloads/:id', to: 'downloads#show'

  get '/search', to: 'search#index'
  get '/:id', to: 'protected_areas#show'
end
