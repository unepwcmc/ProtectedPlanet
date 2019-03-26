module CountriesHelper
  def is_malaysia?
    @country && @country.iso_3 == "MYS"
  end

  def is_japan?
    @country && @country.iso_3 == "JPN"
  end

  def has_restricted_sites?
    restricted_iso3 = ["RUS", "EST", "CHN", "GBR"]
    
    return restricted_iso3.include? @country.iso_3
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
