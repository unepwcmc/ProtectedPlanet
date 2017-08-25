class CountryPresenter
  def initialize country
    @country = country
  end

  def marine_statistics
    statistic = StatisticPresenter.new(country)
    {
      name: country.name,
      totalMarineArea: statistic.marine_area,
      totalOverseasTerritories: country.children.count,
      overseasTerritoriesURL: overseas_territories_url,
      national: statistic.pa_marine_area,
      nationalPercentage: statistic.percentage_pa_marine_cover,
      overseas: statistic.overseas_total_protected_marine_area,
      overseasPercentage: statistic.overseas_percentage
    }
  end

  private

  def country
    @country
  end

  def overseas_territories_url
    overseas_territories = country.children.map(&:iso_3).join(',')
    "search?q=#{overseas_territories}&type=country"
  end
end
