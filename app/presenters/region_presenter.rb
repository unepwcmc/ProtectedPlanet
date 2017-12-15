class RegionPresenter
  def initialize region
    @region = region
    @countries = Country.where(region_id: @region.id)
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
    pa_land_area = 0
    total_pa_land_cover = 0

    Country.all.each do |country|
      pa_land_area += (country.statistic.pa_land_area || 0) if (country.region_id == @region.id)
      total_pa_land_cover += country.statistic.pa_land_area || 0
    end

    percentage = (pa_land_area / total_pa_land_cover) * 100
  end

  def pa_land_area
    pa_land_area = 0

    @countries.each do |country|
      pa_land_area += country.statistic.pa_land_area || 0
    end
    pa_land_area
  end

  def land_area
    land_area = 0

    @countries.each do |country|
      land_area += country.statistic.land_area || 0
    end
    land_area
  end

  def percentage_pa_marine_cover
    pa_marine_area = 0
    total_pa_marine_area = 0

    Country.all.each do |country|
      pa_marine_area += (country.statistic.pa_marine_area || 0) if (country.region_id == @region.id)
      total_pa_marine_area += country.statistic.pa_marine_area || 0
    end
    percentage = (pa_marine_area / total_pa_marine_area) * 100
  end

  def pa_marine_area
    pa_marine_area = 0

    @countries.each do |country|
      pa_marine_area += country.statistic.pa_marine_area || 0
    end
    pa_marine_area
  end

  def marine_area
    marine_area = 0

    @countries.each do |country|
      marine_area += country.statistic.marine_area || 0
    end
    marine_area
  end

  def sources_per_jurisdiction
    sources_per_jurisdiction_hash = {
      international: 0,
      national: 0
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

    region.countries.each do |country|
      country.protected_areas_per_iucn_category.each do |protected_area|
        region_data["#{protected_area['iucn_category_name']}"][:count] = Array.new if region_data["#{protected_area['iucn_category_name']}"][:count].nil?
        region_data["#{protected_area['iucn_category_name']}"][:count] << protected_area["count"].to_i
        region_data["#{protected_area['iucn_category_name']}"][:percentage] = Array.new if region_data["#{protected_area['iucn_category_name']}"][:percentage].nil?
        region_data["#{protected_area['iucn_category_name']}"][:percentage] << protected_area["percentage"].to_f
      end
    end

    processed_data = region_data.map{ |key,value| {
          iucn_category_name: key,
          total_count: value[:count].reduce(0, :+),
          total_percentage: value[:percentage].reduce(0, :+)
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
