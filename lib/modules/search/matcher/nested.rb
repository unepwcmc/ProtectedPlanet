class Search::Matcher::Nested < Search::Matcher
  def to_h
    {
      "nested" => {
        "path" => @options[:path],
        "query" => query
      }
    }
  end

  private

  def query
    if @term.blank?
      {
        "match_all" => {}
      }
    else
      {
        "multi_match" => {
          "query" => @term,
          "fields" => @options[:fields],
          "fuzziness" => "0"
        }
      }
    end
  end
end
