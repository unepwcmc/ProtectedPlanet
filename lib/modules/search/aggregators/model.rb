module Search::Aggregators::Model
  def self.build name, raw_aggregations, config
    model = (config['class'] || name.classify).constantize

    raw_aggregations[name]['aggregation']['buckets'].map do |info|
      label = model.select(:name).find(info['key']).name
      {
        identifier: label,
        query: config['query'] || name,
        label: label,
        count: info['doc_count']
      }
    end
  end
end
