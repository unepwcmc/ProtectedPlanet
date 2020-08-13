class Search::FullSerializer < Search::BaseSerializer
  DEFAULT_RESULT = {
    title: '',
    url: '',
    summary: '',
    image: ''
  }.freeze

  DEFAULT_OBJ = {
    search_term: '',
    current_page: 1,
    page_items_start: 1,
    page_items_end: 1,
    total_items: 0,
    results: [DEFAULT_RESULT]
  }.freeze

  def serialize
    return DEFAULT_OBJ.to_json unless @search

    all_objects = @results.objects.values.compact.flatten
    per_page = @options[:per_page].to_i
    DEFAULT_OBJ.merge(
      {
        search_term: @search_term,
        # TODO get page from params
        current_page: @page,
        page_items_start: @search.page_items_start(page: @page, per_page: per_page, for_display: true),
        page_items_end: @search.page_items_end(page: @page, per_page: per_page, for_display: true),
        total_items: @results.count || 0,
        # TODO get page from params
        results: all_objects.map do |record|
          {
            title: strip_html(record.respond_to?(:label) ? record.label : record.name),
            url: url(record),
            summary: strip_html(record.respond_to?(:summary) ? record.summary : record.name),
            image: image(record)
          }
        end
      }
    ).to_json
  end
end
