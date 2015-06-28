class Search::Filter
  FILTERS = {
    type: { type: 'type' },
    marine: { type: 'equality', path: 'marine' },
    iucn_category: { type: 'nested', path: 'iucn_category', field: 'iucn_category.id', required: true },
    designation: { type: 'nested', path: 'designation', field: 'designation.id', required: true },
    location: { type: 'geo', path: 'location', field: 'protected_area.coordinates' },
    has_parcc_info: { type: 'equality', path: 'has_parcc_info' },
    has_irreplaceability_info: { type: 'equality', path: 'has_irreplaceability_info' },
    country: {
      type: 'nested',
      path: 'countries_for_index',
      field: 'countries_for_index.id',
      required: true
    },
    region: {
      type: 'nested',
      path: 'countries_for_index.region_for_index',
      field: 'countries_for_index.region_for_index.id',
      required: true
    }
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
      filter = self.new(value, FILTERS[name.to_sym]).to_h
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
    "location" => -> (value) {
      value.tap { |v|
        v[:coords] = v[:coords].map(&:to_f)
        v[:distance] = v[:distance].to_f
      }
    }
  }

  def standardise value
    CONVERSIONS[@options[:path].to_s].call(value) rescue value
  end

  def filter
    filter_type  = @options[:type].classify
    filter_class = "Search::Filter::#{filter_type}".constantize

    filter_class.new @term, @options
  end
end
