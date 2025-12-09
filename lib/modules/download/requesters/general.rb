class Download::Requesters::General < Download::Requesters::Base
  TYPE_MAP = {
    all_wdpca: 'all',
    all_marine_wdpca: 'marine',
    all_greenlisted_wdpca: 'greenlist'
  }.freeze

  def initialize format, token
    @format = format
    @token = token
  end

  def request
    unless ['ready', 'generating'].include? generation_info['status']
      DownloadWorkers::General.perform_async(@format, type, identifier)
    end

    json_response
  end

  def domain
    'general'
  end

  private

  def identifier
    @token
  end

  def type
    if TYPE_MAP.values.include?(identifier)
      identifier
    else
      (identifier.length == 2 ? "region" : "country")
    end
  end
end
