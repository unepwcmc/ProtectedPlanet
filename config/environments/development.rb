# class DisableAssetsLogger
  # def initialize(app)
    # @app = app
    # Rails.application.assets.logger = Logger.new('/dev/null')
  # end
#
  # def call(env)
    # previous_level = Rails.logger.level
    # Rails.logger.level = Logger::ERROR if env['PATH_INFO'].index("/assets/") == 0
    # @app.call(env)
  # ensure
    # Rails.logger.level = previous_level
  # end
# end

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  # config.webpacker.check_yarn_integrity = true

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.seconds.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end


  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false

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

  # Shuts up logger for assets serving! Yay!
  # config.middleware.insert_before Rails::Rack::Logger, DisableAssetsLogger

  config.action_mailer.delivery_method = :smtp

  secrets = Rails.application.secrets.mailer
  config.action_mailer.asset_host = secrets[:asset_host]
  config.action_mailer.default_url_options = { :host => secrets[:host] }
  config.action_mailer.smtp_settings = {
    :enable_starttls_auto => true,
    :address => secrets[:address],
    :port => 587,
    :domain => secrets[:domain],
    :authentication => :login,
    :user_name => secrets[:username],
    :password => secrets[:password]
  }

  config.active_storage.service = :local
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end

