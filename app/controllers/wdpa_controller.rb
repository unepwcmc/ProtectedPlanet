class WdpaController < ApplicationController
  def index
    @pa_coverage_percentage = 20 ##TODO FERDI - percentage of the world covered by PAs

    @search_area_types = [
      { id: 'wdpa', title: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.search-wdpa') }
    ].to_json

    @tabs = get_tabs(3).to_json
  end

  private

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