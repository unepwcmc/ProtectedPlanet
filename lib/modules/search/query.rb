class Search::Query
  def initialize search_term, options={}
    @term = search_term
    @options = options
  end

  def to_h
    base_query = {
      "filtered" => {
        "query" => {
          "bool" => matchers
        }
      }
    }

    base_query["filtered"]["filter"] = {"and" => filters} if @options[:filters].present?

    base_query
  end

  private

  MATCHERS = {
    should: [
      { type: 'nested', path: 'countries_for_index', fields: ['countries_for_index.name'] },
      { type: 'nested', path: 'countries_for_index.region_for_index', fields: ['countries_for_index.region_for_index.name'] },
      { type: 'nested', path: 'sub_location', fields: ['sub_location.english_name'] },
      { type: 'nested', path: 'designation', fields: ['designation.name'] },
      { type: 'nested', path: 'iucn_category', fields: ['iucn_category.name'] },
      { type: 'multi_match', fields: ['name', 'original_name' ] }
    ]
  }

  def matchers
    constructed_matchers = {}

    MATCHERS.each do |type, matchers|
      matchers.each do |matcher|
        constructed_matchers[type.to_s] ||= []
        constructed_matchers[type.to_s].push Search::Matcher.new(@term, matcher).to_h
      end
    end

    constructed_matchers
  end

  FILTERS = {
    type: { type: 'type' },
    country: { type: 'nested', path: 'countries_for_index', field: 'countries_for_index.id', required: true },
    region: { type: 'nested', path: 'countries_for_index.region_for_index', field: 'countries_for_index.region_for_index.id', required: true },
    iucn_category: { type: 'nested', path: 'iucn_category', field: 'iucn_category.id', required: true },
    designation: { type: 'nested', path: 'designation', field: 'designation.id', required: true }
  }

  def filters
    constructed_filters = []
    requested_filters = @options[:filters] || []

    requested_filters.each do |filter|
      constructed_filters.push Search::Filter.new(
        filter[:value], FILTERS[filter[:name].to_sym]
      ).to_h
    end

    constructed_filters
  end
end
