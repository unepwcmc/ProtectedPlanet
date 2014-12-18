class Search::Results
  def initialize query_results
    @query_results = query_results
  end

  def pluck key
    @values ||= {}
    @values[key] ||= matches.map { |result| result['_source'][key] }
  end

  def objects
    @objects ||= matches.map do |result|
      model_class = result['_type'].classify.constantize
      model_class.without_geometry.find(result['_source']['id'])
    end
  end

  def raw
    @raw ||= matches.map { |result| result['_source'] }
  end

  def matches
    @query_results['hits']['hits']
  end

  def with_coords
    matches.map { |result| result['_source'].slice('id', 'wdpa_id', 'name', 'coordinates') }
  end

  def count
    @query_results['hits']['total']
  end

  private

  def method_missing meth, *args, &blk
    objects.send(meth, *args, &blk)
  end

  def respond_to? method, include_all=false
    super(method, include_all) || objects.respond_to?(method, include_all)
  end
end
