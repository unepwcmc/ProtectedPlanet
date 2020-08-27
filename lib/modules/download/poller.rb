module Download::Poller
  def self.poll(params)
    json_response(params)
  end

  private

  def self.json_response(params)
    domain = params['domain']
    filters = get_filters(params)
    token = filters ? Download::Utils.search_token(search_term(params), filters) : params['token']
    format = params['format']

    generation_info = Download.generation_info(domain, token, format)
    filename = generation_info['filename']
    is_ready = generation_info['status'] == 'ready'
    {
      'id' => computed_id(token, format),
      'title' => filename,
      'url' => is_ready ? Download.link_to(filename) : '',
      'hasFailed' => Download.has_failed?(domain, token, format),
      'token' => token
    }
  end

  def self.computed_id(identifier, format)
    "#{identifier}-#{format}"
  end

  def self.search_term(params)
    params['search'].to_s
  end

  def self.get_filters(params)
    return unless params['search']
    params['filters'] ? Download::Utils.extract_filters(JSON.parse(params['filters'])) : {}
  end
end