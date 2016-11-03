class Download::Requesters::General < Download::Requesters::Base
  def initialize token
    @token = token
  end

  def request
    unless ['ready', 'generating'].include? generation_info['status']
      DownloadWorkers::General.perform_async identifier
    end

    {'token' => identifier}.merge(generation_info)
  end

  def domain
    'general'
  end

  private

  def identifier
    @token
  end
end
