require 'test_helper'

class SearchAggregationTest < ActiveSupport::TestCase
  test '#all returns a hash with all aggregations configurations' do
    expected_aggregations = {
      "protected_areas_by_country" => {
        "nested" => {
          "path" => "countries"
        },
        "aggs" => {
          "aggregation" => {
            "terms" => {
              "field" => "countries.id"
            }
          }
        }
      },
      "protected_areas_by_region" => {
        "nested" => {
          "path" => "countries.region"
        },
        "aggs" => {
          "aggregation" => {
            "terms" => {
              "field" => "countries.region.id"
            }
          }
        }
      },
      "protected_areas_by_designation" => {
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
      "protected_areas_by_iucn_category" => {
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
