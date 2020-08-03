module NewsAndStoriesHelper
  def news_filters
    category_groups = load_categories

    [
      {
        title: I18n.t('search.filter-by'),
        filters: category_groups.map do |group|
          {
            id: group[:id],
            options: group[:items],
            title: group[:title],
            type: 'checkbox'
          }
        end
      }
    ].to_json
  end
end