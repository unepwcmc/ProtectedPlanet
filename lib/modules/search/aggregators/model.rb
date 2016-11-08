module Search::Aggregators::Model
  def self.build name, raw_aggregations, config
    model = (config['class'] || name.classify).constantize

    raw_aggregations[name]['aggregation']['buckets'].map do |info|
      {
        identifier: info['key'],
        query: config['query'] || name,
        label: model.select(:name).find(info['key']).name,
        count: info['doc_count']
      }
    end
  end
end
