class Search::Results
  def initialize query_results
    @query_results = query_results
  end

  def pluck key
    @values ||= {}
    @values[key] ||= matches.map { |result| result['_source'][key] }
  end

  INCLUDES = {
    "protected_area" => [:designation, {countries: :region}]
  }

  def objects
    by_type_and_id = matches.group_by { |match|
      match["_type"]
    }.each_with_object({}) { |(type, objs), final|
      ids = objs.map { |obj| obj["_source"]["id"] }
      final[type] = type.classify.constantize.
        without_geometry.
        where(id: ids).
        includes(INCLUDES[type]).
        group_by(&:id)
    }

    @objects ||= matches.map do |result|
      id = result["_source"]["id"]
      type = result["_type"]

      by_type_and_id[type][id].first
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
