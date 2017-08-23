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
      national: statistic.pa_marine_area,
      nationalPercentage: statistic.national_percentage,
      overseas: statistic.overseas_total_area,
      overseasPercentage: statistic.overseas_percentage
    }
  end

  private

  def country
    @country
  end
end
