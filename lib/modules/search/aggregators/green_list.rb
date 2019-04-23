module Search::Aggregators::GreenList
  def self.build name, raw_aggregations, config
    raw_aggregations[name]['buckets'].map do |info|
      label = info['key']

      {
        identifier: label,
        query: config['query'] || name,
        label: label,
        count: info['doc_count']
      }
    end
  end
end
