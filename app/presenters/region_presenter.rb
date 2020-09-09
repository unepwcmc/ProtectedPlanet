class RegionPresenter
  include ActionView::Helpers::NumberHelper

  def initialize(region)
    @region = region
    @countries = @region.countries
    @statistics = @countries.map(&:statistic).compact
    @designations_presenter = DesignationsPresenter.new(region)
  end

  def chart_point_poly
    [
      { 
        percentage: total_polygons_percentage, 
        theme: 'theme--primary', 
        title: "#{I18n.t('stats.polygons')} #{total_polygons_percentage}%" 
      },
      { 
        percentage: total_points_percentage, 
        theme: 'theme--primary-dark', 
        title: "#{I18n.t('stats.points')} #{total_points_percentage}%" 
      }
    ]
  end
  
  def designations
    @designations_presenter.designations
  end

  def marine_stats
    {
      pame_km2: nil, ##TODO FERDI - Not sure we have this kind of stat
      pame_percentage: nil, ##TODO FERDI - Not sure we have this kind of stat
      protected_km2: pa_marine_area.round(0),
      protected_percentage: percentage_pa_marine_cover.round(2),
      total_km2: marine_area.round(0)
    }
  end

  def terrestrial_stats
    {
      pame_km2: nil, ##TODO FERDI - Not sure we have this kind of stat
      pame_percentage: nil, ##TODO FERDI - Not sure we have this kind of stat
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
    
    @countries.each do |country|
      statistic = country.statistic
      polygons_count += (statistic && statistic.polygons_count) || 0
      points_count += (statistic && statistic.points_count) || 0
    end
    
    total = polygons_count + points_count
    
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

  def marine_coverage
    {
      title: region.name,
      percentage: percentage_pa_marine_cover,
      km: number_with_delimiter(pa_marine_area.round(0))
    }
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
          percentage: stat.percentage_pa_marine_cover.round(1),
          km: number_with_delimiter(stat.pa_marine_area.round(0)),
          iso3: stat.country.iso_3
        }
      end
    }
  end

  def top_gl_coverage_countries
  # List of all countries with at least one green list PA
    countries = Country.countries_with_gl

    # Group them by region
    countries_in_region = countries.select { |country| country.region == region }

    countries_in_region.concat(region.countries.where.not(id: countries_in_region).take(10 - countries_in_region.length).to_a)

    all_gls = countries_in_region.map do |country|
      total_gl_area = country.protected_areas.green_list_areas.present? ? country.total_gl_coverage : 0
    
      total_area = country.country_statistic.land_area + country.country_statistic.marine_area
      percentage_of_total_area = ((total_gl_area / total_area ).to_f * 100).round(1)
      { country: country, total_area: total_gl_area, percentage: percentage_of_total_area }
    end.sort! do |a, b|
      # If rounded %s happen to be the same, then sort by area
      b[:percentage] == a[:percentage] ? b[:total_area] <=> a[:total_area] : b[:percentage] <=> a[:percentage] 
    end

    {
      regionTitle: region.name,
      countries: all_gls.map do |stat|
        {
          title: stat[:country].name,
          percentage: stat[:percentage],
          km: number_with_delimiter(stat[:total_area].round(0)),
          iso3: stat[:country].iso_3
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
