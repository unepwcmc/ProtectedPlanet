class Search::Query
  def initialize search_term, options={}
    @term = search_term
    @options = options
  end

  def to_h_new
    pa_query = {}
    country_query = {}
    if @term.present?
      pa_query["bool"] ||= {}
      pa_query["bool"]["must"] = {
        "bool" => Search::Matcher.from_params(@term)
      }
      # ^3 weights the field higher as ISO3 exact matches should beat country matches which should beat region matches
      country_query["bool"] ||= {  
        must: {
          multi_match: {
            query:      @term,
            fields:   ["name^2", "iso_3^3", "region_for_index"]
          }
        }
      }
    end


    
    if @options[:filters].present?
      pa_query["bool"] ||= {}
      pa_query["bool"]["filter"] = {
        "bool" => {
          "must" => Search::Filter.from_params(@options[:filters])
        }
        }
    end

    query = {
      bool:  {
        should: [
            pa_query,
            country_query

        ]
      }
    }
    
  end
  
  def to_h
    base_query = {}

    if @term.present?
      base_query["bool"] ||= {}
      base_query["bool"]["must"] = {
        "bool" => Search::Matcher.from_params(@term)
      }
      # ^3 weights the field higher as ISO3 exact matches should beat country matches which should beat region matches
      #base_query["bool"] ||= {  
      #  must: {
      #    multi_match: {
      #      query:      @term,
      #      fields:   ["name^2", "iso_3^3", "countries_for_index", "region_for_index"]
      #    }
      #  }
      #}
    end


    
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
