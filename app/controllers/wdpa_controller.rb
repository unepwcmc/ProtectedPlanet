class WdpaController < ApplicationController
  def index
    @search_area_types = [
      { name: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.wdpa') }
    ].to_json
  end
end