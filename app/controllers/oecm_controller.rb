class OecmController < ApplicationController
  include MapHelper
  
  def index
    @oecm_coverage_percentage = 10 ##TODO FERDI - percentage of the world covered by OECMs

    @search_area_types = [
      { id: 'oecm', title: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.search-oecms') }
    ].to_json

    @tabs = get_tabs(3).to_json

    @map = {
      disclaimer: map_yml[:disclaimer],
      title: map_yml[:title],
      overlays: MapOverlaysSerializer.new(oecm_overlays, map_yml).serialize
    }
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