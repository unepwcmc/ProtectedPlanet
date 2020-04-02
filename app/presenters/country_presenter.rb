class CountryPresenter
  def initialize country
    @country = country
    @statistic = StatisticPresenter.new(country)
    @designations_presenter = DesignationsPresenter.new(country)
  end

  def designations
    @designations_presenter.designations
  end

  def marine_stats
    {
      pame_km2: statistic.pame_statistic.pame_pa_marine_area,
      pame_percentage: statistic.pame_statistic.pame_percentage_pa_marine_cover.round(2),
      protected_km2: statistic.pa_marine_area.round(0),
      protected_percentage: statistic.percentage_pa_marine_cover.round(2),
      total_km2: statistic.marine_area.round(0)
    }
  end

  def terrestrial_stats
    {
      pame_km2: statistic.pame_statistic.pame_pa_land_area,
      pame_percentage: statistic.pame_statistic.pame_percentage_pa_land_cover.round(2),
      protected_km2: statistic.pa_land_area.round(0),
      protected_percentage: statistic.percentage_pa_land_cover.round(2),
      total_km2: statistic.land_area.round(0)
    }
  end

  def marine_page_statistics
    {
      title: country.name,
      iso: country.iso, ## not needed on frontend
      totalMarineArea: statistic.total_marine_area.round,
      totalOverseasTerritories: country.children.count,
      overseasTerritoriesURL: overseas_territories_url,
      flag: '', ##TODO FERDI
      nationalKm: statistic.pa_marine_area.round,
      nationalPercentage: statistic.percentage_pa_marine_cover.round(2),
      overseasKm: statistic.overseas_total_protected_marine_area.round, ##check how this is being calculated
      overseasPercentage: statistic.overseas_percentage.round(2) ##check how this is being calculated - discuss
    }
  end

  def total_points_percentage
    statistic.geometry_ratio[:points]
  end

  def total_polygons_percentage
    statistic.geometry_ratio[:polygons]
  end

  private

  def country
    @country
  end

  def statistic
    @statistic
  end

  def overseas_territories_url
    overseas_territories = country.children.map(&:iso_3).join(',')
    "search?q=#{overseas_territories}&type=country"
  end
end
