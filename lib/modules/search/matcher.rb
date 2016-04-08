class Search::Matcher
  MATCHERS = {
    should: [
      { type: 'nested', path: 'countries_for_index', fields: ['countries_for_index.name'] },
      { type: 'nested', path: 'countries_for_index.region_for_index', fields: ['countries_for_index.region_for_index.name'] },
      { type: 'nested', path: 'sub_location', fields: ['sub_location.english_name'] },
      { type: 'nested', path: 'designation', fields: ['designation.name'] },
      { type: 'nested', path: 'iucn_category', fields: ['iucn_category.name'] },
      { type: 'nested', path: 'governance', fields: ['governance.name'] },
      { type: 'terms',  path: 'wdpa_id'},
      {
        type: 'multi_match',
        fields: ['name', 'original_name'],
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

  def initialize term, options
    @term = term
    @options = options
  end

  def to_h
    matcher.to_h
  end

  def self.from_params term
    constructed_matchers = {}

    MATCHERS.each do |type, matchers|
      matchers.each do |matcher|
        constructed_matchers[type.to_s] ||= []
        constructed_matchers[type.to_s].push self.new(term, matcher).to_h
      end
    end

    constructed_matchers
  end

  private

  def matcher
    matcher_type  = ActiveSupport::Inflector.camelize(@options[:type].to_s.sub(/.*\./, ''))
    matcher_class = "Search::Matcher::#{matcher_type}".constantize

    matcher_class.new @term, @options
  end
end
