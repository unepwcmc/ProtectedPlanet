module Search::Aggregators::Model
  def self.build name, raw_aggregations, config
    model = (config['class'] || name.classify).constantize
    infos = raw_aggregations[name]['aggregation']['buckets']

    ids = infos.map { |info| info["key"] }
    labels = model.select(:name).find(ids).map(&:name)

    labels.zip(infos).map do |(label, info)|
      {
        identifier: info['key'],
        query: config['query'] || name,
        label: label,
        count: info['doc_count']
      }
    end
  end
end
