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
    Download::Utils.properties(Download::Utils.key(domain, identifier))
  end

  def json_response
    {
      'id' => identifier,
      'title' => identifier,
      'url' => '',
      'hasFailed' => has_failed?,
    }
  end

  def has_failed?
    !%w(generating ready).include?(generation_info['status'])
  end
end
