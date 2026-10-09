Rails.application.configure do
  # Overrides config/application.rb.

  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true

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

    config.public_file_server.headers = { 'cache-control' => 'public, max-age=0, must-revalidate' }
    config.middleware.insert_before ActionDispatch::Static, Middleware::CacheHeaders
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load

  # Sprockets, which now serves only the Comfy admin stylesheet.
  config.assets.debug = true
  config.assets.quiet = true
  config.assets.raise_runtime_errors = true

  # config.action_view.raise_on_missing_translations = true

  config.active_storage.service = :local
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Host Authorization's built-in allowance covers loopback and private IPs, not DNS
  # names -- so the PDF generator's requests (from the sidekiq container, addressed by
  # Docker service name) get 403'd without this.
  config.hosts << "protectedplanet-web"

  config.log_formatter  = ::Logger::Formatter.new
  logger                = ActiveSupport::Logger.new(STDOUT)
  logger.formatter      = config.log_formatter
  config.logger         = ActiveSupport::TaggedLogging.new(logger)
end
