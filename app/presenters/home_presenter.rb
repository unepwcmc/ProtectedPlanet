class HomePresenter
  include ActionView::Helpers::NumberHelper

  def initialize
  end

  # Number of areas is still taken from the imported database rather than the global stats CSV.
  # This is because we select out some sites for coverage stats so the number in the
  # global stats csv is the number of the sites we use to calculate the coverage numbers beneath it.
  def terrestrial_pas
    @terrestrial_pas ||= number_with_delimiter(ProtectedArea.where(marine: false).count)
  end
  
  def marine_pas
    @marine_pas ||= number_with_delimiter(ProtectedArea.where(marine: true).count)
  end

  def terrestrial_oecms
    number_with_delimiter(ProtectedArea.where(marine: false, is_oecm: true).count)
  end

  def marine_oecms
    number_with_delimiter(ProtectedArea.where(marine: true, is_oecm: true).count)
  end

  def terrestrial_cover
    GlobalStatistic.total_land_pa_coverage_percentage
  end

  def marine_cover
    GlobalStatistic.total_ocean_pa_coverage_percentage
  end

  def oecm_pa_land_cover
    GlobalStatistic.total_land_oecms_pas_coverage_percentage
  end

  def oecm_pa_marine_cover
    GlobalStatistic.total_ocean_oecms_pas_coverage_percentage
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
end