class Search::Results
  def initialize query_results
    @query_results = query_results
    @type_index_map = {
      Search::REGION_INDEX => "Region",
      Search::COUNTRY_INDEX => "Country",
      Search::PA_INDEX => "ProtectedArea",
      Search::CMS_INDEX => "Comfy::Cms::SearchablePage"
    }
  end

  def pluck key
    @values ||= {}
    @values[key] ||= matches.map { |result| result['_source'][key] }
  end

  INCLUDES = {
    "protected_area" => [:designation, {countries_for_index: :region_for_index}]
  }

  def objects
    return @objects if @objects
    by_type_and_id = matches.group_by { |match|
      match["_index"]
    }.each_with_object({}) { |(index, objs), final|
      ids = objs.map { |obj| obj["_source"]["id"] }
      type = @type_index_map[index]
      records = type == Search::CMS_INDEX ? type.classify.constantize.without_geometry : type.classify.constantize
      final[type] = records.
        where(id: ids).
        includes(INCLUDES[type.underscore]).
        group_by(&:id)
    }
    @objects ||= {}
    @type_index_map.each do |key, _type|
      objs = by_type_and_id[_type]
      @objects[_type] = objs && objs.values.flatten
    end
    @objects
  end

  def protected_areas
    @protected_areas ||= objects[@type_index_map[Search::PA_INDEX]]
  end

  def countries
    @countries ||= objects[@type_index_map[Search::COUNTRY_INDEX]]
  end

  def regions
    @regions ||= objects[@type_index_map[Search::REGION_INDEX]]

    # Remove Global from the list of regions on the pre-filtered search results page
    @regions.filter { |region| region.name != 'Global' }
  end

  def cms_pages
    @cms_pages ||= objects[@type_index_map[Search::CMS_INDEX]]
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
    @query_results['hits']['total']['value']
  end

  private

  def method_missing meth, *args, &blk
    objects.send(meth, *args, &blk)
  end

  def respond_to? method, include_all=false
    super(method, include_all) || objects.respond_to?(method, include_all)
  end
end
