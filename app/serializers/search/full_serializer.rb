class Search::FullSerializer < Search::BaseSerializer
  include Routeable

  def serialize
    all_objects = @results.objects.values.compact.flatten
    {
      search_term: @search_term,
      # TODO get page from params
      current_page: @page,
      page_items_start: @search.page_items_start(page: @page, for_display: true),
      page_items_end: @search.page_items_end(page: @page, for_display: true),
      total_items: @results.count || 0,
      # TODO get page from params
      results: all_objects.map do |record|
        {
          title: strip_html(record.respond_to?(:label) ? record.label : record.name),
          url: url(record),
          summary: strip_html(record.respond_to?(:content) ? record.content : record.name),
          image: 'image url'
        }
      end
    }.to_json
  end

  private

  def strip_html(text)
    ActionView::Base.full_sanitizer.sanitize(text)
  end

  def url(obj)
    if obj.is_a?(Comfy::Cms::SearchablePage)
      path = obj.full_path
      path[0] == '/' ? path[1..-1] : path
    elsif obj.is_a?(ProtectedArea)
      protected_area_path(obj.wdpa_id)
    elsif obj.is_a?(Country)
      country_path(iso: obj.iso_3)
    else
      '#'
    end
  end
end
