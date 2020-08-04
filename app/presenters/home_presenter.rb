class HomePresenter
  include ActionView::Helpers::NumberHelper

  def initialize
  end

  def terrestrial_pas
    @terrestrial_pas ||= number_with_delimiter(Stats::Global.terrestrial_pa_count)
  end
  
  def marine_pas
    @marine_pas ||= number_with_delimiter(Stats::Global.marine_pa_count)
  end

  def terrestrial_oecms
    @terrestrial_oecms = number_with_delimiter(Stats::Global.terrestrial_oecm_count)
  end

  def marine_oecms
    @marine_oecms = number_with_delimiter(Stats::Global.marine_oecm_count)
  end

  def terrestrial_cover
    @terrestrial_cover = CountryStatistic.global_percentage_pa_land_cover
  end

  def marine_cover
    @marine_cover = CountryStatistic.global_percentage_pa_marine_cover
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
            text: I18n.t('home.total_pas')
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
            text: I18n.t('home.total_pas')
          }
        ]
      },
      {
        percentage: 00, #total percentage coverage of terrestrial pas and OECMs
        theme: I18n.t('home.facts')[2][:theme],
        title: I18n.t('home.facts')[2][:title],
        totals: [
          {
            number: terrestrial_pas,
            text: I18n.t('home.total_pas')
          },
          {
            number: terrestrial_oecms,
            text: I18n.t('home.total_oecms')
          }
        ]
      },
      {
        percentage: 00, #total percentage coverage of marine pas and OECMs
        theme: I18n.t('home.facts')[3][:theme],
        title: I18n.t('home.facts')[3][:title],
        totals: [
          {
            number: marine_pas,
            text: I18n.t('home.total_pas')
          },
          {
            number: marine_oecms,
            text: I18n.t('home.total_oecms')
          }
        ]
      }
    ]
  end
end