class RegionPresenter
  def initialize region
    @region = region
    @countries = Country.joins(:region).where(region_id: @region.id)
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

  private

  def region
    @region
  end

  def overseas_territories_url
    overseas_territories = region.countries.map(&:iso_3).join(',')
    "search?q=#{overseas_territories}&type=country"
  end

  def global_statistic
    @global_statistic ||= Region.where(iso: 'GL').first.try(:regional_statistic)
  end
end
