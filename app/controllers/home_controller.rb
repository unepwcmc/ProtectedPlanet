class HomeController < ApplicationController
  def index
    home_yml = I18n.t('home')
    map_yml = I18n.t('main_map')

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
      overlays:
        [
          {
            id: 'terrestrial-wdpa',
            title: map_yml[:overlays][:terrestrial_wdpa][:title],
            isToggleable: false,
            layers: ["https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/MapServer/tile/{z}/{y}/{x}"],
            color: "#38A800",
            isShownByDefault: true
          },
          {
            id: 'marine-wdpa',
            title: map_yml[:overlays][:marine_wdpa][:title],
            isToggleable: false,
            layers: ["https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_Protected_Areas/MapServer/tile/{z}/{y}/{x}"],
            color: "#004DA8",
            isShownByDefault: true
          },
          {
            id: 'oecm',
            title: map_yml[:overlays][:oecm][:title],
            isToggleable: true,
            layers: ["https://data-gis.unep-wcmc.org/server/rest/services/ProtectedSites/The_World_Database_on_other_effective_area_based_conservation_measures/MapServer/tile/{z}/{y}/{x}"],
            color: "#D9B143",
            isShownByDefault: true
          }
        ]
    }
  end
end
