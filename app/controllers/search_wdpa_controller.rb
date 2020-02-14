class SearchWdpaController < ApplicationController
  def index
    search_pas = ProtectedArea.first(4).map{ |pa| {"id": pa.wdpa_id, "name": pa.name} }

    @search_pas_categories = [
      { name: 'Protected Areas', placeholder: 'Search for a Protected Area', options: search_pas }
    ].to_json

    @results = {
      regions: [
        {
          title: 'Asia & Pacific',
          url: 'url to page'
        }
      ],
      countries: [
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
      ],
      sites: [
        {
          country: 'France',
          image: 'url to generated map of PA location',
          region: 'Europe',
          title: 'Avenc De Fra Rafel',
          url: 'url to page'
        }
      ]
    }
  end
end