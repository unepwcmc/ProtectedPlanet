require 'test_helper'

class HomeHelperTest < ActionView::TestCase
  # The home-category filter building moved from a HomeHelper#get_filters method to
  # SearchAreaLinkFilters.home_category_filters(filter:, is_green_list:), which now
  # returns just the status/type key (db_type is applied elsewhere in the search path).
  test 'home_category_filters builds a special_status filter for green list categories' do
    result = SearchAreaLinkFilters.home_category_filters(
      filter: 'pa_or_any_its_parcels_is_greenlisted', is_green_list: true
    )
    assert_equal({ special_status: ['pa_or_any_its_parcels_is_greenlisted'] }, result)
  end

  test 'home_category_filters builds an is_type filter for non-green-list categories' do
    result = SearchAreaLinkFilters.home_category_filters(filter: 'marine', is_green_list: false)
    assert_equal({ is_type: ['marine'] }, result)
  end
end
