class Search::Query
  def initialize search_term, options={}
    @term = search_term
    @options = options
  end

  def to_h
    base_query = {}

    if @term.present?
      base_query["filtered"] ||= {}
      base_query["filtered"]["query"] = {
        "bool" => Search::Matcher.from_params(@term)
      }
    end

    if @options[:filters].present?
      base_query["filtered"] ||= {}
      base_query["filtered"]["filter"] = {
        "and" => Search::Filter.from_params(@options[:filters])
      }
    end

    base_query
  end
end
