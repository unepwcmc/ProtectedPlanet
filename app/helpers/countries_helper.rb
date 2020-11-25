module CountriesHelper
  def has_documents local_assigns
    (local_assigns.has_key? :documents) && (local_assigns[:documents].length > 0)
  end

  def has_related_countries?
    @country.children.any? || @country.parent.present?
  end

  def chart_link(category)
    return unless @country || @region

    geo_entity = @country || @region
    geo_type = geo_entity.class.to_s.downcase 
    name = geo_entity.name
    title_variable = ""
    filters = { location: { type: geo_type, options: [name] } }

    # Looking for the name of the designation, iucn category etc.
    category_name = category.keys.find { |key| key.match?(/(_name)$/) }

    if category_name
      title_variable = "View the #{category[category_name]} sites for #{name}"
      filters.merge!("#{category_name}": [category[category_name]]) 
    end

    # This hash is used to populate the view links of the various charts for the
    # region and country pages
    { 
      link: search_areas_path(
        geo_type: 'site', 
        filters: filters     
      ),
      title: title_variable
    }
  end

  def has_restricted_sites?
    restricted_iso3 = ["RUS", "EST", "CHN", "GBR"]
    
    @country && (restricted_iso3.include? @country.iso_3)
  end
end
