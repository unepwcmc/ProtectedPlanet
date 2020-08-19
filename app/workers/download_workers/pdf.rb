class DownloadWorkers::Pdf < DownloadWorkers::Base
  def perform identifier
    while_generating(key(identifier, format)) do
      Download.generate format, filename(identifier, format), {identifier: identifier}
      {status: 'ready', filename: filename(identifier, format)}.to_json
    end
  end

  protected

  def domain
    'pdf'
  end

  def format
    'pdf'
  end
end