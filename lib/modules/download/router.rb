module Download::Router
  def self.request domain, params
    case domain
    when 'general'
      Download::Requesters::General.request(params['id'])
    when 'search'
      Download::Requesters::Search.request(params['q'], extract_filters(params))
    end
  end

  def self.poll domain, params
    case domain
    when 'general'
      Download::Pollers::General.poll(params['token'])
    when 'search'
      Download::Pollers::Search.poll(params['token'])
    end
  end

  def self.set_email domain, params
    key = Download::Utils.key(domain, params['id'])

    Download::Utils.properties(key).tap{ |properties|
      properties['email'] = params['email']
      $redis.set(key, properties.to_json)
    }
  end

  private

  def self.extract_filters params
    params.stringify_keys.slice(*::Search::ALLOWED_FILTERS)
  end
end
