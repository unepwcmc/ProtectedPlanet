class Search::Matcher::Nested < Search::Matcher
  def to_h
    {
      "nested" => {
        "path" => @options[:path],
        "query" => {
          "fuzzy_like_this" => {
            "like_text" => @term,
            "fields" => @options[:fields]
          }
        }
      }
    }
  end
end
