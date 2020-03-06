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
              id: 'is_type',
              name: 'is_type',
              options: [
                { id: 'all', title: I18n.t('global.search.filter-group-type.options')[0] },
                { id: 'terrestrial', title: I18n.t('global.search.filter-group-type.options')[1] },
                { id: 'marine', title: I18n.t('global.search.filter-group-type.options')[2] }
              ],
              title: I18n.t('global.search.filter-group-type.title'),
              type: 'radio'
            },
            {
              id: 'designation',
              options: objs_for(Designation),
              title: I18n.t('global.search.filter-group-designation.title'),
              type: 'checkbox'
            },
            {
              id: 'governance',
              options: objs_for(Governance),
              title: I18n.t('global.search.filter-group-governance.title'),
              type: 'checkbox'
            },
            {
              id: 'iucn-category',
              options: objs_for(IucnCategory),
              title: I18n.t('global.search.filter-group-iucn-category.title'),
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
