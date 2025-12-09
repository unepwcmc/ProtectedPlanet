class WdpcaController < ApplicationController
  include Concerns::Tabs
  include MapHelper

  def index
    @pa_coverage_percentage = Stats::Global.percentage_pa_cover
    # As get_default_all_wdpca_download_option is supposed to have the same output (alll WDPCAs) as the following commented out line 
    # And they have the same file output name so they will overwrite each other if both are used
    # To keep it consistent, we use the get_default_all_wdpca_download_option
    # @download_options = helpers.download_options(['csv', 'shp', 'gdb'], 'general', Download::Requesters::General::TYPE_MAP[:all_wdpca])
    @download_options = helpers.get_default_all_wdpca_download_option
    @config_search_areas = {
      id: 'all',
      placeholder: I18n.t('global.placeholder.search-wdpca')
    }.to_json

    @filters = { }
    @tabs_list = get_tabs(5, true)
    @tabs = @tabs_list.to_json

    @map = all_areas_map_config
  end

end