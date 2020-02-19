class SearchWdpaController < ApplicationController
  def index
    @search_area_types = [
      { name: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.wdpa') }
    ].to_json

    @filter_groups = [
      {
        title: 'View by', #Stacy get from yml
        filters: [
          {
            id: 'geo_type',
            name: 'geo_type',
            options: [ 
              { id: 'all', title: 'All' }, #Stacy get title from yml
              { id: 'regions', title: 'Regions' }, #Stacy get title from yml
              { id: 'countries', title: 'Countries' }, #Stacy get title from yml
              { id: 'sites', title: 'Protected Areas' } #Stacy get title from yml
            ],
            type: 'radio'
          }
        ]
      },
      {
        title: 'Filter by', #Stacy get from yml
        filters: [
          {
            id: 'type',
            options: [ 
              { id: 'marine', title: 'Marine' },  #Stacy get title from yml
              { id: 'terrestrial', title: 'Terrestrial' }, #Stacy get title from yml
              { id: 'green-list', title: 'Green List' } #Stacy get title from yml
            ],
            title: 'Type', #Stacy get from yml
            type: 'checkbox'
          },
          {
            id: 'designation',
            options: [ { id: 'designation-1', title: 'Designation 1' }, { id: 'designation-2', title: 'Designation 2' } ], #Ferdi pull from DB
            title: 'Designation', #Stacy get from yml
            type: 'checkbox'
          },
          {
            id: 'governance',
            options: [ { id: 'governance-1', title: 'Governance 1' }, { id: 'governance-2', title: 'Governance 2' } ], #Ferdi pull from DB            
            title: 'Governance', #Stacy get from yml
            type: 'checkbox'
          },
          {
            id: 'iucn-category',
            options: [ { id: 'iucn-category-1', title: 'IUCN Category 1' }, { id: 'iucn-category-2', title: 'IUCN Category 2' } ], #Ferdi pull from DB
            title: 'IUCN Category', #Stacy get from yml
            type: 'checkbox'
          }
        ]
      }
    ].to_json
  end
end