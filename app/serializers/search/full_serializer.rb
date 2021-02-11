class Search::FullSerializer < Search::BaseSerializer
  include CmsHelper

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
    return DEFAULT_OBJ unless @search

    all_objects = sorted_pages
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
    )
  end

  private 

  OLDEST_DATE = DateTime.new(0).freeze

  def all_results
    @results.objects.values.compact.flatten
  end

  def sorted_pages
    unless @results.cms_pages.blank?
      return all_results.sort_by! do |p|
        find_date(p) || OLDEST_DATE
      end.reverse
    end
    
    all_results
  end

  def find_date(page)
    return unless page.is_a?(Comfy::Cms::SearchablePage)

    cms_fragment_content_datetime(:published_date, page)
  end
end
