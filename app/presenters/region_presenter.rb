class RegionPresenter
  def initialize region
    @region = region
    @countries = @region.countries
    @statistics = @countries.map(&:statistic)
  end

  def geometry_ratio
    polygons_count = 0
    points_count = 0
    total = 0

    @countries.each do |country|
      polygons_count += country.statistic.polygons_count || 0
      points_count += country.statistic.points_count || 0
      total += (country.statistic.polygons_count || 0) + (country.statistic.points_count || 0)
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

  def sources_per_jurisdiction
    sources_per_jurisdiction_hash = {
      international: 0,
      national: 0,
      regional: 0
    }

    @countries.each do |country|
      country.sources_per_jurisdiction.each do |source_per_jurisdiction|
        sources_per_jurisdiction_hash[source_per_jurisdiction["name"].downcase.to_sym] += source_per_jurisdiction["count"].to_i || 0
      end
    end
    sources_per_jurisdiction_hash
  end

  def protected_areas_per_iucn_category
    region_data = Hash.new { |hash, key| hash[key] = Hash.new }
    processed_data = []
    total_region_count = []

    region.countries.each do |country|
      country.protected_areas_per_iucn_category.each do |protected_area|
        region_pa_category = region_data[protected_area["iucn_category_name"]]
        region_pa_category[:count] ||= 0
        region_pa_category[:count] += protected_area["count"].to_i
        total_region_count << protected_area["count"].to_i
        region_pa_category[:percentage] ||= 0
        region_pa_category[:percentage] += protected_area["percentage"].to_f
      end
    end

    processed_data = region_data.map{ |key,value| {
          iucn_category_name: key,
          total_count: value[:count],
          total_percentage: 100 * value[:count] / total_region_count.reduce(0, :+)
        }
    }

    processed_data
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
