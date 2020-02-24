class Search::FullSerializer < Search::BaseSerializer
  def serialize
    {
      search_term: @search_term,
      categories: [
        { id: 0, title: 'All' }, # Pull id from CMS
        { id: 0, title: 'News & Stories' }, # Pull id and title from CMS
        { id: 0, title: 'Resources' } # Pull id and title from CMS
      ],
      # TODO get page from params
      current_page: 1,
      page_items_start: @results.page_items_start(page: 1, for_display: true),
      page_items_end: @results.page_items_end(page: 1, for_display: true),
      total_items: @results.count , # Total items for selected category
      # TODO get page from params
      results: @results.paginate(page: 1).map do |record|
        {
          title: record.respond_to?(:title) ? record.title : record.name,
          url: 'url',
          summary: record.respond_to?(:content) ? record.content : record.name,
          image: 'image url'
        }
      end
    }.to_json
  end
end
