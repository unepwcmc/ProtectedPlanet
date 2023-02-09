Sidekiq.configure_server do |config|
  config.redis = {url: ENV["REDIS_URL"]}
  config.logger.level = Rails.logger.level
end

