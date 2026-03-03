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
    # As of 05Feb2026 we are fetching all site_ids for creating views in Download.generate and it can be 350,000 site_ids max at the dated time it can be a lot more in future.
    # At some point we will need to change this to use proper query build up when we start noticing the slow down in performance.
    success = Download.generate(@format, filename(ids_digest, @format), { site_selection: { site_ids: protected_area_site_ids } })
    raise "Download.generate returned false (#{domain} #{@format} #{@token})" unless success
  end

  def ids_digest
    return "#{@token}" if @search_term.blank?
    return "#{@search_term}_#{@token}".gsub(' ', '_') if @filters_values.empty?

    filter = @filters_values.map { |f| f.to_s[0..9] }.join(',')
    "#{@search_term[0..11]}_#{filter}_#{@token}".gsub(' ', '_')
  end

  def protected_area_site_ids
    search.all_site_ids
  end

  def search
    @search ||= SavedSearch.new(
      search_term: @search_term,
      filters: @filters_json
    )
  end
end
