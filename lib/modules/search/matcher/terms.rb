class Search::Matcher::Terms < Search::Matcher
  def to_h
    ids = @term.split(',').map(&:strip).map(&:to_i)
    ids = [] if ids.include?(0)

    {"terms" => {@options[:path] => ids}}
  end
end
