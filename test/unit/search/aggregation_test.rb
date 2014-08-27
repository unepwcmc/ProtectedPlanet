require 'test_helper'

class SearchAggregationTest < ActiveSupport::TestCase
  test '#all returns a hash with all aggregations configurations' do
    expected_aggregations = {
      "country" => {
        "nested" => {
          "path" => "countries_for_index"
        },
        "aggs" => {
          "aggregation" => {
            "terms" => {
              "field" => "countries_for_index.id"
            }
          }
        }
      },
      "region" => {
        "nested" => {
          "path" => "countries_for_index.region_for_index"
        },
        "aggs" => {
          "aggregation" => {
            "terms" => {
              "field" => "countries_for_index.region_for_index.id"
            }
          }
        }
      },
      "designation" => {
        "nested" => {
          "path" => "designation"
        },
        "aggs" => {
          "aggregation" => {
            "terms" => {
              "field" => "designation.id"
            }
          }
        }
      },
      "iucn_category" => {
        "nested" => {
          "path" => "iucn_category"
        },
        "aggs" => {
          "aggregation" => {
            "terms" => {
              "field" => "iucn_category.id"
            }
          }
        }
      }
    }

    aggregations = Search::Aggregation.all

    assert_equal expected_aggregations, aggregations
  end
end
