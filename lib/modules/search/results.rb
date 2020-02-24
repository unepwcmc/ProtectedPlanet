class Search::Results
  def initialize query_results
    @query_results = query_results
    @type_index_map = {
      Search::COUNTRY_INDEX => "Country",
      Search::PA_INDEX => "ProtectedArea",
      Search::CMS_INDEX => "Comfy::Cms::Fragment"
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
    @objects ||= matches.map do |result|
      id = result["_source"]["id"]
      type = @type_index_map[result["_index"]]
      obj = by_type_and_id[type][id].first
      # TODO Improve the following
      obj = obj.is_a?(Comfy::Cms::Fragment) ? obj.record : obj
      obj.is_a?(Comfy::Cms::Translation) ? obj.page : obj
    end
  end

  PAGE = 1.freeze
  PER_PAGE = 8.freeze
  def paginate(page: PAGE, per_page: PER_PAGE)
    offset = page_items_start(page: page, per_page: per_page)
    limit = page_items_end(page: page, per_page: per_page)
    objects[offset..limit]
  end

  def page_items_start(page: PAGE, per_page: PER_PAGE, for_display: false)
    n = (page - 1) * per_page
    for_display ? n + 1 : n
  end

  def page_items_end(page: PAGE, per_page: PER_PAGE, for_display: false)
    n = page * per_page - 1
    if for_display
      n >= objects.count ? objects.count : n + 1
    else
      n
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
