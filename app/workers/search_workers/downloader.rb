class SearchWorkers::Downloader < SearchWorkers::Base
  def perform token, search_term, options
    self.search_term = search_term
    self.token = token
    self.filters = options['filters']

    generate_download
    complete_search
  end

  private

  def generate_download
    Download.generate(filename, {wdpa_ids: protected_area_ids})
    send_completion_email
  end

  def complete_search
    search.properties['links'] = filename
    search.complete!
  end

  def ids_digest
    Digest::SHA256.hexdigest(protected_area_ids.join)
  end

  def filename
    ['csv', 'shp', 'kml'].each_with_object({}) do |type, hash|
      hash[type] = Download.link_to "search_#{ids_digest}", type
    end.to_json
  end

  def send_completion_email
    if email
      DownloadCompleteMailer.
        create(filename, email).
        deliver
    end
  end

  def email
    @email ||= Search.find(self.token).properties['user_email']
  end
end
