class Search::Matcher::MultiMatch < Search::Matcher
  def to_h
    if @options[:boost]
      query_with_booster
    else
      query
    end
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
          "fuzziness" => "0"
        }
      }
    end
  end
end
