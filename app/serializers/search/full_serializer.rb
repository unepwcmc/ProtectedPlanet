class Search::FullSerializer < Search::BaseSerializer
  def initialize(search, opts={})
    super(search, opts)
    @page = @options[:page] || 1
  end

  def serialize
    {
      search_term: @search_term,
      # TODO get page from params
      current_page: @page,
      page_items_start: @results.page_items_start(page: @page, for_display: true),
      page_items_end: @results.page_items_end(page: @page, for_display: true),
      total_items: @results.objects.count || 0,
      # TODO get page from params
      results: @results.paginate(page: @page).map do |record|
        {
          title: record.respond_to?(:title) ? record.label : record.name,
          url: 'url',
          summary: record.respond_to?(:content) ? record.content : record.name,
          image: 'image url'
        }
      end
    }.to_json
  end
end
