class ImportTools::RedisHandler
  def lock token
    import_locked = $redis.setnx(current_key, token)
    $redis.set("#{redis_prefix}:#{token}", '') if import_locked

    import_locked
  end

  def unlock
    $redis.del(current_key)
  end

  def current_token
    $redis.get current_key
  end

  def previous_imports
    @previous_imports ||= $redis.zrangebyscore(
      previous_imports_key,
      '-inf', '+inf',
      {withscores: true, limit: [0, 1]}
    ).map(&:last)
  end

  def add_to_previous_imports token
    $redis.zadd(previous_imports_key, token, token.to_s)
  end

  def delete_property token, property
    $redis.del(property_key(token, property))
  end

  def get_property token, property
    $redis.get(property_key(token, property))
  end

  def set_property token, property, value
    $redis.set(property_key(token, property), value)
  end

  def increase_property token, property
    $redis.incr property_key(token, property)
  end

  def increase_property_and_compare token, property, compared_property
    values = $redis.multi do
      $redis.incr property_key(token, property)
      $redis.get property_key(token, compared_property)
    end.map(&:to_i)

    values.first == values.last
  end

  private

  def property_key token, property
    "#{key(token)}:#{property}"
  end

  def key token
    "#{redis_prefix}:#{token}"
  end

  def current_key
    "#{redis_prefix}:current"
  end

  def previous_imports_key
    "#{redis_prefix}:previous"
  end

  def redis_prefix
    Rails.application.secrets.redis[:wdpa_imports_prefix]
  end
end
