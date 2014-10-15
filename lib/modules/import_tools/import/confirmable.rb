module ImportTools::Import::Confirmable
  def confirmation_key
    stored_confirmation_key or generate_confirmation_key
  end

  private

  def generate_confirmation_key
    SecureRandom.hex.tap do |key|
      redis_handler.set_property(
        self.token, 'confirmation_key', key
      )
    end
  end

  def stored_confirmation_key
    @confirmation_key ||= redis_handler.get_property(self.token, 'confirmation_key')
  end

  def redis_handler
    @redis_handler ||= ImportTools::RedisHandler.new
  end
end
