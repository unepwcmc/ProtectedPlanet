module Download::Poller
  def self.poll(params)
    json_response(params)
  end

  private

  def self.json_response(params)
    domain = params['domain']
    filters = params['filters'] && Download::Utils.extract_filters(JSON.parse(params['filters']))
    token = filters ? Download::Utils.search_token(search_term(params), filters) : params['token']
    format = params['format']

    filename = Download::Utils.filename(domain, token, format)
    is_ready = Download.is_ready?(domain, token, format)
    {
      'id' => computed_id(token, format),
      'title' => filename,
      'url' => is_ready ? Download.link_to(filename) : '',
      'hasFailed' => Download.has_failed?(domain, token, format)
    }
  end

  def self.computed_id(identifier, format)
    "#{identifier}-#{format}"
  end

  def self.search_term(params)
    params['search'].to_s
  end
end