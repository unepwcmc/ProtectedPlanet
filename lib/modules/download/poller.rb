module Download::Poller
  def self.poll(params)
    json_response(params)
  end

  private

  def self.json_response(params)
    _domain = params['domain']
    _token = params['token']
    _format = params['format']

    info = Download.generation_info(_domain, _token)
    {
      'id' => _token,
      'title' => info['filename'] || _token,
      'url' => Download.link_to(info['filename'], _format),
      'hasFailed' => Download.has_failed?(_domain, _token)
    }
  end
end