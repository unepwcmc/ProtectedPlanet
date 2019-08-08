require 'test_helper'

class SearchAggregationTest < ActiveSupport::TestCase
  test '#all returns a hash with all aggregations configurations' do
    expected_aggregations = {
      "is_green_list" => {
        "terms" => {
          "field" => "is_green_list"
        }
      },
      "has_irreplaceability_info" => {
        "terms" => {
          "field" => "has_irreplaceability_info"
        }
      },
      "country" => {
        "nested" => {
          "path" => "countries_for_index"
        },
        "aggs" => {
          "aggregation" => {
            "terms" => {
              "field" => "countries_for_index.id",
              "size" => 500
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
              "field" => "countries_for_index.region_for_index.id",
              "size" => 500
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
              "field" => "designation.id",
              "size" => 500
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
              "field" => "iucn_category.id",
              "size" => 500
            }
          }
        }
      },
      "governance" => {
        "nested" => {
          "path" => "governance"
        },
        "aggs" => {
          "aggregation" => {
            "terms" => {
              "field" => "governance.id",
              "size" => 500
            }
          }
        }
      }
    }

    aggregations = Search::Aggregation.all

    assert_equal expected_aggregations, aggregations
  end

  test '.parse, given the hash of raw aggregations, returns the computed aggregations' do
    region = FactoryGirl.create(:region)
    designation = FactoryGirl.create(:designation)
    iucn_category = FactoryGirl.create(:iucn_category)
    governance = FactoryGirl.create(:governance)
    country_1 = FactoryGirl.create(:country)
    country_2 = FactoryGirl.create(:country)

    aggregations_hash = {
      'designation' => {
        'doc_count'=> 100,
        'aggregation' => {
          'buckets'=> [
            {'key' => designation.id, 'doc_count' => 100},
          ]
        }
      },
      'iucn_category' => {
        'doc_count'=> 100,
        'aggregation' => {
          'buckets'=> [
            {'key' => iucn_category.id, 'doc_count' => 100},
          ]
        }
      },
      'governance' => {
        'doc_count'=> 100,
        'aggregation' => {
          'buckets'=> [
            {'key' => governance.id, 'doc_count' => 100},
          ]
        }
      },
      'region' => {
        'doc_count'=> 100,
        'aggregation' => {
          'buckets'=> [
            {'key' => region.id, 'doc_count' => 100},
          ]
        }
      },
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
      },
      'has_parcc_info' => {
        'doc_count'=> 100,
        'buckets'=> [
          {'key' => 'T', 'doc_count' => 50},
          {'key' => 'F', 'doc_count' => 50}
        ]
      },
      'has_irreplaceability_info' => {
        'doc_count'=> 12,
        'buckets'=> [
          {'key' => 'T', 'doc_count' => 2},
          {'key' => 'F', 'doc_count' => 10}
        ]
      }
    }
    expected_response =
{"type_of_territory"=>[], "related_sources"=>[], "country"=>[{:identifier=>"MyText", :query=>"country", :label=>"MyText", :count=>64}, {:identifier=>"MyText", :query=>"country", :label=>"MyText", :count=>17}], "region"=>[{:identifier=>"Global", :query=>"region", :label=>"Global", :count=>100}], "designation"=>[{:identifier=>"MyString", :query=>"designation", :label=>"MyString", :count=>100}], "governance"=>[{:identifier=>"MyString", :query=>"governance", :label=>"MyString", :count=>100}], "iucn_category"=>[{:identifier=>"MyString", :query=>"iucn_category", :label=>"MyString", :count=>100}]}
    aggregations = Search::Aggregation.parse(aggregations_hash)
    assert_equal expected_response, aggregations
  end
end
