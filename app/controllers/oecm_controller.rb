class OecmController < ApplicationController
  include Concerns::Tabs
  include MapHelper

  def index
    @oecm_coverage_percentage = 10 ##TODO FERDI - percentage of the world covered by OECMs

    @config_search_areas = {
      id: 'oecm',
      placeholder: I18n.t('global.placeholder.search-oecm')
    }.to_json

    @tabs = get_tabs.to_json

    @map = {
      overlays: MapOverlaysSerializer.new(oecm_overlays, map_yml).serialize
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