class RegionPresenter
  include ActionView::Helpers::NumberHelper

  # Relates to GL 'top-10' chart size (per region)
  GL_CHART_SIZE = 10.freeze

  def initialize(region)
    @region = region
    @countries = @region.countries
    @statistics = @countries.map(&:statistic).compact
    @designations_presenter = DesignationsPresenter.new(region)
  end

  def iucn_categories_chart(chart_input)
    chart_input.enum_for(:each_with_index)
      .map do |category, i|
      { 
        id: i+1,
        title: category['iucn_category_name'], 
        value: category['count'] 
      }
    end
  end

  def governance_chart(chart_input)
    chart_input.map do |item|
      { 
        id: item['governance_id'],
        title: item['governance_name'],
        value: item['count']
      }
    end
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

  def designations(exclude_oecms: false)
    @designations_presenter.designations(exclude_oecms: exclude_oecms)
  end

  def build_stats(type)
    {
      protected_km2: number_with_delimiter(send("pa_#{type}_area").round(0)),
      protected_percentage: send("percentage_pa_#{type}_cover").round(2),
      total_km2: number_with_delimiter(send("#{type}_area").round(0)),
      title: I18n.t("stats.coverage_#{yml_key(type)}.title_wdpa"),
      type: yml_key(type),
      text_protected: I18n.t("stats.coverage_#{yml_key(type)}.covered"),
      text_total: I18n.t("stats.coverage_#{yml_key(type)}.total"),
      text_coverage: I18n.t("stats.coverage"), 
    }
  end

  def build_combined_stats(type)
    build_stats(type).merge!(
      {
        protected_km2: number_with_delimiter(send("oecms_pa_#{type}_area").round(0)),
        protected_percentage: send("percentage_oecms_pa_#{type}_cover").round(2),
        title: I18n.t("stats.coverage_#{yml_key(type)}.title_wdpa_oecm")
      }
    )
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
      polygons_count += statistic&.polygons_count || 0
      points_count += statistic&.points_count || 0
    end

    total = polygons_count + points_count

    return { polygons: 0, points: 0 } if total == 0

    {
      polygons: ((polygons_count / total.to_f) * 100).round,
      points: ((points_count / total.to_f) * 100).round
    }
  end

  def percentage_oecms_pa_land_cover
    @statistics.map(&:percentage_oecms_pa_land_cover).compact.reduce(:+)
  end

  def percentage_pa_land_cover
    # (pa_land_area / land_area * 100).round(2) - not sure how accurate this stat is
    @statistics.map(&:percentage_pa_land_cover).compact.reduce(:+)
  end

  def oecms_pa_land_area
    @statistics.map(&:oecms_pa_land_area).compact.reduce(:+)
  end

  def pa_land_area
    @statistics.map(&:pa_land_area).compact.reduce(:+)
  end

  def land_area
    @statistics.map(&:land_area).compact.reduce(:+)
  end

  def percentage_oecms_pa_marine_cover
    @statistics.map(&:percentage_oecms_pa_marine_cover).compact.reduce(:+)
  end

  def percentage_pa_marine_cover
    # (pa_marine_area / marine_area * 100).round(2) - not sure how accurate this stat is
    @statistics.map(&:percentage_pa_marine_cover).compact.reduce(:+)
  end

  def oecms_pa_marine_area
    @statistics.map(&:oecms_pa_marine_area).compact.reduce(:+)
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
    # List of all countries with at least one green list PA, grouped by region
    countries = Country.countries_with_gl.where(region: region)
    corresponding_stats = get_gl_data_for_countries(countries)

    {
      regionTitle: region.name,
      countries: fill_chart(corresponding_stats)
    }
  end

  def get_gl_data_for_countries(countries)
    top_countries = countries.map do |country|
      total_area = country.country_statistic.total_area
      total_gl_area = country.total_gl_coverage
      percentage_of_total_area = ((total_gl_area / total_area).to_f * 100).round(1)
      
      { country: country, total_area: total_gl_area, percentage: percentage_of_total_area }
    end
    
    top_countries.sort! do |a, b|
      # If rounded %s happen to be the same, then sort by area
      b[:percentage] == a[:percentage] ? b[:total_area] <=> a[:total_area] : b[:percentage] <=> a[:percentage]
    end.take(10)
  end

  def fill_chart(stats)
    # Always return at least an array of empty chart bars (hashes symbolising them here)
    return Array.new(GL_CHART_SIZE, {}) if stats.empty?

    countries = stats.map do |stat|
      {
        title: stat[:country].name,
        percentage: stat[:percentage],
        km: number_with_delimiter(stat[:total_area].round(0)),
        iso3: stat[:country].iso_3
      }
    end

    countries.count < GL_CHART_SIZE ? countries.in_groups_of(GL_CHART_SIZE, {}).flatten : countries
  end

  private

  attr_reader :region

  def yml_key(type)
    type == 'land' ? 'terrestrial' : 'marine'
  end

  def overseas_territories_url
    overseas_territories = region.countries.map(&:iso_3).join(',')
    "search?q=#{overseas_territories}&type=country"
  end
end
