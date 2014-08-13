require 'test_helper'

class TestSearch < ActiveSupport::TestCase
  test '#search queries ElasticSearch with the given term, and returns
   the matching models' do
    protected_area = FactoryGirl.create(:protected_area)
    country = FactoryGirl.create(:country)

    search_query = "manbone"

    query_object = {
      index: 'protected_areas',
      body: {
        size: 10,
        query: {
          "filtered" => {
            "query" => {
              "bool" => {
                "should" => [
                  { "nested" => { "path" => "countries", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "countries.name" ] } } } },
                  { "nested" => { "path" => "countries.region", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "countries.region.name" ] } } } },
                  { "nested" => { "path" => "sub_location", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "sub_location.english_name" ] } } } },
                  { "nested" => { "path" => "designation", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "designation.name" ] } } } },
                  { "nested" => { "path" => "iucn_category", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "iucn_category.name" ] } } } },
                  { "multi_match" => { "query" => "*#{search_query}*", "fields" => [ "name", "original_name" ] } }
                ]
              }
            }
          }
        }
      }
    }

    results_object = {
      "hits" => {
        "hits" => [{
          "_type" => "protected_area",
          "_source" => {
            "id" => protected_area.id
          }
        }, {
          "_type" => "country",
          "_source" => {
            "id" => country.id
          }
        }]
      }
    }

    search_mock = mock()
    search_mock.
      expects(:search).
      with(query_object).
      returns(results_object)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    results = Search.search(search_query).results
    assert 2, results.length

    returned_protected_area = results.first
    assert_kind_of ProtectedArea, returned_protected_area
    assert_equal   protected_area.id, returned_protected_area.id

    returned_country = results.second
    assert_kind_of Country, returned_country
    assert_equal   country.id, returned_country.id
  end
end
