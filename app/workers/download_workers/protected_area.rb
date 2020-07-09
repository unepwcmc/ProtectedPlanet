class DownloadWorkers::ProtectedArea < DownloadWorkers::Base
  def perform format, wdpa_id, opts={}
    while_generating(key(wdpa_id)) do
      Download.generate format, filename(wdpa_id), opts.symbolize_keys.merge({wdpa_ids: [wdpa_id]})
      {status: 'ready', filename: filename(wdpa_id)}.to_json
    end
  end

  protected

  def domain
    'protected_area'
  end
end

