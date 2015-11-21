class Search::Filter
  def initialize term, options
    @options = options
    @term = standardise(term)
  end

  def to_h
    filter.to_h
  end

  def self.from_params params
    constructed_filters = []

    params.each do |name, value|
      filter = self.new(value, configuration[name.to_s]).to_h
      constructed_filters << {
        "bool" => {
          "should" => Array.wrap(filter)
        }
      }
    end

    constructed_filters
  end

  private

  CONVERSIONS = {
    "countries_for_index" => -> (value) { value.to_i },
    "countries_for_index.region_for_index" => -> (value) { value.to_i },
    "iucn_category" => -> (value) { Array.wrap(value).map(&:to_i) },
    "designation" => -> (value) { value.to_i },
    "governance" => -> (value) { value.to_i },
    "location" => -> (value) {
      value.tap { |v|
        v[:coords] = v[:coords].map(&:to_f)
        v[:distance] = v[:distance].to_f
      }
    }
  }

  def self.configuration
    Search.configuration['filters']
  end

  def standardise value
    CONVERSIONS[@options['path'].to_s].call(value) rescue value
  end

  def filter
    filter_type  = @options['type'].classify
    filter_class = "Search::Filter::#{filter_type}".constantize

    filter_class.new @term, @options
  end
end
