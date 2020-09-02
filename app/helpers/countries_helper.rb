module CountriesHelper
  def is_malaysia?
    @country && @country.iso_3 == "MYS"
  end

  def has_related_countries?
    @country.children.any? || @country.parent.present?
  end

  def iucn_link(category)
    type = @country ? 'country' : 'region'
    name = @country ? @country.name : @region.name
    
    # This hash is used to populate the 'View All' links of the IUCN categories chart for the show pages
    # depending on whether the page relates to a country or region.
    { 
      link: search_areas_path(
      geo_type: 'site', 
      filters: { 
        iucn_category: ["#{category['iucn_category_name']}"],
        location: { type: type, options: [name] }
        }          
      ),
      title: "View the #{category['iucn_category_name']} sites for #{name}"
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
