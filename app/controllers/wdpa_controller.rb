class WdpaController < ApplicationController
  include Concerns::Tabs
  include MapHelper

  def index
    @pa_coverage_percentage = 20 ##TODO FERDI - percentage of the world covered by PAs

    @config_search_areas = {
      id: 'wdpa',
      placeholder: I18n.t('global.placeholder.search-wdpa')
    }.to_json

    @filters = { db_type: ['wdpa'] }

    @tabs = get_tabs(3).to_json

    @map = {
      overlays: MapOverlaysSerializer.new(wdpa_overlays, map_yml).serialize
    }
  end

  private

  def wdpa_overlays
    overlays(['marine_wdpa', 'terrestrial_wdpa'])
  end
end