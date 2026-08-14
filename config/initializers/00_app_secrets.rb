# Rails.application.secrets is deprecated under load_defaults 7.1 and REMOVED in Rails
# 7.2. We keep the same YAML (renamed config/secrets.yml -> config/app_secrets.yml so
# Rails no longer magic-loads it) and read it explicitly via config_for.
#
# AppSecrets is a drop-in for the old Rails.application.secrets: config_for returns an
# ActiveSupport::OrderedOptions (dot access) with nested hashes intact, so existing call
# sites change only the receiver -- `Rails.application.secrets.redis[:url]` becomes
# `AppSecrets.redis[:url]`. Missing keys return nil, matching the old behaviour.
#
# The `00_` filename prefix makes this load before every other initializer (redis.rb,
# sidekiq.rb, ...) that references AppSecrets.
AppSecrets = Rails.application.config_for(:app_secrets)
