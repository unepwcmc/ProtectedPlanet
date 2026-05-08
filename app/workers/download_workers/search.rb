class DownloadWorkers::Search < DownloadWorkers::Base
  def perform(format, token, search_term, filters)
    @format = format
    @token = token
    @search_term = search_term
    @filters_json = filters
    @filters_values = JSON.load(filters).values.flatten

    while_generating(key(token, format)) do
      generate_download
      { status: 'ready', filename: filename(ids_digest, format) }.to_json
    end
  end

  protected

  def domain
    'search'
  end

  def generate_download
    filters = JSON.parse(@filters_json)
    site_selection = build_site_selection('search', filters)
    Rails.logger.info "[DownloadWorkers::Search] token=#{@token} format=#{@format} filters=#{@filters_json}"
    Rails.logger.info "site_selection: #{site_selection.inspect}"
    success = Download.generate(@format, filename(ids_digest, @format), { site_selection: site_selection })
    raise "Download.generate returned false (#{domain} #{@format} #{@token})" unless success
  end

  def ids_digest
    return "#{@token}" if @search_term.blank?
    return "#{@search_term}_#{@token}".gsub(' ', '_') if @filters_values.empty?

    filter = @filters_values.map { |f| f.to_s[0..9] }.join(',')
    "#{@search_term[0..11]}_#{filter}_#{@token}".gsub(' ', '_')
  end
end
