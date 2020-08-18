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
      'id' => computed_id(_token, _format),
      'title' => info['filename'] || computed_id(_token, _format),
      'url' => Download.link_to(info['filename'], _format),
      'hasFailed' => Download.has_failed?(_domain, _token)
    }
  end

  def self.computed_id(identifier, format)
    "#{identifier}-#{format}"
  end
end