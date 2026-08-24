secrets = Rails.application.config_for(:app_secrets).mailer

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure static asset server for tests with Cache-Control for performance.
  config.serve_static_files  = true
  config.static_cache_control = 'public, max-age=3600'

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  config.assets.compress = false
  # Compile on demand. With this false and no precompiled manifest in test, every
  # asset lookup failed; that was invisible only because the pre-6.0 default let
  # asset_path silently fall back to a bare public/ path. load_defaults 6.0 sets
  # config.assets.unknown_asset_fallback = false, which turns those into
  # Sprockets::Rails::Helper::AssetNotFound.
  config.assets.compile = true

  config.active_support.test_order = :random

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  config.active_storage.service = :test

  # Do not regenerate db/structure.sql after migrating in test, matching staging and
  # production. Two reasons: a test run should never rewrite a developer's schema
  # file, and the dump shells out to pg_dump, which in the dev image is v11 and
  # refuses to talk to a Postgres 17 server ("aborting because of server version
  # mismatch"). Without this, `rake db:migrate` exits non-zero on PG17 even when all
  # 204 migrations applied successfully -- which would fail CI on a green run.
  config.active_record.dump_schema_after_migration = false

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end
