require 'test_helper'

class SearchSorterTest < ActiveSupport::TestCase
  test '#from_params, given a hash of sort params, returns the sort
   as a hash' do
    sorters = Search::Sorter.from_params(geo_distance: [40, 35])

    expected_sorters = [{
      "_geo_distance" => {
          "protected_area.coordinates" => [40, 35],
          "order" => "asc",
          "unit" => "km"
      }
    }]

    assert_equal sorters, expected_sorters
  end

  test '.to_h, given a geo distance sorter, returns a geo distance
   sorter with the given coordinates' do
    options = { type: 'geo_distance', field: 'protected_area.coordinates' }
    sorter = Search::Sorter.new([40, 35], options)

    expected_sorter = {
      "_geo_distance" => {
          "protected_area.coordinates" => [40, 35],
          "order" => "asc",
          "unit" => "km"
      }
    }

    assert_equal sorter.to_h, expected_sorter
  end
end
