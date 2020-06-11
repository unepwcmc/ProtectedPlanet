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
            type: 'radio-search'
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
    records = @aggregations[aggregation]
    records.map { |obj| { id: obj[:label], title: obj[:label] } }
  end
end