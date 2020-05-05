class HomeController < ApplicationController
  def index
    home_yml = I18n.t('home')

    @pa_coverage_percentage = 9999 #TODO Total PA coverage in %

    @config_search_areas = {
      id: 'all',
      placeholder: I18n.t('global.placeholder.search-oecm-wdpa')
    }.to_json

    @pas_title = home_yml[:pas][:title]
    @pas_button = home_yml[:pas][:button]
    @pas_levels = home_yml[:pas][:levels]

    comfy_themes = Comfy::Cms::Page.find_by_slug("thematical-areas")
    @themes_title = comfy_themes.label
    @themes_url = comfy_themes.full_path

    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")

    @carousel_slides = HomeCarouselSlide.all.select{|slide| slide.published }
  end
end