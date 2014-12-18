class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  after_filter :store_location

  def enable_caching
    expires_in Rails.application.secrets.cache_max_age, public: true
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  private

  NO_REDIRECT = [
    "/users/sign_in",
    "/users/sign_up",
    "/users/password/new",
    "/users/password/edit",
    "/users/confirmation",
    "/users/sign_out"
  ]

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    return unless request.get?

    if (!NO_REDIRECT.include?(request.path) && !request.xhr?)
      session[:previous_url] = request.fullpath
    end
  end

  def load_user_projects
    @projects = current_user.projects if user_signed_in?
  end
end
