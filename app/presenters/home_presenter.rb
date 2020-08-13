class HomePresenter
  include ActionView::Helpers::NumberHelper

  def initialize
  end

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
    CountryStatistic.global_percentage_pa_land_cover
  end

  def marine_cover
    CountryStatistic.global_percentage_pa_marine_cover
  end

  def oecm_pa_land_cover
    ProtectedArea.global_terrestrial_oecm_coverage
  end

  def oecm_pa_marine_cover
    ProtectedArea.global_marine_oecm_coverage
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
            text: I18n.t('global.area-types.oecm')
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