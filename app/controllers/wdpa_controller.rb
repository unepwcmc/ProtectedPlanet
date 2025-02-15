class WdpaController < ApplicationController
  include Concerns::Tabs
  include MapHelper

  def index
    @pa_coverage_percentage = Stats::Global.percentage_pa_cover

    @download_options = helpers.download_options(['csv', 'shp', 'gdb', 'esri_wdpa'], 'general', 'wdpa')

    @config_search_areas = {
      id: 'wdpa',
      placeholder: I18n.t('global.placeholder.search-wdpa')
    }.to_json

    @filters = { db_type: ['wdpa'] }
    @tabs_list = get_tabs(5, true)
    @tabs = @tabs_list.to_json

    @map = {
      overlays: MapOverlaysSerializer.new(wdpa_overlays, map_yml).serialize,
      title: I18n.t('map.title'),
      type: 'wdpa',
      point_query_services: wdpa_services_for_point_query
    }
  end

  private

  def wdpa_overlays
    overlays(['marine_wdpa', 'terrestrial_wdpa'])
  end
end