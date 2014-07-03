class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def enable_caching
    expires_in Rails.application.secrets.cache_max_age, public: true
  end
end
