Rails.application.configure do
  # Overrides config/application.rb. The test database is scratch space -- it is
  # wiped and recreated between runs.

  config.cache_classes = true
  config.eager_load = false

  config.serve_static_files  = true
  config.static_cache_control = 'public, max-age=3600'

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  config.assets.compress = false
  # Compile on demand. With this false and no precompiled manifest in test, every
  # asset lookup failed -- invisible only because the pre-6.0 default let
  # asset_path silently fall back to a bare public/ path. load_defaults 6.0 sets
  # config.assets.unknown_asset_fallback = false, which turns those into
  # Sprockets::Rails::Helper::AssetNotFound.
  config.assets.compile = true

  config.active_support.test_order = :random
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr
  config.active_storage.service = :test

  # Don't regenerate db/structure.sql after migrating, matching staging and
  # production: a test run should never rewrite a developer's schema file.
  # Development still dumps normally.
  config.active_record.dump_schema_after_migration = false

  # config.action_view.raise_on_missing_translations = true
end
