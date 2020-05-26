module Concerns::Filterable
  extend ActiveSupport::Concern

  included do
    private

    def load_filters
      @area_type = search_params[:area_type]
      @search_area_types = [
        {
          id: @area_type,
          title: I18n.t("global.area-types.#{@area_type}"),
          placeholder: I18n.t("global.placeholder.search-#{@area_type}")
        }
      ].to_json

      @filter_groups = [
        {
          title: I18n.t('search.filter-by'),
          filters: [
            {
              id: 'db_type',
              name: 'db_type',
              options: [
                { id: 'oecm', title: I18n.t('search.filter-group-db.options')[0] },
                { id: 'wdpa', title: I18n.t('search.filter-group-db.options')[1] },
              ],
              type: 'checkbox'
            },
            {
              id: 'is_type',
              name: 'is_type',
              options: [
                { id: 'all', title: I18n.t('search.filter-group-type.options')[0] },
                { id: 'terrestrial', title: I18n.t('search.filter-group-type.options')[1] },
                { id: 'marine', title: I18n.t('search.filter-group-type.options')[2] }
              ],
              title: I18n.t('search.filter-group-type.title'),
              type: 'checkbox'
            },
            {
              id: 'special_status',
              name: 'special_status',
              options: [
                { id: 'green-list', title: I18n.t('search.filter-group-special-status.options')[0] },
                { id: 'parcc', title: I18n.t('search.filter-group-special-status.options')[1] },
                { id: 'irreplacibility', title: I18n.t('search.filter-group-special-status.options')[2] },
              ],
              title: I18n.t('search.filter-group-special-status.title'),
              type: 'checkbox'
            },
            {
              id: 'geo_type',
              name: 'geo_type',
              options: [
                { 
                  id: 'country', 
                  title: I18n.t('search.filter-group-geo-type.options')[0],
                  autocomplete: [ 
                    { id: '1 ferdi - whatever you need', title: 'United Kingdom' },
                    { id: '2 ferdi - whatever you need', title: 'United Arab Emirates' }
                  ]
                },
                { 
                  id: 'region', 
                  title: I18n.t('search.filter-group-geo-type.options')[1],
                  autocomplete: [ { id: '3 ferdi - whatever you need', title: 'Europe' }]
                }
              ],
              title: I18n.t('search.filter-group-geo-type.title'),
              type: 'radio-search'
            },
            {
              id: 'designation',
              options: objs_for(Designation),
              title: I18n.t('search.filter-group-designation.title'),
              type: 'checkbox'
            },
            {
              id: 'governance',
              options: objs_for(Governance),
              title: I18n.t('search.filter-group-governance.title'),
              type: 'checkbox'
            },
            {
              id: 'iucn_category',
              options: objs_for(IucnCategory),
              title: I18n.t('search.filter-group-iucn-category.title'),
              type: 'checkbox'
            }
          ]
        }
      ].to_json
    end

    def objs_for(model)
      model.all.map { |obj| { id: obj.name, title: obj.name } }
    end
  end
end
