class Download::Requesters::Pdf < Download::Requesters::Base
  def initialize token
    # token can be SITE_ID or ISO
    @token = token
  end

  def request
    enqueue_generation_once do
      DownloadWorkers::Pdf.perform_async identifier
    end

    json_response
  end

  def domain
    'pdf'
  end

  def format
    'pdf'
  end

  private

  def identifier
    @token
  end
end