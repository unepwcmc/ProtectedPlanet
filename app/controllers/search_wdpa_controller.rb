class SearchWdpaController < ApplicationController
  def index
    @search_area_types = [
      { name: I18n.t('global.area-types.wdpa'), placeholder: I18n.t('global.placeholder.wdpa') }
    ].to_json

    @filter_groups = [
      {
        title: I18n.t('global.search.view-by'),
        filters: [
          {
            id: 'geo_type',
            name: 'geo_type',
            options: [ 
              { id: 'all', title: I18n.t('global.search.view-group-geo-type.options')[0] },
              { id: 'regions', title: I18n.t('global.search.view-group-geo-type.options')[1] },
              { id: 'countries', title: I18n.t('global.search.view-group-geo-type.options')[2] },
              { id: 'sites', title: I18n.t('global.area-types.wdpa') } ## OR I18n.t('global.area-types.oecm')
            ],
            type: 'radio'
          }
        ]
      },
      {
        title: I18n.t('global.search.filter-by'),
        filters: [
          {
            id: 'type',
            options: [ 
              { id: 'marine', title: I18n.t('global.search.filter-group-type.options')[0] },
              { id: 'terrestrial', title: I18n.t('global.search.filter-group-type.options')[1] },
              { id: 'green-list', title: I18n.t('global.search.filter-group-type.options')[2] }
            ],
            title: I18n.t('global.search.filter-group-type.title'),
            type: 'checkbox'
          },
          {
            id: 'designation',
            options: [  #Ferdi pull from DB
              { id: 'designation-1', title: 'Designation 1' }, 
              { id: 'designation-2', title: 'Designation 2' },
              { id: 'designation-3', title: 'Designation 3' },
              { id: 'designation-4', title: 'Designation 4' },
              { id: 'designation-5', title: 'Designation 5' },
              { id: 'designation-6', title: 'Designation 6' },
              { id: 'designation-7', title: 'Designation 7' },
              { id: 'designation-8', title: 'Designation 8' },
              { id: 'designation-9', title: 'Designation 9' },
              { id: 'designation-10', title: 'Designation 10' },
              { id: 'designation-11', title: 'Designation 11' },
              { id: 'designation-12', title: 'Designation 12' }
            ],
            title: I18n.t('global.search.filter-group-designation.title'),
            type: 'checkbox'
          },
          {
            id: 'governance',
            options: [ { id: 'governance-1', title: 'Governance 1' }, { id: 'governance-2', title: 'Governance 2' } ], #Ferdi pull from DB            
            title: I18n.t('global.search.filter-group-governance.title'),
            type: 'checkbox'
          },
          {
            id: 'iucn-category',
            options: [ { id: 'iucn-category-1', title: 'IUCN Category 1' }, { id: 'iucn-category-2', title: 'IUCN Category 2' } ], #Ferdi pull from DB
            title: I18n.t('global.search.filter-group-iucn-category.title'),
            type: 'checkbox'
          }
        ]
      }
    ].to_json
  end
end