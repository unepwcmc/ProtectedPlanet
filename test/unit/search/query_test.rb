require 'test_helper'

class SearchQueryTest < ActiveSupport::TestCase
  test '.to_h, given a search term, returns an ElasticSearch query, with
   aggregations' do
    term = "manbone"

    expected_object = {
      "filtered" => {
        "query" => {
          "bool" => {
            "should" => [
              {
                "nested" => {
                  "path" => "countries",
                  "query" => { "fuzzy_like_this" => { "like_text" => "manbone", "fields" => [ "countries.name" ] } }
                }
              },
              {
                "nested" => {
                  "path" => "countries.region",
                  "query" => { "fuzzy_like_this" => { "like_text" => "manbone", "fields" => [ "countries.region.name" ] } }
                }
              },
              {
                "nested" => {
                  "path" => "sub_location",
                  "query" => { "fuzzy_like_this" => { "like_text" => "manbone", "fields" => [ "sub_location.english_name" ] } }
                }
              },
              {
                "nested" => {
                  "path" => "designation",
                  "query" => { "fuzzy_like_this" => { "like_text" => "manbone", "fields" => [ "designation.name" ] } }
                }
              },
              {
                "nested" => {
                  "path" => "iucn_category",
                  "query" => { "fuzzy_like_this" => { "like_text" => "manbone", "fields" => [ "iucn_category.name" ] } }
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
                  "functions" => [
                    {
                      "filter" => {
                        "or" => [
                          { "type" => { "value" => "country"} },
                          { "type" => { "value" => "region"} }
                        ]
                      },
                      "boost_factor" => 15
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
      "and" => [
        "type" => {
          "value" => type
        }
      ]
    }

    query = Search::Query.new(term, filters: [{name: 'type', value: 'country'}]).to_h
    filters = query["filtered"]["filter"]

    assert_equal expected_object, filters
  end
end
