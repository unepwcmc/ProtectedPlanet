class Search::BaseSerializer
  include Routeable

  def initialize(search, opts={})
    unless search.is_a?(Search)
      raise ArgumentError, 'Results argument must be of type Search'
    end
    @search = search
    @results = search.results
    @search_term = search.search_term
    @options = opts
    @page = @search.current_page
  end

  def serialize
    raise NotImplementedError
  end

  private

  def paginate(items)
    size = @search.options[:size] || 1
    page = @search.options[:page] || 1
    offset = size * (page - 1)
    last_item = size * page - 1

    items && items[offset..last_item].presence || []
  end

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
      obj.image
    else
      'placeholder_image' #TODO
    end
  end
end
