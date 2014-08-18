class Search::Query
  def initialize search_term, options={}
    @term = search_term
    @options = options
  end

  def to_h
    base_query = template
    base_query["filtered"]["query"] = {"bool" => matchers}
    base_query["filtered"]["filter"] = {"and" => filters} if @options[:filters].present?

    base_query
  end

  private

  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'templates')
  TEMPLATE = File.read(File.join(TEMPLATE_DIRECTORY, 'query_base.json'))

  MATCHERS = {
    should: [
      { type: 'nested', path: 'countries', fields: ['countries.name'] },
      { type: 'nested', path: 'countries.region', fields: ['countries.region.name'] },
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
    country: { type: 'nested', path: 'countries.region', term: 'countries.region.id', required: true }
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

  def template
    JSON.parse(TEMPLATE)
  end
end
