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
    total: 0,
    totalPages: 1,
    results: [DEFAULT_RESULT]
  }.freeze

  def serialize
    return DEFAULT_OBJ.to_json unless @search

    per_page = @options[:per_page].to_i
    DEFAULT_OBJ.merge(
      {
        total: total,
        totalPages: total_pages,
        results: sorted_pages.map do |record|
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

  OLDEST_DATE = DateTime.new(0).freeze
  def sorted_pages
    return [] if @results.cms_pages.blank?
    @results.cms_pages.sort_by do |p|
      p.fragments.find_by(identifier: 'published_date')
        .try(:datetime) || OLDEST_DATE
    end.reverse
  end

  def date(page)
    _date = cms_fragment_content(:published_date, page)
    _date.present? ? _date.strftime('%d %B %y') : _date
  end

  def file(page)
    attachments = page.fragments.where(identifier: 'file').first.try(:attachments)
    attachments.attachments.first.blob.service_url if attachments.present?
  end

  def link(page)
    cms_fragment_content(:link, page)
  end

  def link_title(page)
    cms_fragment_content(:link_title, page)
  end

  def total
    @total ||= @results.count || 0
  end

  DEFAULT_PAGE_SIZE = {
    resources: 9.0,
    news_and_stories: 6.0
  }.freeze
  def total_pages
    (total / default_page_size(cms_root_page.try(:slug))).ceil
  end

  def default_page_size(slug)
    DEFAULT_PAGE_SIZE[slug.underscore.to_sym] || 9.0
  end

  def cms_root_page
    _root_page_id = @search.options.dig(:filters, :ancestor)
    @cms_root_page ||= Comfy::Cms::Page.find_by(id: _root_page_id)
  end
end