require 'test_helper'

class SearchFilterTest < ActiveSupport::TestCase
  test '#from_params, given a nested Filter, returns the filter query as a
   hash' do
    filters = Search::Filter.from_params({region: 3})

    expected_filters = [{
      "bool"=>{
        "should"=>[
          {
            "nested"=>{
              "path"=>"countries_for_index.region_for_index",
              "filter"=>{
                "bool"=>{
                  "must"=>{
                    "term"=>{
                      "countries_for_index.region_for_index.id"=>3
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }]

    assert_equal expected_filters, filters
  end

  test '#from_params, given a type Filter, returns the filter query as a
   hash' do
    filter = Search::Filter.from_params({type: 'country'})
    expected_filters = [{"bool"=>{"should"=>[{"type"=>{"value"=>"country"}}]}}]

    assert_equal expected_filters, filter
  end

  test '#from_params, given a marine filter, returns the filter query
   as a hash' do
    filters = Search::Filter.from_params(marine: false)
    expected_filters = [{"bool"=>{"should"=>[{"term"=>{"marine"=>false}}]}}]

    assert_equal expected_filters, filters
  end

  test '#from_params, given an integer filter passed as a string, converts
   the string to an integer' do
    filters = Search::Filter.from_params(region: '3')

    expected_filters = [{
      "bool"=>{
        "should"=>[
          {
            "nested"=>{
              "path"=>"countries_for_index.region_for_index",
              "filter"=>{
                "bool"=>{
                  "must"=>{
                    "term"=>{
                      "countries_for_index.region_for_index.id"=>3
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }]

    assert_equal expected_filters, filters
  end

  test '#from_params, given a geo filter passed as a string, converts
   the string to a float' do
    puts "the test"
    filters = Search::Filter.from_params(location: {coords: ['1','2'], distance: '2'})

    expected_filters =  [{
      "bool" => {
        "should" => [{
          "geo_distance" => {
            "distance" => "2000km",
            "protected_area.coordinates" => {
              "lon"=>1.0,
              "lat"=>2.0
            }
          }
        }]
      }
    }]

    assert_equal expected_filters, filters
  end

  test '.to_h, given a geo filter, returns the filter as a hash' do
    filters = Search::Filter.from_params(location: {distance_km: 123, coords: [1,2]})

    expected_filters = [{
      "bool"=>{
        "should"=>[
          {
            "geo_distance"=>{
              "distance"=>"123km",
              "protected_area.coordinates"=>{
                "lon"=>1.0,
                "lat"=>2.0
              }
            }
          }
        ]
      }
    }]

    assert_equal expected_filters, filters
  end

  test '#from_params, given a filter with an array of values, creates a
   filter for each value' do
    filters = Search::Filter.from_params(
      iucn_category: [1,2]
    )

    expected_filters = [{
      "bool"=>{
        "should"=>[
          {
            "nested"=>{
              "path"=>"iucn_category",
              "filter"=>{
                "bool"=>{
                  "must"=>{
                    "term"=>{
                      "iucn_category.id"=>1
                    }
                  }
                }
              }
            }
          },
          {
            "nested"=>{
              "path"=>"iucn_category",
              "filter"=>{
                "bool"=>{
                  "must"=>{
                    "term"=>{
                      "iucn_category.id"=>2
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }]

    assert_equal expected_filters, filters
  end
end
