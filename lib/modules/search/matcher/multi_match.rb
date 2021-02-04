class Search::Matcher::MultiMatch < Search::Matcher
  def to_matcher_hash
    @options[:boost] ? query_with_booster : query
  end

  private

  def query_with_booster
    {
      "function_score" => {
        "query" => query,
        "boost" => "5",
        "functions" => @options[:functions]
      }
    }
  end
  
  def query
    if @term.blank?
      {
        "match_all" => {}
      }
    else
      {
        "multi_match" => {
          "query" => "#{@term}",
          "fields" => @options[:fields],
          "minimum_should_match" => @options[:minimum_should_match] || "0%",
          "fuzziness" => "0"
        }
      }
    end
  end
end
