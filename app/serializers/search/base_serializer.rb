class Search::BaseSerializer
  def initialize(search, opts={})
    unless search.is_a?(Search)
      raise ArgumentError, 'Results argument must be of type Search'
    end
    @search = search
    @results = search.results
    @search_term = search.search_term
    @options = opts
    @page = @search.current_page
  end

  def serialize
    raise NotImplementedError
  end

  private

  def paginate(items)
    size = @search.options[:size]
    page = @search.options[:page]
    offset = size * (page - 1)
    last_item = size * page - 1

    items[offset..last_item].presence || []
  end
end
