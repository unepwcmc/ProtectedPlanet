class OecmController < ApplicationController
  include Concerns::Tabs
  include MapHelper

  def index
    @oecm_coverage_percentage = GlobalStatistic.global_oecms_pas_coverage_percentage

    @download_options = helpers.download_options(['csv', 'shp', 'gdb', 'esri_oecm'], 'general', 'oecm')

    @config_search_areas = {
      id: 'oecm',
      placeholder: I18n.t('global.placeholder.search-oecm')
    }.to_json

    @tabs = get_tabs.to_json

    @map = {
      overlays: MapOverlaysSerializer.new(oecm_overlays, map_yml).serialize,
      title: I18n.t('map.title_oecm'),
      type: 'oecm',
      point_query_services: [
        { url: OECM_FEATURE_SERVER_LAYER_URL, isPoint: false }
      ]
    }
    @map_options = {
      map: { center: [-100,0] }
    }
    @filters = { db_type: ['oecm'] }
  end

  private

  def oecm_overlays
    overlays(['oecm'], {
      'oecm': {
        isToggleable: false
      }
    })
  end
end