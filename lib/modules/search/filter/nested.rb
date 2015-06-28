class Search::Filter::Nested < Search::Filter
  def to_h
    if @term.kind_of? Array
      return @term.each_with_object([]) do |value, filters|
        filters.push(filter(value))
      end
    else
      filter(@term)
    end
  end

  private

  def filter value
    {
      "nested" => {
        "path" => @options['path'],
        "filter" => {
          "bool" => {
            bool_key => {
              "term" => {
                @options['field'] => value
              }
            }
          }
        }
      }
    }
  end

  def bool_key
    @options['required'] ?  "must" : "must_not"
  end
end
