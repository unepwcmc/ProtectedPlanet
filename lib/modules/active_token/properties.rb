module ActiveToken
  class Properties < Hash
    def initialize key
      @redis_key = key
      merge! $redis.hgetall(@redis_key)
    end

    def []= key, value
      $redis.hset(@redis_key, key, value)
      super key, value

      value
    end

    def reload!
      replace($redis.hgetall(@redis_key))
    end
  end
end
