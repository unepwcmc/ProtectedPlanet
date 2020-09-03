class OecmController < ApplicationController
  include MapHelper
  
  def index
    @oecm_coverage_percentage = 10 ##TODO FERDI - percentage of the world covered by OECMs

    @config_search_areas = {
      id: 'oecm',
      placeholder: I18n.t('global.placeholder.search-oecm')
    }.to_json

    @tabs = get_tabs(3).to_json

    @map = {
      overlays: MapOverlaysSerializer.new(oecm_overlays, map_yml).serialize,
      title: I18n.t('map.title_oecm'),
      type: 'oecm'
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

  def get_tabs total_tabs
    tabs = []

    total_tabs.times do |i|
      tab = {
        id: i+1,
        title: @cms_page.fragments.where(identifier: "tab-title-#{i+1}").first.content
      }

      tabs << tab
    end

    tabs
  end
end