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

  def cover item
    send COVER_HELPERS[item.class], item
  end

  def protected_area_cover protected_area
    image_tag(
      AssetGenerator.link_to(protected_area.wdpa_id),
      alt: protected_area.name
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
end
