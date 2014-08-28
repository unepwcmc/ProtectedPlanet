class Search::Filter::Nested < Search::Filter
  def to_h
    {
      "nested" => {
        "path" => @options[:path],
        "filter" => {
          "bool" => {
            bool_key => term
          }
        }
      }
    }
  end

  private

  def bool_key
    @options[:required] ?  "must" : "must_not"
  end

  def term
    {
      "term" => {
        @options[:field] => @term
      }
    }
  end
end
