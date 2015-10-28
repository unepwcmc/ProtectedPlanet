module Search::Aggregators::Boolean
  def self.build name, raw_aggregations, config
    with_identifier = -> info { config['identifiers'][info['key']].nil? }

    raw_aggregations[name]['buckets'].reject(&with_identifier).map do |info|
      {
        label: config['labels'][info['key']],
        query: config['query'] || name,
        identifier: config['identifiers'][info['key']],
        count: info['doc_count']
      }
    end
  end
end
