class Download::Requesters::General < Download::Requesters::Base
  def initialize token
    @token = token
  end

  def request
    unless ['ready', 'generating'].include? generation_info['status']
      type = (identifier == "all" ? "general" : "country")
      DownloadWorkers::General.perform_async type, identifier
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
