class DownloadWorkers::Pdf < DownloadWorkers::Base
  def perform identifier
    while_generating(key(identifier)) do
      Download.generate format, filename(identifier), {identifier: identifier}
      {status: 'ready', filename: filename(identifier)}.to_json
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