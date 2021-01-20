module Download::Poller
  def self.poll(params)
    json_response(params)
  end

  private

  def self.json_response(params)
    domain = params['domain']
    token = domain == 'search' ? params['backEndToken'] : params['token']
    format = params['format']

    generation_info = Download.generation_info(domain, token, format)
    is_ready = generation_info['status'] == 'ready'
    # If not ready, generate the filename again even if won't match the final one.
    # When ready, get the filename set by the generator
    filename = is_ready ? generation_info['filename'] : Download::Utils.filename(domain, token, format)
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
end