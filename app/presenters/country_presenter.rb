class CountryPresenter
  include ActionView::Helpers::NumberHelper
  
  def initialize country
    @country = country
    @statistic = StatisticPresenter.new(country)
    @designations_presenter = DesignationsPresenter.new(country)
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

  def coverage_growth_chart(exclude_oecms: false)
    {
      title: I18n.t('charts.legend.coverage_km2'),
      units: I18n.t('charts.units.km2'),
      datapoints: @country.coverage_growth(exclude_oecms).map { |el| { year: el['year'], value: el['count'] } }
    }
  end

  def designations(exclude_oecms: false)
    @designations_presenter.designations(exclude_oecms: exclude_oecms)
  end

  def documents
    [
      national_report,
      malaysia_documents
    ].compact.flatten
  end

  def build_stats(type)
    {
      national_report_version: statistic.nr_version,
      pame_km2: number_with_delimiter(statistic.pame_statistic.send("pame_pa_#{type}_area").round(0)),
      pame_percentage: statistic.pame_statistic.send("pame_percentage_pa_#{type}_cover").round(2),
      protected_km2: number_with_delimiter(statistic.send("pa_#{type}_area").round(0)),
      protected_national_report: statistic.send("percentage_nr_#{type}_cover"),
      protected_percentage: statistic.send("percentage_pa_#{type}_cover").round(2),
      total_km2: number_with_delimiter(statistic.send("#{type}_area").round(0)),
      title: I18n.t("stats.coverage_#{yml_key(type)}.title_wdpa"),
      type: yml_key(type),
      text_protected: I18n.t("stats.coverage_#{yml_key(type)}.covered"),
      text_total: I18n.t("stats.coverage_#{yml_key(type)}.total"),
      text_coverage: I18n.t("stats.coverage"), #same as marine
      text_national_report: I18n.t("stats.nr-report-title"), #same as marine
      text_pame: I18n.t("stats.pame.areas-assessed"), #same as marine
      text_pame_assessments: I18n.t("stats.pame.with-assessments"), #same as marine
    }
  end

  def build_combined_stats(type)
    build_stats(type).merge!(
      {
        protected_km2: number_with_delimiter(statistic.send("oecms_pa_#{type}_area").round(0)),
        protected_percentage: statistic.send("percentage_oecms_pa_#{type}_cover").round(2),
        title: I18n.t("stats.coverage_#{yml_key(type)}.title_wdpa_oecm")
      }
    )
  end

  def marine_page_statistics
    {
      title: country.name,
      totalMarineArea: statistic.total_marine_area.round,
      totalOverseasTerritories: country.children.count,
      overseasTerritoriesURL: overseas_territories_url,
      flag: "flags/#{flag_name}",
      nationalKm: statistic.pa_marine_area.round,
      nationalPercentage: statistic.percentage_pa_marine_cover.round(2),
      overseasKm: statistic.overseas_total_protected_marine_area.round, ##check how this is being calculated
      overseasPercentage: statistic.overseas_percentage.round(2) ##check how this is being calculated - discuss
    }
  end

  def malaysia_documents
    return unless @country && @country.iso_3 == "MYS"
    [
      {
        url: 'https://wdpa.s3.amazonaws.com/Country_informations/MYS/COMMUNICATION%20PLAN%202012-2017.pdf',
        name: 'Department of Marine Park Malaysia CP',
        type: 'pdf',
        button_text: I18n.t("global.button.pdf")
      },
      {
        url: 'https://wdpa.s3.amazonaws.com/Country_informations/MYS/TOTAL%20ECONOMIC%20VALUE%20OF%20MARINE%20BIODIVERSITY.pdf',
        name: 'Malaysia Marine Parks Biodiversity',
        type: 'pdf',
        button_text: I18n.t("global.button.pdf")
      }
    ]
  end

  def national_report
    return unless @statistic.nr_report_url.present?
    {
      url: @statistic.nr_report_url,
      name: I18n.t('stats.nr_latest'),
      type: 'link',
      button_text: I18n.t("global.button.link")
    }
  end

  def total_points_percentage
    statistic.geometry_ratio[:points]
  end

  def total_polygons_percentage
    statistic.geometry_ratio[:polygons]
  end

  private

  def yml_key(type)
    type == 'land' ? 'terrestrial' : 'marine'
  end

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

  def flag_name
    country.name.underscore.gsub(' ', '-').gsub(/"/, '').gsub(',','').gsub(/'/,'')
  end
end
