Rails.application.routes.draw do  

  get 'stats/global', to: 'stats/global#index'
  get 'stats/regional/:iso', to: 'stats/regional#show'
  get 'stats/country/:iso', to: 'stats/country#show'
  get '/search', to: 'search#index'
  get '/:id', to: 'protected_areas#show'
end
