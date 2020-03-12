module Search::Aggregators::Model
  def self.build name, raw_aggregations, config
    model = (config['class'] || name.classify).constantize

    raw_aggregations[name]['aggregation']['buckets'].map do |info|
      column_name = model.has_attribute?(:name) ? :name : :label
      label = model.select(column_name).find(info['key']).send(column_name)
      {
        identifier: label,
        query: config['query'] || name,
        label: label,
        count: info['doc_count']
      }
    end
  end
end
