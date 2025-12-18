class DownloadWorkers::ProtectedArea < DownloadWorkers::Base
  def perform(format, site_id, opts = {})
    while_generating(key(site_id, format)) do
      success = Download.generate format, filename(site_id, format), opts.symbolize_keys.merge({ site_ids: [site_id] })
      raise "Download.generate returned false (#{domain} #{format} #{site_id})" unless success
      { status: 'ready', filename: filename(site_id, format) }.to_json
    end
  end

  protected

  def domain
    'protected_area'
  end
end
