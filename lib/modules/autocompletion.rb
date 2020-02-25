module Autocompletion
  AUTOCOMPLETION_KEY = "autocompletion"

  def self.lookup term
    limit = {limit: [0, 5]}

    $redis.zrangebylex(AUTOCOMPLETION_KEY, "(#{term.downcase}", "+", limit).map do |result|
      result = result.split("||")

      term = result[0]
      name = result[1]
      type = result[2]
      identifier = result[3]

      url = type == 'protected_area' ? "/#{identifier}" : "/country/#{identifier}"

      { title: name, url: url }
    end
  end

  def self.populate
    ProtectedArea.pluck(:name, :wdpa_id).each do |name, wdpa_id|
      $redis.zadd(AUTOCOMPLETION_KEY, 0, "#{name.downcase}||#{name}||protected_area||#{wdpa_id}")
    end

    Country.pluck(:name, :iso).each do |name, iso|
      $redis.zadd(AUTOCOMPLETION_KEY, 0, "#{name.downcase}||#{name}||country||#{iso}")
    end
  end

  def self.drop
    $redis.del(AUTOCOMPLETION_KEY)
  end
end
