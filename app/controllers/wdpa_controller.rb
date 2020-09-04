class WdpaController < ApplicationController
  include Concerns::Tabs
  include MapHelper

  def index
    @pa_coverage_percentage = Stats::Global.percentage_pa_cover

    @download_options = helpers.download_options(['csv', 'shp', 'gdb', 'esri'], 'general', 'wdpa')

    @config_search_areas = {
      id: 'wdpa',
      placeholder: I18n.t('global.placeholder.search-wdpa')
    }.to_json

    @filters = { db_type: ['wdpa'] }

    @tabs = get_tabs.to_json

    @map = {
      overlays: MapOverlaysSerializer.new(wdpa_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'wdpa',
      point_query_services: [
        { url: WDPA_POINT_LAYER_URL, isPoint: true },
        { url: WDPA_POLY_LAYER_URL, isPoint: false }
      ]
    }
  end

  private

  def wdpa_overlays
    overlays(['marine_wdpa', 'terrestrial_wdpa'])
  end
end