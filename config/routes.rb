Rails.application.routes.draw do
  root to: 'home#index'

  get '/', to: 'home#index'
  get '/search', to: 'search#index'
  get '/:id', to: 'protected_areas#show'
end
