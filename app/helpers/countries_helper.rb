module CountriesHelper
  def is_malaysia?
    @country && @country.iso_3 == "MYS"
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
    else
      filters.merge!(iucn_category: ["#{category['iucn_category_name']}"]) 
      title_variable = category['iucn_category_name']
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

  def malaysia_documents
    [
      {
        url: 'https://wdpa.s3.amazonaws.com/Country_informations/MYS/COMMUNICATION%20PLAN%202012-2017.pdf',
        name: 'Department of Marine Park Malaysia CP'
      },
      {
        url: 'https://wdpa.s3.amazonaws.com/Country_informations/MYS/TOTAL%20ECONOMIC%20VALUE%20OF%20MARINE%20BIODIVERSITY.pdf',
        name: 'Malaysia Marine Parks Biodiversity'
      }
    ]
  end
end
