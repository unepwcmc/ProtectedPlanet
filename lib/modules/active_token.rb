module ActiveToken
  def self.included receiver
    receiver.extend ClassMethods
  end

  module ClassMethods
    def find token, *attrs
      return nil unless $redis.exists(token_key(token))
      self.new(*attrs).tap{ |instance| instance.token = token }
    end

    def create token=generate_token, *attrs
      token = shaify_token(token)

      $redis.hset(token_key(token), 'created_at', Time.now.to_i)
      self.new(*attrs).tap{ |instance| instance.token = token }
    end

    def token_key token, property=nil
      "#{@@domain}:#{token}"
    end

    private
    def token_domain domain
      @@domain = domain
    end

    def shaify_token token
      Digest::SHA256.hexdigest token
    end
  end

  attr_accessor :token

  def properties
    @properties ||= ActiveToken::Properties.new self.class.token_key(self.token)
  end

  def generate_token generator=lambda{}
    (generator.call || SecureRandom.hex(10)).to_s
  end
  module_function :generate_token
end
