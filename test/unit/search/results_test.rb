require 'test_helper'

class SearchResultsTest < ActiveSupport::TestCase
  test '.pluck, given a property, returns the corresponding values in the EC hits' do
    es_response = {
      'hits' => {
        'hits' => [
          { '_source' => {'wdpa_id' => 123, 'id' => 24} },
          { '_source' => {'wdpa_id' => 345, 'id' => 1} },
          { '_source' => {'id' => 22} }
        ]
      }
    }

    results = Search::Results.new(es_response)
    assert_equal [123, 345, nil], results.pluck('wdpa_id')
  end

  test '.with_coords returns all the search result models with their
   coordinates, WDPA ID and name' do
    es_response = {
      'hits' => {
        'hits' => [{
          '_type' => 'protected_area',
          '_source' => {
            'id' => 123,
            'wdpa_id' => 32423123,
            'name' => 'San Huirremo',
            'coordinates' => [1, -2]
          }
        }, {
          '_type' => 'protected_area',
          '_source' => {
            'id' => 456,
            'wdpa_id' => 32431878,
            'name' => 'San Terremo',
            'coordinates' => [-1, 0]
          }
        }]
      }
    }

    expected = [{
      'id' => 123,
      'wdpa_id' => 32423123,
      'name' => 'San Huirremo',
      'coordinates' => [1, -2]
    }, {
      'id' => 456,
      'wdpa_id' => 32431878,
      'name' => 'San Terremo',
      'coordinates' => [-1, 0]
    }]

    results = Search::Results.new(es_response)
    assert_same_elements expected, results.with_coords
  end

  test '.count returns the total count of the result set, rather than
   array length, so that pagination works correctly' do
    es_response = {"hits" => { "total" => 42 }}
    results = Search::Results.new(es_response)

    assert_equal 42, results.count
  end
end
