class Download::Requesters::Base
  def self.request *args
    instance = new(*args)
    instance.request
  end

  def request
    raise NotImplementedError, "Override this method to implement a requester"
  end

  def domain
    raise NotImplementedError, "Override this method to implement a requester"
  end

  protected

  def generation_info
    Download.generation_info(domain, identifier, format)
  end

  def json_response
    filename = Download::Utils.filename(domain, identifier, format)
    {
      'id' => computed_id,
      'title' => filename,
      'url' => url(filename),
      'hasFailed' => Download.has_failed?(domain, identifier, format),
      'token' => identifier
    }
  end

  def format
    @format
  end

  def computed_id
    "#{identifier}-#{format}"
  end

  def url(filename)
    generation_info['status'] == 'ready' ? Download.link_to(filename) : ''
  end
end
