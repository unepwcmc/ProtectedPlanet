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
    info = Download.generation_info(domain, identifier)
    {
      'id' => computed_id,
      'title' => info['filename'] || computed_id,
      'url' => Download.link_to(info['filename'], format),
      'hasFailed' => Download.has_failed?(domain, identifier),
    }
  end

  def format
    @format
  end

  def computed_id
    "#{identifier}-#{format}"
  end
end
