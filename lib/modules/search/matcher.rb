class Search::Matcher
  def initialize term, options
    @term = term
    @options = options
  end

  def to_h
    matcher.to_h
  end

  private

  def matcher
    matcher_type  = @options[:type].classify
    matcher_class = "Search::Matcher::#{matcher_type}".constantize

    matcher_class.new @term, @options
  end
end
