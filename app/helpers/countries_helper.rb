module CountriesHelper
  def has_documents local_assigns
    (local_assigns.has_key? :documents) && (local_assigns[:documents].length > 0)
  end

  def has_related_countries?
    @country.children.any? || @country.parent.present?
  end

  def chart_link(category)
    geo_type = @country ? 'country' : 'region'
    name = @country ? @country.name : @region.name
    title_variable = ""
    filters = { location: { type: geo_type, options: [name] } }

    if category.has_key?('governance_name')
      filters.merge!(governance: ["#{category['governance_name']}"]) 
      title_variable = category['governance_name']
    elsif category.has_key?('iucn_category_name')
      filters.merge!(iucn_category: ["#{category['iucn_category_name']}"]) 
      title_variable = category['iucn_category_name']
    else
      filters.merge!(designation: ["#{category['designation_name']}"]) 
      title_variable = category['designation_name']
    end
    
    # This hash is used to populate the view links of the torus charts for the show pages
    # depending on whether the chart relates to IUCN category or governance. 
    { 
      link: search_areas_path(
      geo_type: 'site', 
      filters: filters        
      ),
      title: "View the #{title_variable} sites for #{name}"
    }
  end

  def has_restricted_sites?
    restricted_iso3 = ["RUS", "EST", "CHN", "GBR"]
    
    @country && (restricted_iso3.include? @country.iso_3)
  end
end
