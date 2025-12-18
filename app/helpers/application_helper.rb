module ApplicationHelper
  include ActionView::Helpers::NumberHelper
  include BemHelper

  COVER_HELPERS = {
    ProtectedArea => :protected_area_cover,
    Country => :country_cover,
    Region => :region_cover
  }.freeze

  PLACEHOLDERS = {
    ProtectedArea => 'search-placeholder-country.png',
    Country => 'search-placeholder-country.png',
    Region => 'search-placeholder-region.png'
  }.freeze

  def get_square_side(area)
    Math.sqrt(area / 100) * 100
  end

  def commaify(number)
    number_with_delimiter(number, delimeter: ',')
  end

  def spaceify(number)
    number_with_delimiter(number, delimeter: ' ')
  end

  def yml_key
    case controller_name
    when 'target_dashboard'
      'thematic_area.target_11_dashboard'
    end
  end

  def active_nav_item?(current_path)
    request.fullpath == current_path
  end

  def cover(item)
    send COVER_HELPERS[item.class], item
  end

  def cover_placeholder(klass)
    PLACEHOLDERS[klass]
  end

  def tiles_path(params)
    Rails.application.routes.url_helpers.tiles_path(params)
  end

  def cover_data(image_params, item_class)
    placeholder = cover_placeholder(item_class)
    {
      'data-src': tiles_path(image_params),
      'data-error': image_path(placeholder),
      'data-loading': image_path(placeholder)
    }
  end

  def protected_area_cover(protected_area, with_tag: true)
    version = Rails.application.secrets.mapbox[:version]
    image_params = { id: protected_area.site_id, type: 'protected_area', version: version }
    data = cover_data(image_params, protected_area.class)

    return tiles_path(image_params) unless with_tag

    image_tag(
      cover_placeholder(protected_area.class),
      {
        alt: protected_area.name,
        class: 'image'
      }.merge(data)
    )
  end

  def country_cover(country, with_tag: true)
    version = Rails.application.secrets.mapbox[:version]
    image_params = { id: country.iso, type: 'country', version: version }
    data = cover_data(image_params, country.class)

    return tiles_path(image_params) unless with_tag

    image_tag(
      cover_placeholder(country.class),
      { alt: country.name }.merge(data)
    )
  end

  def region_cover(region, with_tag: true)
    version = Rails.application.secrets.mapbox[:version]
    image_params = { id: region.iso, type: 'region', version: version }
    return tiles_path(image_params) unless with_tag

    image_tag(
      cover_placeholder(region.class),
      alt: region.name
    )
  end

  def url_encode(text)
    ERB::Util.url_encode(text)
  end

  def is_regional_page(controller_name)
    controller_name == 'region'
  end

  def get_cms_url(path)
    root_path + path
  end

  def get_nav_primary
    [
      map_page('about'),
      map_page('news-and-stories'),
      map_page('resources'),
      map_page('monthly-release-news'),
      map_page('thematic-areas', true)
    ].compact.to_json
  end

  # def link_to_page? card
  #   !card[:pdf].present? && !card[:external_link].present?
  # end

  def get_resource_cards(all = false)
    presenter = ResourcesPresenter.new(@cms_site, all)
    _resources = presenter.resources

    _resources[:url] = get_cms_url(_resources[:url])
    _resources[:cards].map! do |c|
      page = c[:page]
      file = cms_fragment_render(:file, page)
      link = cms_fragment_render(:link, page)
      url = file.present? || link.present? ? nil : get_cms_url(page.full_path)

      c.merge(
        date: DateTime.parse(cms_fragment_render(:published_date, page)).strftime('%d %B %y'),
        url: url,
        summary: cms_fragment_render(:summary, page),
        fileUrl: file,
        linkUrl: link,
        linktTile: cms_fragment_render(:link_title, page)
      )
    end

    @items = _resources
  end

  def get_news_items(all = false)
    return (@items = { title: nil, url: false, cards: [] }) if @cms_site.nil?

    news_page = @cms_site.pages.find_by_slug('news-and-stories')
    return (@items = { title: nil, url: false, cards: [] }) if news_page.nil?

    published_pages = news_page.children.published
    sorted_cards = published_pages.sort_by do |c|
      c.fragments.where(identifier: 'published_date').first&.datetime || Time.at(0)
    end.reverse

    @items = {
      title: news_page.label,
      url: all ? false : get_cms_url(news_page.full_path),
      cards: all ? sorted_cards : sorted_cards.first(2)
    }
  end

  def get_thematic_areas
    @items = ThematicAreasPresenter.new(@cms_site).thematic_areas
  end

  def get_footer_links
    @links = {}
    @links['links1'] = make_footer_links(%w[resources oecms wdpa])
    @links['links2'] = make_footer_links(%w[about legal])
  end

  def get_local_classes(local_assigns)
    (local_assigns.has_key? :classes) ? local_assigns[:classes] : ''
  end

  private

  def make_footer_links(slug_array)
    slug_array.map do |slug|
      page = @cms_site.pages.find_by_slug(slug)
      next if page.nil?

      {
        title: if page.fragments.find_by(identifier: 'short_title')
                 cms_fragment_render(:short_title,
                   page)
               else
                 page.label
               end,
        url: get_cms_url(page.full_path)
      }
    end.compact
  end

  def get_config_carousel_themes
    {
      wrapAround: true
    }.to_json
  end

  def map_page(slug, map_children = false)
    cms_page = Comfy::Cms::Page.find_by_slug(slug)
    return nil if cms_page.nil?

    mapped_page = {
      id: cms_page.slug,
      label: cms_page.label,
      url: get_cms_url(cms_page.full_path),
      is_current_page: active_nav_item?(get_cms_url(cms_page.full_path))
    }

    if map_children
      mapped_page['children'] = cms_page.children.published.map do |page|
        {
          id: page.slug,
          label: page.label,
          url: get_cms_url(page.full_path),
          is_current_page: active_nav_item?(get_cms_url(page.full_path))
        }
      end
    end

    mapped_page
  end

  def active_banners
    @active_banners ||= Banner.active.order(updated_at: :desc).to_a
  end

  def banner_signature
    # Signature of current active banners set to support dismissing a group
    @banner_signature ||= Digest::SHA1.hexdigest(active_banners.map(&:id).join('-'))
  end

  def current_banner
    # For backward compatibility where only first is used
    active_banners.first
  end

  def banner_visible?
    return false if active_banners.empty?

    if active_banners.size == 1
      return false if cookies[:banner_closed] == active_banners.first.id.to_s

      return true
    end

    cookies[:banner_closed_sig] != banner_signature
  end
end
