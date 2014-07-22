class ImportTools::RedisHandler
  attr_reader :redis

  def initialize
    Sidekiq.redis{|conn| self.redis = conn }
  end

  def lock id
    redis.setnx(current_import_key, id)
  end

  def current_import_id
    redis.get current_import_key
  end

  def past_import_ids
    @past_import_ids ||= redis.zrangebyscore(
      past_imports_key,
      '-inf', '+inf',
      {withscores: true, limit: [0, 1]}
    ).map(&:last)
  end

  def increase_total_jobs_count id
    redis.incr(total_jobs_count_key(id))
  end

  def increase_completed_jobs_count id
    redis.incr(completed_jobs_count_key(id))
  end

  private
  attr_writer :redis

  def total_jobs_count_key id
    "#{import_key(id)}:total_jobs"
  end

  def completed_jobs_count_key id
    "#{import_key(id)}:completed_jobs"
  end

  def import_key id
    "#{redis_prefix}:#{id}"
  end

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
