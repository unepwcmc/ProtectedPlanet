class ImportTools::RedisHandler
  attr_reader :redis

  def initialize
    Sidekiq.redis{|conn| self.redis = conn }
  end

  def lock import_id
    redis.setnx(current_import_key, import_id)
  end

  def current_import_id
    @current_import_id ||= redis.get current_import_key
  end

  def past_import_ids
    @past_import_ids ||= redis.zrangebyscore(
      past_imports_key,
      '-inf', '+inf',
      {withscores: true, limit: [0, 1]}
    ).map(&:last)
  end

  private
  attr_writer :redis

  def past_imports_key
    "#{redis_prefix}:past_imports"
  end

  def current_import_key
    "#{redis_prefix}:current_import"
  end

  def redis_prefix
    Rails.application.secrets.redis['wdpa_imports_prefix']
  end
end
