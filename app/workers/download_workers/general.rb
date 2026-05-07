class DownloadWorkers::General < DownloadWorkers::Base
  def perform(format, type, identifier, opts = {})
    while_generating(key(identifier, format)) do

      options = opts.symbolize_keys.merge(
        site_selection: build_site_selection(type, identifier)
      )

      success = Download.generate format, filename(identifier, format), options
      raise "Download.generate returned false (#{domain} #{format} #{identifier})" unless success
      { status: 'ready', filename: filename(identifier, format) }.to_json
    end
  end

  protected

  def domain
    'general'
  end
end
