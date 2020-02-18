class SearchWdpaController < ApplicationController
  def index
    search_pas = ProtectedArea.first(4).map{ |pa| {"id": pa.wdpa_id, "name": pa.name} }##TODO Ferdi - update this with ac

    @search_pas_types = [
      { name: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.wdpa'), endpoint: '' }
    ].to_json

    @temp = {
      
    }.to_json
  end
end