class WdpcaController < ApplicationController
  include Concerns::Tabs
  include MapHelper

  def index
    @pa_coverage_percentage = Stats::Global.percentage_pa_cover

    # Combined WDPA + OECM downloads
    @download_options = helpers.download_options(['csv', 'shp', 'gdb'], 'general', 'general')

    @config_search_areas = {
      id: 'all',
      placeholder: I18n.t('global.placeholder.search-oecm-wdpa')
    }.to_json

    @filters = { }
    @tabs_list = get_tabs(5, true)
    @tabs = @tabs_list.to_json

    @map = all_areas_map_config
  end

end