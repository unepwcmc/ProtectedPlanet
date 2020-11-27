module CountriesHelper
  def has_documents local_assigns
    (local_assigns.has_key? :documents) && (local_assigns[:documents].length > 0)
  end

  def has_related_countries?
    @country.children.any? || @country.parent.present?
  end

  def chart_link(category)
    return unless geo_entity

    type, name, locale = search_path_vars(geo_entity)
    title_variable = ""
    filters = base_filters(type, name)

    # Looking for the name of the designation, iucn category etc.
    category_name = category.keys.find { |key| key.match?(/(_name)$/) }
    chart_category = category_name.gsub('_name', '')

    if category_name
      title_variable = "View the #{category[category_name]} sites for #{name}"
      filters = filters.deep_merge(filters: {"#{chart_category}": [category[category_name]]}) 
    end

    # This hash is used to populate the view links of the various charts for the
    # region and country pages
    { 
      link: search_areas_path(locale, filters),
      title: title_variable
    }
  end

  def has_restricted_sites?
    restricted_iso3 = ["RUS", "EST", "CHN", "GBR"]
    
    @country && (restricted_iso3.include? @country.iso_3)
  end

  def view_all_link(additional_filter_hash = nil)
    return unless geo_entity

    type, name, locale = search_path_vars(geo_entity)
    filters = base_filters(type, name)

    if additional_filter_hash.nil? || !additional_filter_hash.is_a?(Hash)
      search_areas_path(locale, filters)
    else
      combined_filters = filters.deep_merge(filters: additional_filter_hash)
      search_areas_path(locale, combined_filters)
    end
  end

  def geo_entity
    @country || @region || @geo_entity
  end

  def search_path_vars(geo_entity)
    [
      geo_entity.class.to_s.downcase,
      geo_entity.name,
      I18n.locale.to_s
    ]
  end

  def base_filters(type, name)
    { filters: { location: { type: type, options: [name] } } }
  end
end
