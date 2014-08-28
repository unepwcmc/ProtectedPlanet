class Search::Filter
  def initialize term, options
    @term = term
    @options = options
  end

  def to_h
    filter.to_h
  end

  private

  def filter
    filter_type  = @options[:type].classify
    filter_class = "Search::Filter::#{filter_type}".constantize

    filter_class.new @term, @options
  end
end
