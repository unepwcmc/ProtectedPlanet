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

  def increase_property id, property
    redis.incr import_property_key(id, property)
  end

  def increase_property_and_compare id, property, compared_property
    values = redis.multi do
      redis.incr import_property_key(id, property)
      redis.get import_property_key(id, compared_property)
    end.map(&:to_i)

    values.first == values.last
  end

  private
  attr_writer :redis

  def import_property_key id, property
    "#{import_key(id)}:#{property}"
  end

  def import_key id
    "#{redis_prefix}:#{id}"
  end

  def current_import_key
    "#{redis_prefix}:current_import"
  end

  def past_imports_key
    "#{redis_prefix}:past_imports"
  end

  def redis_prefix
    Rails.application.secrets.redis['wdpa_imports_prefix']
  end
end
