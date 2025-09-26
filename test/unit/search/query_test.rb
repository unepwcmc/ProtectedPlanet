require 'test_helper'

class SearchQueryTest < ActiveSupport::TestCase
  test '.to_h, given a search term, returns an ElasticSearch query, with
   aggregations' do
    term = "manbone"

    expected_object = {"bool"=>{"must"=>{"bool"=>{"should"=>[{"nested"=>{"path"=>"designation", "query"=>{"multi_match"=>{"query"=>"manbone", "fields"=>["designation.name"], "fuzziness"=>"0"}}}}, {"nested"=>{"path"=>"iucn_category", "query"=>{"multi_match"=>{"query"=>"manbone", "fields"=>["iucn_category.name"], "fuzziness"=>"0"}}}}, {"nested"=>{"path"=>"governance", "query"=>{"multi_match"=>{"query"=>"manbone", "fields"=>["governance.name"], "fuzziness"=>"0"}}}}, {"terms"=>{"site_id"=>[]}}, {"function_score"=>{"query"=>{"multi_match"=>{"query"=>"manbone", "fields"=>["iso_3", "name", "original_name"], "fuzziness"=>"0"}}, "boost"=>"5", "functions"=>[{"filter"=>{"match"=>{"type"=>"country"}}, "weight"=>20}, {"filter"=>{"match"=>{"type"=>"region"}}, "weight"=>10}]}}, {"multi_match"=>{"query"=>"manbone", "fields"=>["label", "label.english", "label.french", "label.spanish"], "fuzziness"=>"0"}}, {"nested"=>{"path"=>"fragments_for_index", "query"=>{"multi_match"=>{"query"=>"manbone", "fields"=>["fragments_for_index.content", "fragments_for_index.content.english", "fragments_for_index.content.french", "fragments_for_index.content.spanish"], "fuzziness"=>"0"}}}}, {"nested"=>{"path"=>"translations_for_index.fragments_for_index", "query"=>{"multi_match"=>{"query"=>"manbone", "fields"=>["translations_for_index.fragments_for_index.content", "translations_for_index.fragments_for_index.content.english", "translations_for_index.fragments_for_index.content.french", "translations_for_index.fragments_for_index.content.spanish"], "fuzziness"=>"0"}}}}, {"nested"=>{"path"=>"categories", "query"=>{"multi_match"=>{"query"=>"manbone", "fields"=>["categories.label"], "fuzziness"=>"0"}}}}, {"nested"=>{"path"=>"ancestors", "query"=>{"multi_match"=>{"query"=>"manbone", "fields"=>["ancestors.label"], "fuzziness"=>"0"}}}}]}}}}

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
    expected_filters = {"bool"=>{"must"=>{"bool"=>{"should"=>[{"nested"=>{"path"=>"designation", "query"=>{"match_all"=>{}}}}, {"nested"=>{"path"=>"iucn_category", "query"=>{"match_all"=>{}}}}, {"nested"=>{"path"=>"governance", "query"=>{"match_all"=>{}}}}, {"terms"=>{"site_id"=>[]}}, {"function_score"=>{"query"=>{"match_all"=>{}}, "boost"=>"5", "functions"=>[{"filter"=>{"match"=>{"type"=>"country"}}, "weight"=>20}, {"filter"=>{"match"=>{"type"=>"region"}}, "weight"=>10}]}}, {"match_all"=>{}}, {"nested"=>{"path"=>"fragments_for_index", "query"=>{"match_all"=>{}}}}, {"nested"=>{"path"=>"translations_for_index.fragments_for_index", "query"=>{"match_all"=>{}}}}, {"nested"=>{"path"=>"categories", "query"=>{"match_all"=>{}}}}, {"nested"=>{"path"=>"ancestors", "query"=>{"match_all"=>{}}}}]}}, "filter"=>{"bool"=>{"must"=>[{"bool"=>{"should"=>[{"geo_distance"=>{"distance"=>"2000km", "protected_area.coordinates"=>{"lon"=>-69.0, "lat"=>-29.0}}}]}}]}}}}

    query = Search::Query.new('', filters: {location: {coords: [-69, -29]}}).to_h

    assert_equal expected_filters, query
  end
end
