class ApplicationController < ActionController::Base
  class PageNotFound < StandardError; end;

  protect_from_forgery with: :exception

  after_filter :store_location
  before_filter :load_cms_pages
  before_filter :check_for_pdf

  def raise_404
    raise PageNotFound
  end

  rescue_from PageNotFound do
    render_404
  end

  def enable_caching
    expires_in Rails.application.secrets.cache_max_age, public: true
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  private

  def render_404
    render file: Rails.root.join("/public/404.html"), layout: false, status: :not_found
  end

  NO_REDIRECT = [
    "/users/sign_in",
    "/users/sign_up",
    "/users/password/new",
    "/users/password/edit",
    "/users/confirmation",
    "/users/sign_out"
  ]

  def load_cms_pages
    @updates_and_news  = Comfy::Cms::Category.find_by_label("Updates & News")
    @connectivity_page = Comfy::Cms::Page.find_by_label("Connectivity Conservation")
    @pame_page         = Comfy::Cms::Page.find_by_label("Protected Areas Management Effectiveness (PAME)")
    @wdpa_page         = Comfy::Cms::Page.find_by_label("World Database on Protected Areas")
    @green_list_page   = Comfy::Cms::Page.find_by_slug("green-list")
  end

  def check_for_pdf
    @for_pdf = params[:for_pdf].present?
  end

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    return unless request.get?

    if (!NO_REDIRECT.include?(request.path) && !request.xhr?)
      session[:previous_url] = request.fullpath
    end
  end
end
