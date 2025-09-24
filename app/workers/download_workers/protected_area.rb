class DownloadWorkers::ProtectedArea < DownloadWorkers::Base
  def perform(format, site_id, opts = {})
    while_generating(key(site_id, format)) do
      Download.generate format, filename(site_id, format), opts.symbolize_keys.merge({ site_ids: [site_id] })
      { status: 'ready', filename: filename(site_id, format) }.to_json
    end
  end

  protected

  def domain
    'protected_area'
  end
end
