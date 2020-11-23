class DownloadWorkers::Search < DownloadWorkers::Base
  def perform format, token, search_term, filters
    @format = format
    @token = token
    @search_term = search_term
    @filters_json = filters
    @filters_values = JSON.load(filters).values.flatten

    while_generating(key(token, format)) do
      generate_download
      {status: 'ready', filename: filename(ids_digest, format)}.to_json
    end
  end

  protected

  def domain
    'search'
  end

  def generate_download
    Download.generate(@format, filename(ids_digest, @format), {wdpa_ids: protected_area_ids})
  end

  def ids_digest
    sha = Download::Utils.search_token(@search_term, JSON.parse(@filters_json))
    return "#{sha}" if @search_term.blank?
    return "#{@search_term}_#{sha}".gsub(' ', '_') if @filters_values.empty?
    filter = @filters_values.map { |f| f.to_s[0..9] }.join(',')
    "#{@search_term[0..11]}_#{filter}_#{sha}".gsub(' ', '_')
  end

  def protected_area_ids
    search.wdpa_ids
  end

  def search
    @search ||= SavedSearch.new(
      search_term: @search_term,
      filters: @filters_json
    )
  end
end
