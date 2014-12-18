class Search::Aggregators::Model
  def self.build name, raw_aggregation, config
    model = (config['class'] || name.classify).constantize

    raw_aggregation['aggregation']['buckets'].map do |info|
      {
        identifier: info['key'],
        query: config['query'] || name,
        label: model.select(:name).find(info['key']).name,
        count: info['doc_count']
      }
    end
  end
end
