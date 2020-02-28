class OecmController < ApplicationController
  def index
    @search_area_types = [
      { id: 'oecm', title: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.search-oecms') }
    ].to_json
  end
end