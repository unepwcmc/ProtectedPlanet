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
    {
      'id' => computed_id,
      'title' => filename,
      'url' => url(filename),
      'hasFailed' => Download.has_failed?(domain, identifier, format),
      'token' => identifier
    }
  end

  def filename
    if ready?
      generation_info['filename']
    else
      if domain == 'search'
        # Use the 'backend token' / SHA256 digest instead of the normal token
        Download::Utils.filename(domain, token, format) 
      else
        Download::Utils.filename(domain, identifier, format)
      end
    end
  end

  def format
    @format
  end

  def computed_id
    "#{identifier}-#{format}"
  end

  def ready?
    generation_info['status'] == 'ready'
  end

  def url(filename)
    ready? ? Download.link_to(filename) : ''
  end
end
