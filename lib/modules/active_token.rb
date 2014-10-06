module ActiveToken
  def self.included receiver
    receiver.extend ClassMethods
  end

  module ClassMethods
    def find token, *attrs
      return nil unless $redis.exists(token_key(token))
      new(*attrs).tap{ |instance| instance.token = token }
    end

    def create token=generate_token, *attrs
      $redis.hset(token_key(token), 'created_at', Time.now.to_i)
      new(*attrs).tap{ |instance| instance.token = token }
    end

    def token_key token
      "#{@@domain}:#{token}"
    end

    private

    def token_domain domain
      @@domain = domain
    end
  end

  attr_accessor :token

  def properties
    @properties ||= ActiveToken::Properties.new self.class.token_key(token)
  end

  def generate_token generator=lambda{}
    (generator.call || SecureRandom.hex(10)).to_s
  end
  module_function :generate_token
end
