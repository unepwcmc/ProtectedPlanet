class Download::Requesters::Pdf < Download::Requesters::Base
  def initialize token
    # token can be WDPAID or ISO
    @token = token
  end

  def request
    unless ['ready', 'generating'].include? generation_info['status']
      DownloadWorkers::Pdf.perform_async identifier
    end

    {'token' => identifier}.merge(generation_info)
  end

  def domain
    'pdf'
  end

  private

  def identifier
    @token
  end
end