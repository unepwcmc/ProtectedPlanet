class OecmController < ApplicationController
  def index
    @oecm_coverage_percentage = 10 ##TODO FERDI - percentage of the world covered by OECMs

    @search_area_types = [
      { id: 'oecm', title: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.search-oecms') }
    ].to_json
  end
end