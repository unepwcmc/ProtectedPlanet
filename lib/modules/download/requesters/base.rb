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
    Download.generation_info(domain, identifier)
  end

  def json_response
    {
      'id' => identifier,
      'title' => identifier,
      'url' => '',
      'hasFailed' => Download.has_failed?(domain, identifier),
    }
  end
end
