Rails.application.configure do
  # Overrides config/application.rb.

  config.cache_classes = true
  config.eager_load = true
  config.enable_dependency_loading = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # dalli 3.x removed :dalli_store; :mem_cache_store is the Rails built-in (dalli-backed).
  config.cache_store = :mem_cache_store, Rails.application.config_for(:app_secrets).memcache_servers, { value_max_bytes: 10_485_760 }

  # NO Rack::Cache. It used to store rendered HTML here keyed by URL, which is what
  # made CMS edits invisible until the next deploy. The cache store above still holds
  # the expensive work behind it (statistics, search aggregations, Mapbox tiles), so
  # pages re-render every request from warm data. See docs/caching.md.

  # One flat hash covers all of public/, so this is the safe half: stable URLs
  # revalidate, which is cheap because Rack::Files answers If-Modified-Since with a
  # 304 itself. Middleware::CacheHeaders then grants a long TTL to the
  # fingerprinted build output.
  config.public_file_server.headers = { 'cache-control' => 'public, max-age=0, must-revalidate' }
  config.middleware.insert_before ActionDispatch::Static, Middleware::CacheHeaders

  # Terser rather than Uglifier: uglify-js is ES5-era and its Ruby wrapper is
  # unmaintained, failing opaquely on Node 24. Terser handles ES6+ natively.
  config.assets.js_compressor = :terser
  config.assets.compile = false
  config.assets.digest = true
  # Bump to expire every asset URL.
  config.assets.version = '1.0'

  # config.force_ssl = true
  # config.log_tags = [ :subdomain, :uuid ]
  # config.action_controller.asset_host = ""

  config.log_level = :info
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify

  # Default formatter, so PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false

  config.active_storage.service = :staging
end
