class Thematic::EffectivenessController < ApplicationController
  after_action :enable_caching
  include GreenListPageData

  def index
    prepare_green_list_tab_data
    @tabs_list = helpers.thematic_and_data_area_tabs(@cms_page)
  end
end
