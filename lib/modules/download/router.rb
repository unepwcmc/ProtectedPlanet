module Download::Router
  # params['format'] to be one of csv, shp, gdb
  def self.request domain, params
    case domain
    when 'general'
      Download::Requesters::General.request(params['format'], params['token'])
    when 'search'
      Download::Requesters::Search.request(params['format'], params['q'], extract_filters(params))
    when 'protected_area'
      Download::Requesters::ProtectedArea.request(params['format'], params['token'])
    when 'pdf'
      Download::Requesters::Pdf.request(params['token'])
    end
  end

  def self.poll domain, params
    case domain
    when 'general'
      Download::Pollers::General.poll(params['token'])
    when 'search'
      Download::Pollers::Search.poll(params['token'])
    when 'protected_area'
      Download::Pollers::ProtectedArea.poll(params['token'])
    when 'pdf'
      Download::Pollers::Pdf.poll(params['token'])
    end
  end

  # TODO This could probably go as should be about the old way of notifying
  # a user about downloads statuses
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
