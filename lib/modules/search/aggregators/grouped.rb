module Search::Aggregators::Grouped
  def self.build group_name, raw_aggregations, config
    config['members'].inject([]) do |all_aggs, (name, aggregation_config)|
      type = aggregation_config['type']

      all_aggs |= Search::Aggregation::AGGREGATORS[type].build(
        name, raw_aggregations, aggregation_config
      )
    end
  end
end
