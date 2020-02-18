class SearchWdpaController < ApplicationController
  def index
    search_pas = ProtectedArea.first(4).map{ |pa| {"id": pa.wdpa_id, "name": pa.name} }##TODO Ferdi - update this with ac

    @search_pas_categories = [
      { name: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.wdpa'), endpoint: '' }
    ].to_json

    # @temp_autocomplete = [
    # ].to_json

    @temp = {
      results: [
        {
          type: 'region',
          title: 'Regions',
          total: 10,
          areas: [
            {
              title: 'Asia & Pacific',
              url: 'url to page'
            }
          ]
        },
        {
          type: 'country',
          title: 'Countries',
          total: 10,
          areas: [
            {
              areas: 5908,
              region: 'America',
              title: 'United States of America',
              url: 'url to page'
            },
            {
              areas: 508,
              regions: 'Europe',
              title: 'United Kingdom',
              url: 'url to page'
            },
            {
              areas: 508,
              regions: 'Europe',
              title: 'United Kingdom',
              url: 'url to page'
            },
            {
              areas: 508,
              regions: 'Europe',
              title: 'United Kingdom',
              url: 'url to page'
            }
          ]
        },
        {
          type: 'site',
          title: I18n.t('global.type.wdpa'),
          total: 30,
          areas: [
            {
              country: 'France',
              image: 'url to generated map of PA location',
              region: 'Europe',
              title: 'Avenc De Fra Rafel',
              url: 'url to page'
            }
          ]
        }
      ]
    }.to_json
  end

  def search_wdpa
    
  end
end