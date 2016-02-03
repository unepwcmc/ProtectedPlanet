module ApplicationHelper
  include BemHelper

  COVER_HELPERS = {
    ProtectedArea => :protected_area_cover,
    Country => :country_cover,
    Region => :region_cover,
    SavedSearch => :saved_search_cover
  }

  def commaify number
    number_with_delimiter(number, delimeter: ',')
  end

  def spaceify number
    number_with_delimiter(number, delimeter: ' ')
  end

  def cover item
    send COVER_HELPERS[item.class], item
  end

  def protected_area_cover protected_area
    version = Rails.application.secrets.mapbox['version']
    image_params = {id: protected_area.wdpa_id, version: version}

    image_tag(
      "search-placeholder-country.png",
      "alt" => protected_area.name,
      "data-async" => tiles_path(image_params),
    )
  end

  def country_cover country
    image_tag("search-placeholder-country.png", alt: country.name)
  end

  def region_cover region
    image_tag("search-placeholder-region.png", alt: region.name)
  end

  def saved_search_cover saved_search
    image_tag("projects-saved-searches.png", alt: saved_search.name)
  end

  def page_title base_title
    custom_title = content_for(:page_title)

    if custom_title
      "#{custom_title} | #{base_title}".html_safe
    else
      base_title
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

  DOWNLOAD_TYPES = {
    csv: {
      content: '.CSV',
      attrs: {'data-type' => 'csv', 'class' => 'u-bold tooltip__element link-with-icon'}
    },
    kml: {
      content: '.KML',
      attrs: {'data-type' => 'kml', 'class' => 'u-bold tooltip__element link-with-icon'}
    },
    shp: {
      content: '.SHP',
      attrs: {'data-type' => 'shapefile', 'class' => 'u-bold tooltip__element link-with-icon'}
    },
    gdb: {
      content: 'File Geodatabase',
      attrs: {'href' => Rails.application.secrets.wdpa_current_release_url, 'class' => 'u-bold tooltip__element link-with-icon'}
    },
    esri: {
      content: 'ESRI Web Service',
      attrs: {'href' => Rails.application.secrets.esri_web_service_url, 'class' => 'u-bold tooltip__element link-with-icon'}
    }
  }

  def download_dropdown item_id, download_type, types
    download_dropdown_attrs = {
      'data-item-id' => item_id,
      'data-download-type' => download_type,
      'class' => 'js-target tooltip download-type-dropdown'
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
end
