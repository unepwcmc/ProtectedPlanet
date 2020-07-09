class Download::Requesters::General < Download::Requesters::Base
  def initialize format, token
    @format = format
    @token = token
  end

  def request
    unless ['ready', 'generating'].include? generation_info['status']
      type = if identifier == "marine"
               "marine"
             else
               (identifier == "all" ? "general" :  "country")
             end
      DownloadWorkers::General.perform_async(@format, type, identifier)
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
