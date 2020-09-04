Sidekiq.configure_server do |config|
  config.redis = {namespace: 'protectedplanet', url: ENV["REDIS_URL"]}
end

