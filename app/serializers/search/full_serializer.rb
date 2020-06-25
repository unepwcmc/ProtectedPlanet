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

  def image(obj)
    if obj.is_a?(ProtectedArea)
      ApplicationController.helpers.protected_area_cover(obj, with_tag: false)
    elsif obj.is_a?(Comfy::Cms::SearchablePage)
      'page_image' #TODO
    else
      'placeholder_image' #TODO
    end
  end
end
