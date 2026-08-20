class ApplicationController < ActionController::Base
  CACHE_FETCH_TTL = 30.days

  # Clumsy rescue from fragments custom not null database errors
  rescue_from ActiveRecord::StatementInvalid, :with => :record_invalid_error
  class PageNotFound < StandardError; end;

  protect_from_forgery with: :exception
  # Required for development
  before_action :set_host_for_local_storage

  helper_method :opengraph, :canonical_url, :structured_data

  before_action :load_cms_site
  before_action :load_cms_content

  before_action :set_locale
  before_action :check_for_pdf

  def admin_path?
    request.original_fullpath =~ %r{/(?:#{I18n.locale}/)?admin/?}
  end

  def opengraph
    return if admin_path?

    @opengraph ||= OpengraphBuilder.new('og': og_tags, 'twitter': twitter_tags)
  end

  def og_tags
    {
      'site_name': t('meta.site.name'),
      'title': t('meta.site.title'),
      'description': t('meta.site.description'),
      'url': request.url,
      'type': 'website',
      'image': URI.join(root_url, helpers.image_path(t('meta.image'))),
      'image:alt': t('meta.image_alt'),
      'image:height': t('meta.image_height'),
      'image:width': t('meta.image_width'),
      'locale': 'en_GB'
    }
  end

  def twitter_tags
    {
      'card': t('meta.twitter.card'),
      'site': t('meta.twitter.site'),
      'creator': t('meta.twitter.creator')
    }
  end

  def canonical_url
    return if admin_path?

    request.original_url.split('?').first
  end

  def structured_data
    return if admin_path?

    @structured_data ||= {
      '@context': 'https://schema.org',
      '@type': 'WebSite',
      name: t('meta.site.name'),
      url: root_url,
      description: t('meta.site.description'),
      publisher: {
        '@type': 'Organization',
        name: t('meta.site.name'),
        logo: URI.join(root_url, helpers.image_path(t('meta.image'))).to_s
      }
    }
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

  # Production only: a blanket StandardError handler swallows every exception, so in
  # development it hides the Rails error page/backtrace and in test it turns genuine
  # failures into a rendered 500 instead of failing loudly.
  if Rails.env.production?
    rescue_from StandardError do
      render_error_page(500)
    end
  end

  # Declared AFTER StandardError deliberately: rescue_from matches the most recently
  # registered handler first, and PageNotFound < StandardError — reverse the order and
  # every 404 would render as a 500 in production.
  # Unguarded, so a missing record renders the styled 404 page in every environment.
  rescue_from PageNotFound do
    render_error_page(404)
  end

  def enable_caching
    expires_in AppSecrets.cache_max_age, public: true
  end

  # as of 04Apr it doesn't seem to be used
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

    # Strips out the locale and any query params (including the query character) 
    # when attempting to find the page in the DB by its full_path
    sanitised_request = request.original_fullpath.gsub(%r{\A/#{I18n.locale}/?}, '/')[/[^?]+/]

    @cms_page ||= Comfy::Cms::Page.find_by_full_path(sanitised_request)

    return unless @cms_page

    ComfyOpengraph.new({ 'social-title': 'title', 'social-description': 'description', 'image': 'image' },
                        page: @cms_page).parse(opengraph: opengraph, type: 'og')
  end

  def record_invalid_error(exception = nil)
    message = "We're sorry, but something went wrong"

    # This handler is registered for ALL ActiveRecord::StatementInvalid, but its
    # not-null-fragment logic only applies to the Comfy page-edit form. Guard the
    # page params (nil on any other request) and log the underlying error so a DB
    # error elsewhere isn't silently swallowed by a crash in this handler.
    fragments_params = params.dig(:page, :fragments_attributes)
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
      return redirect_to(request.referrer || root_path, alert: message)
    end

    # Anything that is NOT the Comfy fragment case is a genuine database error and
    # must surface. This used to log and redirect, which meant a broken query was
    # indistinguishable from a normal 302.
    #
    # That is not hypothetical: after the move to the PostgreSQL 17 staging host,
    # Country#coverage_growth raised
    #   PG::UndefinedColumn: ERROR: column "date_part" does not exist
    # on EVERY country page. All of them silently redirected to the homepage, no
    # error reached AppSignal, and nothing looked wrong from the outside -- it was
    # found only because a route smoke test compared against production.
    #
    # NB: raising from inside a rescue_from handler propagates straight to the error
    # middleware -- it is NOT re-dispatched to the StandardError handler above -- so
    # a bare re-raise in production would lose the styled error page. Hence: report
    # explicitly, then raise in development/test where a loud backtrace is what you
    # want, and render the normal 500 page in production.
    Rails.logger.error("record_invalid_error: #{exception.class}: #{exception.message}") if exception
    Appsignal.send_error(exception) if exception && defined?(Appsignal)

    raise exception if exception && !Rails.env.production?
    return render_error_page(500) if exception

    redirect_to(request.referrer || root_path, alert: message)
  end

  def is_comfy_page_edit?
    params[:controller] == 'comfy/admin/cms/pages' && params[:action] == 'update'
  end

  def render_error_page(status)
    case status
    when 404
      render template: "layouts/error_page", layout: "application", status: :not_found, locals: { error_status: status }
    else
      render template: "layouts/error_page", layout: "application", status: :internal_server_error, locals: { error_status: status }
    end
  end

  def check_for_pdf
    @for_pdf = params[:for_pdf].present?
  end

  def set_host_for_local_storage
    Rails.application.routes.default_url_options[:host] = request.base_url
    # TODO Check why this is not set automatically
    # ActiveStorage::Current.host = request.base_url if Rails.application.config.active_storage.service == :local
  end
end
