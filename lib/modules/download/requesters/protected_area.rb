class Download::Requesters::ProtectedArea < Download::Requesters::Base
  def initialize format, site_id
    @format = format
    @site_id = site_id
  end

  def request
    enqueue_generation_once do
      DownloadWorkers::ProtectedArea.perform_async(@format, identifier)
    end

    json_response
  end

  def domain
    'protected_area'
  end

  private

  def identifier
    @site_id
  end
end

