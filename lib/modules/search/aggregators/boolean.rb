class Search::Aggregators::Boolean
  def self.build name, raw_aggregation, config
    raw_aggregation['buckets'].map do |info|
      {
        label: config['labels'][info['key']],
        query: config['query'] || name,
        identifier: config['identifiers'][info['key']],
        count: info['doc_count']
      }
    end
  end
end
