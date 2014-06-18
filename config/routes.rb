Rails.application.routes.draw do
  get '/:id', to: 'protected_areas#show'
end
