Sidekiq.configure_server do |config|
  config.redis = {url: $redis.client.options[:url]}
end

