class Data::WdpcaController < ApplicationController
  include MapHelper

  def index
    @download_options = helpers.download_options(%w[csv shp gdb esri_wdpa], 'general', 'wdpa')

    @config_search_areas = {
      id: PageSlugs::Data::WDPCA,
      placeholder: I18n.t('global.placeholder.search-wdpca')
    }.to_json

    @wdpca_view_all_url = search_areas_path(geo_type: 'site')
    @tabs_list = helpers.thematic_and_data_area_tabs(@cms_page)

    @map = {
      overlays: MapOverlaysSerializer.new(wdpca_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'wdpca',
      point_query_services: all_services_for_point_query
    }
  end

  private

  def wdpca_overlays
    overlays(%w[oecm marine_wdpa terrestrial_wdpa])
  end
end
