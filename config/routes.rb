Rails.application.routes.draw do
  namespace :admin do
    resources :home_carousel_slides
    resources :call_to_actions
    resources :banners, except: [:show]
  end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/admin/sidekiq'

  get '/en', to: 'home#index'
  get '/', to: redirect('/en')
  get '/admin', to: redirect('/admin/sites')

  # Must precede the /:id catch-all below, which would otherwise swallow
  # /sitemap.xml as a protected area lookup for site_id "sitemap".
  get '/sitemap.xml', to: 'sitemaps#index', as: 'sitemap', format: false
  get '/sitemaps/:name.xml', to: 'sitemaps#show', as: 'sitemap_chunk', format: false

  # French and Spanish were never actually translated: config/locales contains only
  # en files, so /fr and /es served identical English content at duplicate URLs.
  # Locale routing is en-only now (see config/initializers/locale.rb), and these
  # 301 the URLs search engines have already indexed onto their English
  # equivalents -- consolidating the duplicates instead of 404ing them and throwing
  # away whatever ranking those URLs had.
  #
  # Also ahead of /:id, which matches single-segment paths like /fr.
  retired_locales = /es|fr/
  get '/:locale', constraints: { locale: retired_locales }, to: redirect('/en')
  get '/:locale/*path', constraints: { locale: retired_locales }, to: redirect { |params, request|
    query = request.query_string.presence
    ["/en/#{params[:path]}", query].compact.join('?')
  }

  get '/:id', to: 'protected_areas#show', as: 'protected_area'

  get '/assets/tiles/:id', to: 'assets#tiles', as: 'tiles'

  # en only: see the retired-locale redirects above.
  scope '(:locale)', locale: /en/ do
    root to: 'home#index'
    get '/', to: 'home#index'

    put '/admin/maintenance', as: 'maintenance'
    put '/admin/clear_cache', as: 'clear_cache'

    ## Non-CMS routes
    get '/region/:iso', to: 'region#show', as: 'region'

    get '/country/:iso', to: 'country#show', as: 'country'
    # No compare route: CountryController has never had a `compare` action, so it
    # 404s. Removed once already and restored by a merge — see smoke:routes.
    get '/country/:iso/protected_areas', to: 'country#protected_areas', as: 'country_protected_areas'

    get '/global_statistics_download', to: 'global_statistics#download'

    # JSON endpoints
    get '/downloads/poll', to: 'downloads#poll', as: 'download_poll'
    resources :downloads, only: %i[show create]

    ## Only CMS routes are present below

    get '/terms', to: redirect("/c/#{PageSlugs::TERMS_AND_CONDITIONS}")

    get PageSlugs::Data.path(PageSlugs::Data::WDPCA), to: 'data_pages/wdpca#index'
    get PageSlugs::Data.path(PageSlugs::Data::GDPAME), to: 'data_pages/gdpame#index'

    get PageSlugs::ThematicAreas.path(PageSlugs::ThematicAreas::EFFECTIVENESS), to: 'thematic/effectiveness#index'
    get PageSlugs::ThematicAreas.path(PageSlugs::ThematicAreas::MARINE), to: 'thematic/marine#index'

    # JSON endpoints - CMS
    post '/pame/download', to: 'data_pages/gdpame#download'
    post '/pame/list', to: 'data_pages/gdpame#list'

    # Used for site-wide search
    post '/search/autocomplete', to: 'search#autocomplete'
    get '/search-results', to: 'search#search_results', as: :search_results

    # Used to fetch news articles/resources
    get '/search-cms', to: 'search_cms#index', as: :search_cms

    # Used for PA/region/country search
    get '/search-areas', to: 'search_areas#index', as: :search_areas
    get '/search-areas-results', to: 'search_areas#search_results', as: :search_areas_results
    get '/search', to: 'search#index'

    # Ensure that this route is defined last

    comfy_route :cms_admin, path: '/admin'
    comfy_route :cms, path: '/', sitemap: false
  end
end
