class HomePresenter
  include ActionView::Helpers::NumberHelper

  def pas_coverage_percentage
    GlobalStatistic.global_oecms_pas_coverage_percentage
  end

  def terrestrial_pas
    @terrestrial_pas ||= number_with_delimiter(GlobalStatistic.total_terrestrial_protected_areas)
  end
  
  def marine_pas
    @marine_pas ||= number_with_delimiter(GlobalStatistic.total_marine_protected_areas)
  end

  def terrestrial_oecms
    GlobalStatistic.total_terrestrial_oecms
  end

  def marine_oecms
    GlobalStatistic.total_marine_oecms
  end

  def terrestrial_cover
    GlobalStatistic.total_land_pa_coverage_percentage.round(2)
  end

  def marine_cover
    GlobalStatistic.total_ocean_pa_coverage_percentage.round(2)
  end

  def oecm_pa_land_cover
    GlobalStatistic.total_land_oecms_pas_coverage_percentage.round(2)
  end

  def oecm_pa_marine_cover
    GlobalStatistic.total_ocean_oecms_pas_coverage_percentage.round(2)
  end
  
  def fact_card_stats
    [
      {
        percentage: terrestrial_cover,
        theme: I18n.t('home.facts')[0][:theme],
        title: I18n.t('home.facts')[0][:title],
        totals: [
          {
            number: terrestrial_pas,
            text: I18n.t('global.area-types.wdpa')
          }
        ]
      },
      {
        percentage: marine_cover,
        theme: I18n.t('home.facts')[1][:theme],
        title: I18n.t('home.facts')[1][:title],
        totals: [
          {
            number: marine_pas,
            text: I18n.t('global.area-types.wdpa')
          }
        ]
      },
      {
        percentage: oecm_pa_land_cover,
        theme: I18n.t('home.facts')[2][:theme],
        title: I18n.t('home.facts')[2][:title],
        totals: [
          {
            number: terrestrial_pas,
            text: I18n.t('global.area-types.wdpa')
          },
          {
            number: terrestrial_oecms,
            text: I18n.t('global.area-types.oecm')
          }
        ]
      },
      {
        percentage: oecm_pa_marine_cover,
        theme: I18n.t('home.facts')[3][:theme],
        title: I18n.t('home.facts')[3][:title],
        totals: [
          {
            number: marine_pas,
            text: I18n.t('global.area-types.wdpa')
          },
          {
            number: marine_oecms,
            text: I18n.t('global.area-types.oecm')
          }
        ]
      }
    ]
  end

  def update_date 
    WDPA_UPDATE_MONTH + ' ' + WDPA_UPDATE_YEAR
  end
end