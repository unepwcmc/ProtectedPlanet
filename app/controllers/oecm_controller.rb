class OecmController < ApplicationController
  include Concerns::Tabs

  def index
    @oecm_coverage_percentage = 10 ##TODO FERDI - percentage of the world covered by OECMs

    @config_search_areas = {
      id: 'oecm',
      placeholder: I18n.t('global.placeholder.search-oecm')
    }.to_json

    @tabs = get_tabs(3).to_json
    @filters = { db_type: ['oecm'] }
  end
end