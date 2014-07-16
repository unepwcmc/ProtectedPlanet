class ImportTools::RedisHandler
  attr_reader :redis

  def initialize
    Sidekiq.redis{|conn| self.redis = conn }
  end

  def lock value
    redis.setnx(locking_key, value)
  end

  private
  attr_writer :redis

  def locking_key
    "#{redis_prefix}:locking_key"
  end

  def redis_prefix
    Rails.application.secrets.redis['wdpa_imports_prefix']
  end
end
