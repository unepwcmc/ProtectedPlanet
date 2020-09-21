class ApplicationController < ActionController::Base
  # Clumsy rescue from fragments custom not null database errors
  rescue_from ActiveRecord::StatementInvalid, :with => :record_invalid_error
  class PageNotFound < StandardError; end;

  protect_from_forgery with: :exception
  # Required for development
  before_action :set_host_for_local_storage

  helper_method :opengraph

  before_action :load_cms_site
  before_action :load_cms_content

  before_action :set_locale
  before_action :check_for_pdf
  after_action :store_location

  def admin_path?
    request.original_fullpath =~ %r{/(?:#{I18n.locale}/)?admin/?}
  end

  def opengraph
    return if admin_path?

    # Methods to populate the site name dynamically are found in opengraph_helper
    @opengraph ||= OpengraphBuilder.new({
                                          'og': {
                                            'site_name': t('meta.site.name'),
                                            'title': t('meta.site.title'),
                                            'description': t('meta.site.description'),
                                            'url': request.url,
                                            'type': 'website',
                                            'image': URI.join(root_url, helpers.image_path(t('meta.image'))),
                                            'image:alt': t('meta.image_alt'),
                                            'locale': I18n.locale
                                          },
                                          'twitter': {
                                            'site': t('meta.twitter.site'),
                                            'creator': t('meta.twitter.creator')
                                          }
                                        })
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def set_locale
    if params[:locale].present?
      I18n.locale = params[:locale]
    else
      I18n.locale = I18n.default_locale
    end
  end

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

  def load_cms_site
    return if admin_path?

    @cms_site ||= Comfy::Cms::Site.first
  end

  def load_cms_content
    return if admin_path?

    @cms_page ||= Comfy::Cms::Page.find_by_full_path(request.original_fullpath.gsub(%r{\A/#{I18n.locale}/?}, '/'))

    return unless @cms_page

    ComfyOpengraph.new({ 'social-title': 'title', 'social-description': 'description', 'image': 'image' },
                        page: @cms_page).parse(opengraph: opengraph, type: 'og')
  end

  def record_invalid_error
    message = "We're sorry, but something went wrong"

    fragments_params = params[:page][:fragments_attributes]
    if fragments_params.present? && is_comfy_page_edit?
      null_fragments = []
      # Only get custom not null cms tags
      # Currently only works with dates but it's already more generalised to work with texts
      fragments_params.values.select { |v| v['tag'].include?('not_null') }.map do |fragment|
        if fragment['tag'].include?('date') && fragment['datetime'].blank? ||
            fragment['tag'].include?('text') && fragment['content'].blank?
          null_fragments << fragment['identifier']
        end
      end
      message = "The following fields cannot be empty: #{null_fragments.join(', ')}"
    end

    redirect_to request.referrer, alert: message
  end

  def is_comfy_page_edit?
    params[:controller] == 'comfy/admin/cms/pages' && params[:action] == 'update'
  end

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

  def set_host_for_local_storage
    Rails.application.routes.default_url_options[:host] = request.base_url if Rails.application.config.active_storage.service == :local
    # TODO Check why this is not set automatically
    ActiveStorage::Current.host = request.base_url if Rails.application.config.active_storage.service == :local
  end
end
