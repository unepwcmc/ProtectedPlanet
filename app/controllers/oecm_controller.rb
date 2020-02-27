class OecmController < ApplicationController
  def index
    @search_area_types = [
      { name: I18n.t('global.area-types.oecm'), placeholder: I18n.t('global.placeholder.oecm') }
    ].to_json
  end
end