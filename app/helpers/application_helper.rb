# coding: utf-8
module ApplicationHelper
  include BemHelper

  COVER_HELPERS = {
    ProtectedArea => :protected_area_cover,
    Country => :country_cover,
    Region => :region_cover
  }.freeze

  PLACEHOLDERS = {
    ProtectedArea => "search-placeholder-country.png",
    Country => "search-placeholder-country.png",
    Region => "search-placeholder-region.png"
  }.freeze

  def get_square_side area
    Math.sqrt(area/100) * 100
  end

  def commaify number
    number_with_delimiter(number, delimeter: ',')
  end

  def spaceify number
    number_with_delimiter(number, delimeter: ' ')
  end

  def yml_key
    case controller_name
    when 'target_dashboard'
      'thematic_area.target_11_dashboard'
    else
      nil
    end
  end

  def active_nav_item?(current_path)
    request.fullpath == current_path
  end

  def cover item
    send COVER_HELPERS[item.class], item
  end

  def cover_placeholder klass
    PLACEHOLDERS[klass]
  end

  def cover_data(image_params, item_class)
    placeholder = cover_placeholder(item_class)
    {
      'data-src': tiles_path(image_params),
      'data-error': image_path(placeholder),
      'data-loading': image_path(placeholder),
    }
  end

  def protected_area_cover protected_area
    version = Rails.application.secrets.mapbox[:version]
    image_params = {id: protected_area.wdpa_id, type: "protected_area", version: version}
    data = cover_data(image_params, protected_area.class)

    image_tag(
      cover_placeholder(protected_area.class),
      {
        alt: protected_area.name,
        class: 'image' #TODO find a way to add classes via parameters
      }.merge(data)
    )
  end

  def country_cover country
    version = Rails.application.secrets.mapbox[:version]
    image_params = {id: country.iso, type: "country", version: version}
    data = cover_data(image_params, country.class)

    image_tag(
      cover_placeholder(country.class),
      {alt: country.name}.merge(data)
    )
  end

  def region_cover region
    image_tag(
      cover_placeholder(region.class),
      alt: region.name
    )
  end

  def site_title
    'Protected Planet'
  end

  def site_description
    "Discover the world's protected areas"
  end

  def page_title(here= false)
    custom_title = content_for(:page_title)

    if custom_title
      "#{custom_title} | #{site_title}".html_safe
    else
      site_title
    end
  end

  def url_encode(text)
    ERB::Util.url_encode(text)
  end

  def encoded_page_url
    url_encode(request.original_url)
  end

  def social_image
    if content_for?(:social_image)
      content_for(:social_image)
    elsif yml_key.present? && I18n.exists?("#{yml_key}.social_image")
      t("#{yml_key}.social_image")
    else
      URI.join(root_url, image_path('social.png'))
    end
  end

  def social_image_alt
    if content_for?(:social_image_alt)
      content_for(:social_image_alt)
    elsif yml_key.present? && I18n.exists?("#{yml_key}.social_image_alt")
      t("#{yml_key}.social_image_alt")
    else
      "Screenshot of the Protected Planet website which shows the menu bar and a map of the world that has protected areas highlighted in green."
    end
  end

  DEFAULT_SEO_DESC = """
    Protected Planet is the online interface for the
    World Database on Protected Areas (WDPA), and the most comprehensive
    global database on terrestrial and marine protected areas.
  """

  def seo_description
    if content_for?(:seo)
      content_for(:seo)
    else
      DEFAULT_SEO_DESC
    end
  end

  def twitter_card
    if content_for?(:twitter_card)
      content_for(:twitter_card)
    elsif yml_key.present? && I18n.exists?("#{yml_key}.social_twitter_card")
      t("#{yml_key}.social_twitter_card")
    else
      "summary"
    end
  end

  def social_title
    if content_for?(:social_title)
      sanitize content_for(:social_title)
    elsif yml_key.present? && I18n.exists?("#{yml_key}.title")
      t("#{yml_key}.title")
    else
      page_title 'Protected Planet'
    end
  end

  def social_description
    if content_for?(:social_description)
      sanitize content_for(:social_description)
    elsif yml_key.present? && I18n.exists?("#{yml_key}.social_description")
      t("#{yml_key}.social_description")
    else
      seo_description
    end
  end

  def create_sharing_facebook_link
    title = url_encode('Share ' + page_title + ' on Facebook')
    url = encoded_page_url
    href = 'https://facebook.com/sharer/sharer.php?u=' + url

    link_to '', href, title: title, class: 'social__icon--facebook', target: '_blank'
  end

  def create_sharing_twitter_link
    title = url_encode('Share ' + page_title + ' on Twitter')
    text = url_encode('Read about a year of impact in @unepwcmc’s 2018/19 Annual Review')
    url = encoded_page_url
    href = 'https://twitter.com/intent/tweet/?text=' + text + '&url=' + url

    link_to '', href, title: title, class: 'social__icon--twitter', target: '_blank'
  end

  def create_sharing_linkedin_link
    title = url_encode('Share ' + page_title + ' on LinkedIn')
    url = encoded_page_url
    href = 'https://www.linkedin.com/shareArticle?url=' + url

    link_to '', href, title: title, class: 'social__icon--linkedin', target: '_blank'
  end

  DOWNLOAD_TYPES = {
    csv: {
      content: '.CSV',
      attrs: {'data-type' => 'csv', 'class' => 'u-bold tooltip-old__element link-with-icon'}
    },
    shp: {
      content: '.SHP',
      attrs: {'data-type' => 'shapefile', 'class' => 'u-bold tooltip-old__element link-with-icon'}
    },
    gdb: {
      content: 'File Geodatabase',
      attrs: {'href' => Rails.application.secrets.wdpa_current_release_url, 'class' => 'u-bold tooltip-old__element link-with-icon'}
    },
    esri: {
      content: 'ESRI Web Service',
      attrs: {'href' => Rails.application.secrets.esri_web_service_url, 'class' => 'u-bold tooltip-old__element link-with-icon'}
    },
    pdf: {
      content: '.PDF',
      attrs: {'href' => '/MPA_Map.pdf', 'class' => 'u-bold tooltip-old__element link-with-icon', target: '_blank'}
    }
  }

  def download_dropdown item_id, download_type, types
    download_dropdown_attrs = {
      'data-item-id' => item_id,
      'data-download-type' => download_type,
      'class' => 'js-target tooltip-old download-type-dropdown'
    }

    content_tag :div, download_dropdown_attrs do
      types.map do |type|
        content_tag :a, DOWNLOAD_TYPES[type][:attrs] do
          concat content_tag(:i, "", {class: "link-with-icon__icon fa fa-download"})
          concat DOWNLOAD_TYPES[type][:content]
        end
      end.join.html_safe
    end
  end

  def is_regional_page controller_name
    controller_name == 'region'
  end

  def get_cms_url path
    root_path + path
  end

  def get_nav_primary
    [
      map_page('about'),
      map_page('news-and-stories'),
      map_page('resources'),
      map_page('thematical-areas', true),
    ].to_json
  end

  # def link_to_page? card
  #   !card[:pdf].present? && !card[:external_link].present?
  # end

  def get_resource_cards(all=false)
    presenter = ResourcesPresenter.new(@cms_site, all)
    _resources = presenter.resources

    _resources[:url] = get_cms_url(_resources[:url])
    _resources[:cards].map! do |c|
      page = c[:page]
      file = cms_fragment_render(:file, page)
      link = cms_fragment_render(:link, page)
      url = file.present? || link.present? ? nil : get_cms_url(page.full_path)

      c.merge(
        published_date: cms_fragment_render(:published_date, page),
        url: url,
        summary: cms_fragment_render(:summary, page),
        file: file,
        link: link,
        link_title: cms_fragment_render(:link_title, page)
      )
    end

    @items = _resources
  end

  def get_news_items all = false
    news_page = @cms_site.pages.find_by_slug('news-and-stories')
    published_pages = news_page.children.published
    sorted_cards = published_pages.sort_by { |c| c.fragments.where(identifier: 'published_date').first.datetime }.reverse

    @items = {
      "title": news_page.label,
      "url": all ? false : get_cms_url(news_page.full_path),
      "cards": all ? sorted_cards : sorted_cards.first(2)
    }
  end

  def get_thematical_areas
    @items = ThematicalAreasPresenter.new(@cms_site).thematical_areas
  end

  def get_footer_links
    @links = {}
    @links["links1"] = make_footer_links(['resources', 'oecms', 'wdpa'])
    @links["links2"] = make_footer_links(['about', 'legal'])
  end

  def get_local_classes local_assigns
    (local_assigns.has_key? :classes) ? local_assigns[:classes] : ''
  end

  private

  def make_footer_links slug_array
    slug_array.map do |slug|
      page = @cms_site.pages.find_by_slug(slug)

      {
        "title": page.label,
        "url": get_cms_url(page.full_path)
      }
    end
  end

  def map_page(slug, map_children = false)
    cms_page = Comfy::Cms::Page.find_by_slug(slug)

    mapped_page = {
      "id": cms_page.slug,
      "label": cms_page.label,
      "url": get_cms_url(cms_page.full_path),
      "is_current_page": active_nav_item?(get_cms_url cms_page.full_path)
    }

    if map_children
      mapped_page["children"] = cms_page.children.published.map do |page|
        {
          "id": page.slug,
          "label": page.label,
          "url": get_cms_url(page.full_path),
          "is_current_page": active_nav_item?(get_cms_url page.full_path)
        }
      end
    end

    mapped_page
  end
end
