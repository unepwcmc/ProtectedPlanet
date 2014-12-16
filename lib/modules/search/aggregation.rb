class Search::Aggregation
  AGGREGATORS = {
    'boolean' => Search::Aggregators::Boolean,
    'model'   => Search::Aggregators::Model
  }

  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'templates')
  TEMPLATE = File.read(File.join(TEMPLATE_DIRECTORY, 'aggregations.json'))

  def self.parse raw_aggregations
    {}.tap do |aggregations|
      raw_aggregations.each do |name, hash|
        aggregator = aggregator_for(name)
        config = configuration[name]

        aggregations[name] = aggregator.build(name, hash, config)
      end
    end
  end

  def self.all
    @@json ||= JSON.parse(TEMPLATE)
  end

  def self.configuration
    Search.configuration['aggregations']
  end

  def self.aggregator_for name
    AGGREGATORS[configuration[name]['type']]
  end

  def self.configuration_for name
    configuration[name]
  end
end
