class Download::Requesters::ProtectedArea < Download::Requesters::Base
  def initialize format, wdpa_id
    @format = format
    @wdpa_id = wdpa_id
  end

  def request
    unless ['ready', 'generating'].include? generation_info['status']
      DownloadWorkers::ProtectedArea.perform_async(format, identifier)
    end

    {'token' => identifier}.merge(generation_info)
  end

  def domain
    'protected_area'
  end

  private

  def identifier
    @wdpa_id
  end
end

