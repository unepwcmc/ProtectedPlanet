class RegionPresenter
  include ActionView::Helpers::NumberHelper

  def initialize(region)
    @region = region
    @countries = @region.countries
    @statistics = @countries.map(&:statistic).compact
    @designations_presenter = DesignationsPresenter.new(region)
  end

  def designations
    @designations_presenter.designations
  end

  def marine_stats
    {
      pame_km2: 'XXXXX', ##TODO FERDI - Not sure we have this kind of stat
      pame_percentage: 'XXXXX', ##TODO FERDI - Not sure we have this kind of stat
      protected_km2: pa_marine_area.round(0),
      protected_percentage: percentage_pa_marine_cover.round(2),
      total_km2: marine_area.round(0)
    }
  end

  def terrestrial_stats
    {
      pame_km2: 'XXXXX', ##TODO FERDI - Not sure we have this kind of stat
      pame_percentage: 'XXXXX', ##TODO FERDI - Not sure we have this kind of stat
      protected_km2: pa_land_area.round(0),
      protected_percentage: percentage_pa_land_cover.round(2),
      total_km2: land_area.round(0)
    }
  end

  def total_points_percentage
    geometry_ratio[:points]
  end

  def total_polygons_percentage
    geometry_ratio[:polygons]
  end

  def geometry_ratio
    polygons_count = 0
    points_count = 0
    total = 0

    @countries.each do |country|
      statistic = country.statistic
      polygons_count += (statistic && statistic.polygons_count) || 0
      points_count += (statistic && statistic.points_count) || 0
      total += polygons_count + points_count
    end
    {
      polygons: (((polygons_count/total.to_f)*100).round rescue 0),
      points:   (((points_count/total.to_f)*100).round   rescue 0),
    }
  end

  def percentage_pa_land_cover
    @statistics.map(&:percentage_pa_land_cover).compact.reduce(:+)/@countries.count
  end

  def pa_land_area
    @statistics.map(&:pa_land_area).compact.reduce(:+)
  end

  def land_area
    @statistics.map(&:land_area).compact.reduce(:+)
  end

  def percentage_pa_marine_cover
    @statistics.map(&:percentage_pa_marine_cover).compact.reduce(:+)/@countries.count
  end

  def pa_marine_area
    @statistics.map(&:pa_marine_area).compact.reduce(:+)
  end

  def marine_area
    @statistics.map(&:marine_area).compact.reduce(:+)
  end

  def top_marine_coverage_countries
    sorted_stats = @statistics.sort_by do |s|
      s.percentage_pa_marine_cover ? -s.percentage_pa_marine_cover : 0.0
    end.first(10)

    {
      regionTitle: region.name,
      countries: sorted_stats.map do |stat|
        {
          title: stat.country.name,
          percentage: stat.percentage_pa_marine_cover,
          km: number_with_delimiter(stat.pa_marine_area),
          iso3: stat.country.iso_3
        }
      end
    }
  end

  private

  def region
    @region
  end

  def overseas_territories_url
    overseas_territories = region.countries.map(&:iso_3).join(',')
    "search?q=#{overseas_territories}&type=country"
  end

end
