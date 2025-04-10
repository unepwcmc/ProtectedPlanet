Sidekiq.configure_server do |config|
  config.logger = Rails.logger
  config.logger.level = Rails.logger.level
  config.logger.formatter = Rails.logger.formatter
  config.redis = {url: ENV["REDIS_URL"]}
end

