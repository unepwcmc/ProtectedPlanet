class Thematic::EffectivenessController < ApplicationController
  include Concerns::GreenListPageData

  def index
    prepare_green_list_tab_data
    @tabs_list = cms_page_tabs
  end
end
