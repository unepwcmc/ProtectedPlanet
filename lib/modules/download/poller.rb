module Download::Poller
  def self.poll(domain, token)
    status = Download::Utils.properties Download::Utils.key(domain, token)
    json_response(token, status)
  end

  private

  def self.json_response(identifier, status)
    {
      'id' => identifier,
      'title' => identifier,
      'url' => '',
      'hasFailed' => status
    }
  end
end