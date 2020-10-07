class Search::Query
  def initialize search_term, options={}
    @term = search_term
    @options = options
  end

  def to_h
    base_query = {}

    base_query["bool"] ||= {}
    base_query["bool"]["must"] = {
      "bool" => Search::Matcher.from_params(@term)
    }

    if @options[:filters].present?
      base_query["bool"] ||= {}
      base_query["bool"]["filter"] = {
        "bool" => {
          "must" => Search::Filter.from_params(@options[:filters])
        }
      }
    end

    base_query
  end
end
