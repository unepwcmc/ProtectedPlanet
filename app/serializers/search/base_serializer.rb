class Search::BaseSerializer
  def initialize(search, opts={})
    unless search.is_a?(Search)
      raise ArgumentError, 'Results argument must be of type Search'
    end
    @search = search
    @results = search.results
    @search_term = search.search_term
    @options = opts
  end

  def serialize
    raise NotImplementedError
  end
end
