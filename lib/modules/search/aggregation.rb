class Search::Aggregation
  AGGREGATORS = {
    'boolean' => Search::Aggregators::Boolean,
    'model'   => Search::Aggregators::Model,
    'grouped' => Search::Aggregators::Grouped
  }

  TEMPLATE_DIRECTORY = File.join(File.dirname(__FILE__), 'templates')
  TEMPLATE = File.read(File.join(TEMPLATE_DIRECTORY, 'aggregations.json'))

  def self.parse raw_aggregations
    configuration.each_with_object({}) do |(aggregation, config), aggregations|
      aggregator = aggregator_for(aggregation)

      aggregations[aggregation] = aggregator.build(aggregation, raw_aggregations, config)
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
