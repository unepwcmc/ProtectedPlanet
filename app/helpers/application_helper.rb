module ApplicationHelper
  include BemHelper

  COVER_HELPERS = {
    ProtectedArea => :protected_area_cover,
    Country => :country_cover,
    Region => :region_cover
  }

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

  def cover item
    send COVER_HELPERS[item.class], item
  end

  def protected_area_cover protected_area
    version = Rails.application.secrets.mapbox[:version]
    image_params = {id: protected_area.wdpa_id, type: "protected_area", version: version}

    image_tag(
      "search-placeholder-country.png",
      alt: protected_area.name,
      data: {async: tiles_path(image_params)},
      class: 'image' #TODO find a way to add classes via parameters
    )
  end

  def country_cover country
    version = Rails.application.secrets.mapbox[:version]
    image_params = {id: country.iso, type: "country", version: version}

    image_tag(
      "search-placeholder-country.png",
      alt: country.name,
      data: {async: tiles_path(image_params)},
    )
  end

  def region_cover region
    image_tag("search-placeholder-region.png", alt: region.name)
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

  def create_sharing_email_link
    title = url_encode('Share ' + page_title + ' via Email')
    url = encoded_page_url
    subject = url_encode("")
    body = url_encode("") + url
    href = 'mailto:?subject=' + subject + '&body=' + body

    link_to '', href, title: title, class: 'social__icon--email', target: '_self'
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

  def get_nav_primary
    def map_page(slug, map_children = false)
      cms_page = Comfy::Cms::Page.find_by_slug(slug)

      mapped_page = { 
        "id": cms_page.slug,
        "label": cms_page.label, 
        "url": root_path + '/c' + cms_page.full_path,
      }

      if map_children
        mapped_page["children"] = cms_page.children.published.map{ |page| {
            "id": page.slug,
            "label": page.label, 
            "url": root_path + '/c' + page.full_path,
          }
        }
      end

      return mapped_page
    end

    return [ 
      map_page('about'),
      map_page('news-and-stories'),
      map_page('resources'),
      map_page('thematical-areas', true),
    ].to_json
  end

  def link_to_page? card 
    !card[:pdf].present? && !card[:external_link].present?
  end

  def get_agile_config_themes
    {
      navButtons: true,
      infinite: false,
      responsive: [
      {
          breakpoint: 628,
          settings: {
            dots: false,
            slidesToShow: 1,
          }
        },
        {
          breakpoint: 768,
          settings: {
            dots: false,
            slidesToShow: 1,
          }
        },
        {
          breakpoint: 1024,
          settings: {
            dots: false,
            slidesToShow: 2
          }
        }
      ]
    }.to_json
  end
end
