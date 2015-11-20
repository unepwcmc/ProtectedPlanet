module ApplicationHelper
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

  DOWNLOAD_TYPES = {
    csv: {
      content: 'CSV',
      attrs: {'data-type' => 'csv', 'class' => 'btn'}
    },
    kml: {
      content: 'KML',
      attrs: {'data-type' => 'kml', 'class' => 'btn'}
    },
    shp: {
      content: 'SHP',
      attrs: {'data-type' => 'shapefile', 'class' => 'btn'}
    },
    esri: {
      content: 'ESRI Web Service',
      attrs: {'href' => Rails.application.secrets.esri_web_service_url, 'class' => 'btn'}
    },
    gdb: {
      content: 'File Geodatabase',
      attrs: {'href' => Rails.application.secrets.wdpa_current_release_url, 'class' => 'btn'}
    }
  }

  def download_dropdown item_id, download_type, types
    download_dropdown_attrs = {
      'data-item-id' => item_id,
      'data-download-type' => download_type,
      'class' => 'download-type-dropdown'
    }

    content_tag :ul, download_dropdown_attrs do
      types.map do |type|
        content_tag :li do
          content_tag :a, DOWNLOAD_TYPES[type][:content], DOWNLOAD_TYPES[type][:attrs]
        end
      end.join.html_safe
    end
  end
end
