class Download::Requesters::Search < Download::Requesters::Base
  def initialize format, search_term, filters
    @format = format
    @search_term = search_term
    @filters = filters
  end

  def request
    unless ['ready', 'generating'].include? generation_info['status']
      DownloadWorkers::Search.perform_async(@format, token, @search_term, filters.to_json)
    end

    {'token' => token}.merge(generation_info)
  end

  def domain
    'search'
  end

  private

  def identifier
    token
  end

  def token
    @token ||= begin
      filters_dump = Marshal.dump filters.keys.sort
      Digest::SHA256.hexdigest(@search_term.to_s + filters_dump)
    end
  end

  def filters
    @filters
  end
end
