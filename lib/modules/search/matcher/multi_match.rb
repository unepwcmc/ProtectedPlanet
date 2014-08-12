class Search::Matcher::MultiMatch < Search::Matcher
  def to_h
    {
      "multi_match" => {
        "query" => "*#{@term}*",
        "fields" => @options[:fields]
      }
    }
  end
end
