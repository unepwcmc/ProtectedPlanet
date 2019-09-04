class Search::Matcher::Nested < Search::Matcher
  def to_h
    {
      "nested" => {
        "path" => @options[:path],
        "query" => {
          "multi_match" => {
            "query" => @term,
            "fields" => @options[:fields],
            "fuzziness" => "0"
          }
        }
      }
    }
  end
end
