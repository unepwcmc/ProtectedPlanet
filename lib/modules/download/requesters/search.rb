class Download::Requesters::Search < Download::Requesters::Base
  def initialize search_term, opts
    @search_term = search_term
    @opts = opts
  end

  def request
    search = Search.download(@search_term, @opts)
    {token: search.token, status: search.properties['status']}
  end
end
