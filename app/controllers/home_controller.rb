class HomeController < ApplicationController
  include MapHelpers

  def index
    home_yml = I18n.t('home')

    @pa_coverage_percentage = 9999 #TODO Total PA coverage in %

    @search_area_types = [
      { id: 'wdpa', title: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.search-wdpa') },
      { id: 'oecm', title: I18n.t('global.area-types.oecm'), placeholder: I18n.t('global.placeholder.search-oecms') }
    ].to_json
    
    @pas_title = home_yml[:pas][:title]
    @pas_button = home_yml[:pas][:button]
    @pas_levels = home_yml[:pas][:levels]

    comfy_themes = Comfy::Cms::Page.find_by_slug("thematical-areas")
    @themes_title = comfy_themes.label
    @themes_url = comfy_themes.full_path

    @regions_page = Comfy::Cms::Page.find_by_slug("unep-regions")

    @carousel_slides = HomeCarouselSlide.all.select{|slide| slide.published }

    @main_map = {
      disclaimer: map_yml[:disclaimer],
      title: map_yml[:title],
      overlays: MapOverlaysSerializer.new(home_overlays, map_yml).serialize
    }
  end

  private

  def home_overlays
    overlays(['oecm', 'marine_wdpa', 'terrestrial_wdpa']),
  end
end
