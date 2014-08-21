class ImportTools::RedisHandler
  attr_reader :redis

  def initialize
    Sidekiq.redis{|conn| self.redis = conn }
  end

  def lock id
    redis.setnx(current_key, id)
  end

  def unlock
    redis.del(current_key)
  end

  def current_id
    redis.get current_key
  end

  def previous_ids
    @previous_ids ||= redis.zrangebyscore(
      previous_ids_key,
      '-inf', '+inf',
      {withscores: true, limit: [0, 1]}
    ).map(&:last)
  end

  def add_to_previous_ids id
    redis.zadd(previous_ids_key, id, id.to_s)
  end

  def increase_property id, property
    redis.incr property_key(id, property)
  end

  def increase_property_and_compare id, property, compared_property
    values = redis.multi do
      redis.incr property_key(id, property)
      redis.get property_key(id, compared_property)
    end.map(&:to_i)

    values.first == values.last
  end

  private
  attr_writer :redis

  def property_key id, property
    "#{key(id)}:#{property}"
  end

  def key id
    "#{redis_prefix}:#{id}"
  end

  def current_key
    "#{redis_prefix}:current"
  end

  def previous_ids_key
    "#{redis_prefix}:previous"
  end

  def redis_prefix
    Rails.application.secrets.redis['wdpa_imports_prefix']
  end
end
