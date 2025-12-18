class DownloadWorkers::Pdf < DownloadWorkers::Base
  def perform identifier
    while_generating(key(identifier, format)) do
      success = Download.generate format, filename(identifier, format), {identifier: identifier}
      raise "Download.generate returned false (#{domain} #{format} #{identifier})" unless success
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