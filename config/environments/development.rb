Rails.application.configure do

  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true

  # `rails dev:cache` toggles this and restarts via tmp/restart.txt (puma.rb sets
  # `plugin :tmp_restart`); creating the file by hand needs a manual restart.
  #
  # The static-file lines mirror staging/production. They do NOT reach the JS/CSS
  # you edit: ViteRuby::DevServerProxy is middleware #0 and forwards to the Vite
  # dev server whenever it answers on its port, so those stay no-cache. To see the
  # fingerprinted policy on real assets, stop the vite service -- vite_ruby then
  # serves the built hashed files under /vite-dev/assets/, which VITE_DEV_BUILD
  # matches. The first request after that triggers a full build.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store

    # If you want to test browser cache you need to make sure vite container is turned OFF,
    # So rails will trigger its own vite build and all compiled files are then in vite-dev which are cached when caching-dev is there
    config.public_file_server.headers = { 'cache-control' => 'public, max-age=0, must-revalidate' }
    config.middleware.insert_before ActionDispatch::Static, Middleware::CacheHeaders
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true


  # Suppress logger output for asset requests
  config.assets.quiet = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.active_storage.service = :local
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Host Authorization's built-in allowance only covers loopback/private IPs, not DNS
  # names - so the PDF generator's requests (running in the sidekiq container, addressed
  # by Docker service name) get 403'd without this explicit allowance.
  config.hosts << "protectedplanet-web"

  config.log_formatter  = ::Logger::Formatter.new
  logger                = ActiveSupport::Logger.new(STDOUT)
  logger.formatter      = config.log_formatter
  config.logger         = ActiveSupport::TaggedLogging.new(logger)
end

