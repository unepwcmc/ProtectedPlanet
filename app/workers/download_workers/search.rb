class DownloadWorkers::Search < DownloadWorkers::Base
  def perform token, search_term, filters
    @token = token
    @search_term = search_term
    @filters_json = filters.to_json
    @filters_values = filters.values

    while_generating(key(token)) do
      generate_download
      {status: 'ready', filename: filename(ids_digest)}.to_json
    end
  end

  protected

  def domain
    'search'
  end

  def generate_download
    Download.generate(filename(ids_digest), {wdpa_ids: protected_area_ids})
    send_completion_email unless email.blank?
  end

  def send_completion_email
    DownloadCompleteMailer.create(filename(ids_digest), email).deliver
  end

  def ids_digest
    sha = Digest::SHA256.hexdigest(protected_area_ids.join)
    return "#{sha}" if @search_term.blank?
    return "#{@search_term}_#{sha}".gsub(' ', '_') if @filters_values.empty?
    filter = @filters_values.map { |f| f[0..9] }.join(',')
    "#{@search_term[0..11]}_#{filter}_#{sha}".gsub(' ', '_')
  end

  def email
    Download::Utils.properties(key(@token))['email']
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
