class Search::CmsSerializer < Search::BaseSerializer
  include Comfy::CmsHelper

  def initialize(search, opts={})
    super(search, opts)
  end

  DEFAULT_RESULT = {
    date: nil,
    fileUrl: nil,
    linkTitle: nil,
    linkUrl: nil,
    title: '',
    url: '',
    summary: '',
    image: ''
  }.freeze

  DEFAULT_OBJ = {
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
        current_page: @page,
        page_items_start: @search.page_items_start(page: @page, per_page: per_page, for_display: true),
        page_items_end: @search.page_items_end(page: @page, per_page: per_page, for_display: true),
        total_items: @results.count || 0,
        results: all_objects.map do |record|
          {
            date: date(record),
            fileUrl: file(record),
            linkUrl: link(record),
            linktTile: link_title(record), 
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

  def date(page)
    _date = cms_fragment_content(:published_date, page)
    _date.present? ? _date.strftime('%d %B %y') : _date
  end

  def file(page)
    cms_fragment_render(:file, page)
  end

  def link(page)
    cms_fragment_render(:link, page)
  end

  def link_title(page)
    cms_fragment_render(:link_title, page)
  end
end