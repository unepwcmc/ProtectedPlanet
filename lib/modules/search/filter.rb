class Search::Filter
  FILTERS = {
    type: { type: 'type' },
    country: { type: 'nested', path: 'countries_for_index', field: 'countries_for_index.id', required: true },
    region: { type: 'nested', path: 'countries_for_index.region_for_index', field: 'countries_for_index.region_for_index.id', required: true },
    iucn_category: { type: 'nested', path: 'iucn_category', field: 'iucn_category.id', required: true },
    designation: { type: 'nested', path: 'designation', field: 'designation.id', required: true },
    location: { type: 'geo', field: 'protected_area.coordinates' },
  }

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
      constructed_filters.push self.new(
        value, FILTERS[name.to_sym]
      ).to_h
    end

    constructed_filters
  end

  private

  CONVERSIONS = {
    "countries_for_index" => -> (value) { value.to_i },
    "countries_for_index.region_for_index" => -> (value) { value.to_i },
    "iucn_category" => -> (value) { value.to_i },
    "designation" => -> (value) { value.to_i }
  }

  def standardise value
    CONVERSIONS[@options[:path]].try(:call, value) || value
  end

  def filter
    filter_type  = @options[:type].classify
    filter_class = "Search::Filter::#{filter_type}".constantize

    filter_class.new @term, @options
  end
end
