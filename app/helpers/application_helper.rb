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

  def cover item, opts={size: {x: 256, y: 128}}
    send(COVER_HELPERS[item.class], item, opts)
  end

  def protected_area_cover protected_area, opts
    image_tag(protected_area_cover_link(protected_area, opts), alt: protected_area.name)
  end

  def protected_area_cover_link protected_area, opts
    version = Rails.application.secrets.mapbox['version']
    image_params = {id: protected_area.id, version: version}.merge(opts)
    return tiles_path(image_params)
  end

  def country_cover country, opts
    image_tag("search-placeholder-country.png", alt: country.name)
  end

  def region_cover region, opts
    image_tag("search-placeholder-region.png", alt: region.name)
  end

  def saved_search_cover saved_search, opts
    image_tag("projects-saved-searches.png", alt: saved_search.name)
  end
end
