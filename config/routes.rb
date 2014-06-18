Rails.application.routes.draw do
  get '/search', to: 'search#index'
  get '/:id', to: 'protected_areas#show'
end
