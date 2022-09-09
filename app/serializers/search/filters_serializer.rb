class Search::FiltersSerializer < Search::BaseSerializer
  def initialize(search, opts={})
    super(search, opts)
    @aggregations = @search.aggregations
  end

  def serialize
    [
      {
        title: I18n.t('search.filter-by'),
        filters: [
          {
            id: 'db_type',
            name: 'db_type',
            options: [
              { id: 'oecm', title: I18n.t('search.filter-group-db.options')[0] },
              { id: 'wdpa', title: I18n.t('search.filter-group-db.options')[1] }
          ],
            type: 'checkbox'
          },
          {
            id: 'is_type',
            name: 'is_type',
            options: [
              { id: 'terrestrial', title: I18n.t('search.filter-group-type.options.terrestrial') },
              { id: 'marine', title: I18n.t('search.filter-group-type.options.marine') }
            ],
            title: I18n.t('search.filter-group-type.title'),
            type: 'checkbox'
          },
          {
            id: 'special_status',
            name: 'special_status',
            options: [
              { id: 'is_green_list', title: I18n.t('search.filter-group-special-status.options')[0] },
              { id: 'is_green_list_candidate', title: I18n.t('search.filter-group-special-status.options')[1] },
              { id: 'has_parcc_info', title: I18n.t('search.filter-group-special-status.options')[2] },
              { id: 'is_transboundary', title: I18n.t('search.filter-group-special-status.options')[3] }
            ],
            title: I18n.t('search.filter-group-special-status.title'),
            type: 'checkbox'
          },
          {
            id: 'location',
            name: 'location',
            options: [
              { 
                id: 'country', 
                title: I18n.t('search.filter-group-geo-type.options')[0],
                autocomplete: objs_for('country'),
              },
              { 
                id: 'region', 
                title: I18n.t('search.filter-group-geo-type.options')[1],
                autocomplete: objs_for('region'),
              }
            ],
            title: I18n.t('search.filter-group-geo-type.title'),
            type: 'checkbox-search'
          },
          {
            id: 'designation',
            options: objs_for('designation'),
            title: I18n.t('search.filter-group-designation.title'),
            type: 'checkbox'
          },
          {
            id: 'governance',
            options: objs_for('governance'),
            title: I18n.t('search.filter-group-governance.title'),
            type: 'checkbox'
          },
          {
            id: 'iucn_category',
            options: objs_for('iucn_category'),
            title: I18n.t('search.filter-group-iucn-category.title'),
            type: 'checkbox'
          }
        ]
      }
    ]
  end

  def objs_for(aggregation)
    records = sorted_records(@aggregations[aggregation], aggregation)
    records.map { |obj| { id: obj[:label], title: obj[:label] } }.uniq
  end

  def sorted_records(records, agg_type)
    if agg_type == 'iucn_category'
      records.sort_by { |r| r[:identifier] }
    else
      records.sort_by { |r| r[:label] }
    end
  end
end