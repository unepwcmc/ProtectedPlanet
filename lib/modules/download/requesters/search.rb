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

    json_response
  end

  def domain
    'search'
  end

  def identifier
    token
  end

  def token
    @token ||= Download::Utils.search_token(@search_term, filters)
  end
  
  private

  def filters
    @filters
  end
end
