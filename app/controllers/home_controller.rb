class HomeController < ApplicationController
  def index
    @pa_coverage_percentage = 9999 #TODO Total PA coverage in %

    @config_search_areas = {
      id: 'all',
      placeholder: I18n.t('global.placeholder.search-oecm-wdpa')
    }.to_json

    @pas_title = home_yml[:pas][:title]
    @pas_button = home_yml[:pas][:button]
    @pas_levels = levels

    @site_facts = [
      {
        percentage: 00, #total percentage coverage of terrestrial pas
        theme: I18n.t('home.facts')[0][:theme],
        title: I18n.t('home.facts')[0][:title],
        totals: [
          {
            number: 00, #total terrestrial pas
            text: I18n.t('home.total_pas')
          }
        ]
      },
      {
        percentage: 00, #total percentage coverage of marine pas
        theme: I18n.t('home.facts')[1][:theme],
        title: I18n.t('home.facts')[1][:title],
        totals: [
          {
            number: 00, #total marine pas
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
            number: 00, #total terrestrial pas
            text: I18n.t('home.total_pas')
          },
          {
            number: 00, #total terrestrial oecms
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
            number: 00, #total marine pas
            text: I18n.t('home.total_pas')
          },
          {
            number: 00, #total marine oecms
            text: I18n.t('home.total_oecms')
          }
        ]
      }
    ]

    comfy_themes = Comfy::Cms::Page.find_by_slug("thematical-areas")
    @themes_title = comfy_themes.label
    @themes_url = comfy_themes.full_path

    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")

    @carousel_slides = HomeCarouselSlide.all.select{|slide| slide.published }
  end

  private

  def levels
    _levels = home_yml[:pas][:levels]
    _levels.map do |level|
      geo_type = level.delete(:geo_type)
      level[:url] = search_areas_path({geo_type: geo_type, filters: {db_type: ['wdpa']}})
      level
    end
  end

  def home_yml
    @home_yml ||= I18n.t('home')
  end

end