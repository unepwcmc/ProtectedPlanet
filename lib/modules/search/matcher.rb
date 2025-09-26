class Search::Matcher
  MATCHERS = {
    should: [
      # Commented lines are about searching also across nested elements (e.g. countries and regions).
      # Leaving it commented for reference mainly
      # { type: 'nested', path: 'countries_for_index', fields: ['countries_for_index.name'] },
      # { type: 'nested', path: 'countries_for_index.region_for_index', fields: ['countries_for_index.region_for_index.name'] },
      { type: 'nested', path: 'designation', fields: ['designation.name'] },
      { type: 'nested', path: 'iucn_category', fields: ['iucn_category.name'] },
      { type: 'nested', path: 'governance', fields: ['governance.name'] },
      { type: 'terms',  path: 'site_id' },
      {
        type: 'multi_match',
        fields: %w[iso_3 name name.stemmed original_name original_name.stemmed],
        boost: true,
        minimum_should_match: '100%',
        functions: [
          {
            'filter' => { 'match' => { 'type' => 'country' } },
            'weight' => 20
          }, {
            'filter' => { 'match' => { 'type' => 'region' } },
            'weight' => 10
          }
        ]
      },
      {
        type: 'multi_match',
        path: 'label',
        fields: ['label', 'label.english', 'label.french', 'label.spanish']
      },
      {
        type: 'nested',
        path: 'fragments_for_index',
        fields: %w[
          fragments_for_index.content fragments_for_index.content.english
          fragments_for_index.content.french fragments_for_index.content.spanish
        ]
      },
      {
        type: 'nested',
        path: 'translations_for_index.fragments_for_index',
        fields: %w[
          translations_for_index.fragments_for_index.content
          translations_for_index.fragments_for_index.content.english
          translations_for_index.fragments_for_index.content.french
          translations_for_index.fragments_for_index.content.spanish
        ]
      },
      { type: 'nested', path: 'categories', fields: ['categories.label'] },
      { type: 'nested', path: 'topics', fields: ['topics.label'] },
      { type: 'nested', path: 'ancestors', fields: ['ancestors.label'] }
    ]
  }.freeze

  def initialize(term, options)
    @term = term
    @options = options
  end

  def to_matcher_hash
    matcher.to_matcher_hash
  end

  def self.from_params(term)
    constructed_matchers = {}

    MATCHERS.each do |type, matchers|
      matchers.each do |matcher|
        constructed_matchers[type.to_s] ||= []
        constructed_matchers[type.to_s].push(new(term, matcher).to_matcher_hash)
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
