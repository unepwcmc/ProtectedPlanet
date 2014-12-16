require 'test_helper'

class SearchAggregationTest < ActiveSupport::TestCase
  test '#all returns a hash with all aggregations configurations' do
    expected_aggregations = {
      "type_of_territory" => {
        "terms" => {
          "field" => "marine"
        }
      },
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

  test '.parse, given the hash of raw aggregations, returns the computed aggregations' do
    country_1 = FactoryGirl.create(:country)
    country_2 = FactoryGirl.create(:country)

    aggregations_hash = {
      'country' => {
        'doc_count'=> 169,
        'aggregation' => {
          'buckets'=> [
            {'key' => country_1.id, 'doc_count' => 64},
            {'key' => country_2.id, 'doc_count' => 17}
          ]
        }
      },
      'type_of_territory' => {
        'doc_count'=> 169,
        'buckets'=> [
          {'key' => 'T', 'doc_count' => 64},
          {'key' => 'F', 'doc_count' => 17}
        ]
      }
    }
    expected_response = {
      'country' => [{
        label: country_1.name,
        query: 'country',
        count: 64,
        identifier: country_1.id
      }, {
        label: country_2.name,
        query: 'country',
        count: 17,
        identifier: country_2.id
      }],
      'type_of_territory' => [{
        label: 'Marine',
        query: 'marine',
        count: 64,
        identifier: true
      }, {
        label: 'Terrestrial',
        query: 'marine',
        count: 17,
        identifier: false
      }]
    }

    aggregations = Search::Aggregation.parse(aggregations_hash)
    assert_equal expected_response, aggregations
  end
end
