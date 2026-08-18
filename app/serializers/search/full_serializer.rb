class Search::FullSerializer < Search::BaseSerializer
  DEFAULT_RESULT = {
    title: '',
    url: '',
    summary: '',
    image: ''
  }.freeze

  DEFAULT_OBJ = {
    searchTerm: '',
    currentPage: 1,
    pageItemsStart: 1,
    pageItemsEnd: 1,
    totalItems: 0,
    results: [DEFAULT_RESULT]
  }.freeze

  def serialize
    return DEFAULT_OBJ unless @search

    all_objects = @results.objects.values.compact.flatten
    per_page = @options[:per_page].to_i
    DEFAULT_OBJ.merge(
      {
        searchTerm: @search_term,
        # TODO get page from params
        currentPage: @page,
        pageItemsStart: @search.page_items_start(page: @page, per_page: per_page, for_display: true),
        pageItemsEnd: @search.page_items_end(page: @page, per_page: per_page, for_display: true),
        totalItems: @results.count || 0,
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
    )
  end
end
