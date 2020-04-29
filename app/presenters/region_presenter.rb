class RegionPresenter
  def initialize region
    @region = region
    @countries = @region.countries
    @statistics = @countries.map(&:statistic).compact
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
    (pa_land_area / land_area * 100).round(2)
  end

  def pa_land_area
    @statistics.map(&:pa_land_area).compact.reduce(:+)
  end

  def land_area
    @statistics.map(&:land_area).compact.reduce(:+)
  end

  def percentage_pa_marine_cover
    (pa_marine_area / marine_area * 100).round(2)
  end

  def pa_marine_area
    @statistics.map(&:pa_marine_area).compact.reduce(:+)
  end

  def marine_area
    @statistics.map(&:marine_area).compact.reduce(:+)
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
