require 'test_helper'

class SearchQueryTest < ActiveSupport::TestCase
  test '.to_h, given a search term, returns an ElasticSearch query, with
   aggregations' do
    term = "manbone"

    expected_object = {
      "bool" => {
        "must" => {
          "bool" => {
            "should" => [
              {
                "nested" => {
                  "path" => "countries_for_index",
                  "query" => { "multi_match" => { "query" => "manbone", "fields" => [ "countries_for_index.name" ], "fuzziness" => "AUTO" } }
                }
              },
              {
                "nested" => {
                  "path" => "countries_for_index.region_for_index",
                  "query" => { "multi_match" => { "query" => "manbone", "fields" => [ "countries_for_index.region_for_index.name" ], "fuzziness" => "AUTO" } }
                }
              },
              {
                "nested" => {
                  "path" => "sub_location",
                  "query" => { "multi_match" => { "query" => "manbone", "fields" => [ "sub_location.english_name" ], "fuzziness" => "AUTO" } }
                }
              },
              {
                "nested" => {
                  "path" => "designation",
                  "query" => { "multi_match" => { "query" => "manbone", "fields" => [ "designation.name" ], "fuzziness" => "AUTO" } }
                }
              },
              {
                "nested" => {
                  "path" => "iucn_category",
                  "query" => { "multi_match" => { "query" => "manbone", "fields" => [ "iucn_category.name" ], "fuzziness" => "AUTO" } }
                }
              },
              {
                "nested" => {
                  "path" => "governance",
                  "query" => { "multi_match" => { "query" => "manbone", "fields" => [ "governance.name" ], "fuzziness" => "AUTO" } }
                }
              },
              {
                "terms"=> {
                  "wdpa_id"=>[]
                }
              },
              {
                "function_score" => {
                  "query" => {
                      "multi_match" => {
                          "query" => "*manbone*",
                          "fields" => [
                              "name",
                              "original_name"
                          ]
                      }
                  },
                  "boost" => "5",
                  "functions" => [
                    {
                      "filter" => {"match" => {"type" => "country"}},
                      "weight" => 20
                    }, {
                      "filter" => {"match" => {"type" => "region"}},
                      "weight" => 10
                    }
                  ]
                }
              }
            ]
          }
        }
      }
    }

    query = Search::Query.new(term)

    assert_equal expected_object, query.to_h
  end

  test '.to_h, given a search term and a type filter, builds a query
    with a type filter' do
    term = "manbone"
    type = "country"

    expected_object = {
      "bool" => {
        "must" => [
          {
            "bool" => {
              "should" => [
                {
                  "type" => {
                    "value" => type
                  }
                }
              ]
            }
          }
        ]
      }
    }

    query = Search::Query.new(term, filters: {type: 'country'}).to_h
    filters = query["bool"]["filter"]

    assert_equal expected_object, filters
  end

  test '.to_h, given no search term, and a filter, builds a query without matchers' do
    expected_filters = {
      "bool" => {
        "filter" => {
          "bool" => {
            "must" => [
              {
                "bool" => {
                  "should" => [
                    {
                      "geo_distance" => {
                        "distance" => "2000km",
                        "protected_area.coordinates" => {
                          "lon" => -69,
                          "lat" => -29
                        }
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      }
    }

    query = Search::Query.new('', filters: {location: {coords: [-69, -29]}}).to_h

    assert_equal expected_filters, query
  end
end
