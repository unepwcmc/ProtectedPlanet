class SearchDownloader
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform token, search_term, options
    @search_term = search_term
    @token = token
    @options = options

    generate_download
    complete_search
  end

  private

  def generate_download
    Download.generate(filename, {wdpa_ids: protected_area_ids})
  end

  def complete_search
    search.properties['filename'] = filename
    search.complete!
  end

  def search
    @search ||= begin
      instance = Search.search(@search_term, {
        filters: {'type' => 'protected_area'}.merge(@options[:filters] || {}),
        size: ProtectedArea.count,
        without_aggregations: true
      })
      instance.token = @token
      instance
    end
  end

  def create_ids_digest
    Digest::SHA256.hexdigest(protected_area_ids.join)
  end

  def protected_area_ids
    @pa_ids ||= search.pluck('id')
  end

  def filename
    "search_#{create_ids_digest}"
  end
end
