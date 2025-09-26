module Search::Aggregators::Model
  def self.build name, raw_aggregations, config
    model = (config['class'] || name.classify).constantize
    raw_aggregations[name]['aggregation']['buckets'].map do |info|
      column_name = model.has_attribute?(:name) ? :name : :label
      label = select_attribute(model, column_name, info)
      {
        identifier: identifier(model, info) || label,
        query: config['query'] || name,
        label: label,
        count: info['doc_count']
      }
    end
  end

  private

  IDENTIFIERS = {
    'ProtectedArea' => 'site_id',
    'Country' => 'iso_3',
    'Region' => 'iso'
  }.freeze
  def self.identifier(model, info)
    _identifier = IDENTIFIERS[model.to_s] || 'id'
    select_attribute(model, _identifier, info)
  end

  def self.select_attribute(model, column_name, info)
    _record = model.select(column_name).find_by(id: info['key'])
    _record && _record.send(column_name)
  end
end