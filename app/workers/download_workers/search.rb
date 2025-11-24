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
    Download.generate(@format, filename(ids_digest, @format), { site_ids: protected_area_site_ids })
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
