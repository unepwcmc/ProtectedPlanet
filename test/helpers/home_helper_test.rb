require 'test_helper'

class HomeHelperTest < ActionView::TestCase
  test '#get_filters returns special_status and db_type for green list filter' do
    result = get_filters('pa_or_any_its_parcels_is_greenlisted')
    assert_equal({ special_status: ['pa_or_any_its_parcels_is_greenlisted'], db_type: ['wdpa'] }, result)
  end

  test '#get_filters returns is_type and db_type for non-green-list filter' do
    result = get_filters('marine')
    assert_equal({ is_type: ['marine'], db_type: ['wdpa'] }, result)
  end
end
