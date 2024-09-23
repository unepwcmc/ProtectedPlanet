class OecmController < ApplicationController
  include Concerns::Tabs
  include MapHelper

  def index
    @oecm_coverage_percentage = GlobalStatistic.global_oecms_pas_coverage_percentage

    @download_options = helpers.download_options(%w[csv shp gdb esri_oecm], 'general', 'oecm')

    @config_search_areas = {
      id: 'oecm',
      placeholder: I18n.t('global.placeholder.search-oecm')
    }.to_json

    @tabs_list = get_tabs(5, true)
    @tabs = @tabs_list.to_json

    @map = {
      overlays: MapOverlaysSerializer.new(oecm_overlays, map_yml).serialize,
      title: I18n.t('map.title_oecm'),
      type: 'oecm',
      point_query_services: oecm_services_for_point_query
    }
    @map_options = {
      map: { center: [-100, 0] }
    }
    @filters = { db_type: ['oecm'] }
  end

  private

  def oecm_overlays
    overlays(['oecm'], {
      oecm: {
        isToggleable: false
      }
    })
  end
end
