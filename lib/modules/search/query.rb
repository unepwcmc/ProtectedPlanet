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

    if @options[:filters].present?
      base_query["filtered"]["filter"] = {
        "and" => Search::Filter.from_params(@options[:filters])
      }
    end

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
      {
        type: 'multi_match',
        fields: ['name', 'original_name' ],
        boost: true,
        functions: [
          "filter" => {
            "or" => [
              { "type" => { "value" => "country"} },
              { "type" => { "value" => "region"} }
            ]
          },
          "boost_factor" => 15
        ]
      }
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
end
