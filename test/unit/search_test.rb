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
        size: 20,
        from: 0,
        query: {
          "filtered" => {
            "query" => {
              "bool" => {
                "should" => [
                  { "nested" => { "path" => "countries_for_index", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "countries_for_index.name" ] } } } },
                  { "nested" => { "path" => "countries_for_index.region_for_index", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "countries_for_index.region_for_index.name" ] } } } },
                  { "nested" => { "path" => "sub_location", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "sub_location.english_name" ] } } } },
                  { "nested" => { "path" => "designation", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "designation.name" ] } } } },
                  { "nested" => { "path" => "iucn_category", "query" => { "fuzzy_like_this" => { "like_text" => search_query, "fields" => [ "iucn_category.name" ] } } } },
                  { "function_score" => { "query" => { "multi_match" => { "query" => "*manbone*", "fields" => [ "name", "original_name" ] } }, "functions" => [ { "filter" => { "or" => [ { "type" => { "value" => "country"} }, { "type" => { "value" => "region"} } ] }, "boost_factor" => 15 } ] } }
                ]
              }
            }
          }
        },
        aggs: {
          "country" => {
            "nested" => { "path" => "countries_for_index" },
            "aggs" => { "aggregation" => { "terms" => { "field" => "countries_for_index.id" } } }
          },
          "region" => {
            "nested" => { "path" => "countries_for_index.region_for_index" },
            "aggs" => { "aggregation" => { "terms" => { "field" => "countries_for_index.region_for_index.id" } } }
          },
          "designation" => {
            "nested" => { "path" => "designation" },
            "aggs" => { "aggregation" => { "terms" => { "field" => "designation.id" } } }
          },
          "iucn_category" => {
            "nested" => { "path" => "iucn_category" },
            "aggs" => { "aggregation" => { "terms" => { "field" => "iucn_category.id" } } }
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

  test '.aggregations returns all the aggregations' do
    countries = [
      FactoryGirl.create(:country),
      FactoryGirl.create(:country)
    ]

    search_query = "manbone"

    results_object = {
      "aggregations" => {
        "country" => {
          "doc_count" => 0,
          "aggregation" => {
            "buckets" => [
              {
                "key" => countries.first.id,
                "doc_count" => 59
              },
              {
                "key" => countries.second.id,
                "doc_count" => 10
              }
            ]
          }
        }
      }
    }

    search_mock = mock()
    search_mock.
      expects(:search).
      returns(results_object)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    aggregations = Search.search(search_query).aggregations

    country_aggregations = aggregations["country"]

    assert_equal 2, country_aggregations.length

    assert_kind_of Country, country_aggregations.first[:model]
    assert_equal   59, country_aggregations.first[:count]

    assert_kind_of Country, country_aggregations.second[:model]
    assert_equal   10, country_aggregations.second[:count]
  end

  test '.count returns the total count of the result set, rather than
   array length, so that pagination works correctly' do
    search_query = "manbone"

    results_object = {
      "hits" => {
        "total" => 42
      }
    }

    search_mock = mock()
    search_mock.
      expects(:search).
      returns(results_object)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    results_count = Search.search(search_query).count

    assert_equal 42, results_count
  end

  test '#search, given a search term and a page, offsets the
   Elasticsearch query to correctly paginate' do
    Search::Query.any_instance.stubs(:to_h).returns({})
    Search::Aggregation.stubs(:all).returns({})

    expected_query = {
      size: 20,
      from: 20,
      query: {},
      aggs: {}
    }

    search_mock = mock()
    search_mock.
      expects(:search).
      with(index: 'protected_areas', body: expected_query)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    Search.search("manbone", page: 2)
  end

  test '.current_page returns the current page number' do
    Search::Query.any_instance.stubs(:to_h).returns({})
    Search::Aggregation.stubs(:all).returns({})

    search_mock = mock()
    search_mock.stubs(:search)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    page = Search.search("manbone", page: 2).current_page

    assert_equal 2, page
  end

  test '.current_page returns 1 if the current page is not set' do
    Search::Query.any_instance.stubs(:to_h).returns({})
    Search::Aggregation.stubs(:all).returns({})

    search_mock = mock()
    search_mock.stubs(:search)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    page = Search.search("manbone").current_page

    assert_equal 1, page
  end

  test '.total_pages returns the total number of results pages' do
    Search::Query.any_instance.stubs(:to_h).returns({})
    Search::Aggregation.stubs(:all).returns({})

    search_mock = mock()
    search_mock.stubs(:search).returns({"hits" => {"total" => 400}})
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    pages = Search.search("manbone").total_pages

    assert_equal 20, pages
  end

  test '.pluck, given a property, returns the corresponding values in the EC hits' do
    hits = [
      { '_source' => {'wdpa_id' => 123, 'id' => 24} },
      { '_source' => {'wdpa_id' => 345, 'id' => 1} },
      { '_source' => {'id' => 22} }
    ]

    search_mock = mock()
    search_mock.stubs(:search).returns({ "hits" => {"hits" => hits} })
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    values = Search.search('manbone').pluck('wdpa_id')
    assert_equal [123, 345, nil], values
  end

  test '.with_coords returns all the search result models with their
   coordinates, WDPA ID and name' do
    pa_attributes = [{
      wdpa_id: 123,
      name: 'Benaffleckburg',
      the_geom_latitude: '1',
      the_geom_longitude: '-2'
    }, {
      wdpa_id: 321,
      name: 'Caseyaffleckistan',
      the_geom_latitude: '-1',
      the_geom_longitude: '0'
    }]

    benaffleckburg = FactoryGirl.create(:protected_area, pa_attributes.first)
    caseyaffleckistan = FactoryGirl.create(:protected_area, pa_attributes.second)

    results_object = {
      "hits" => {
        "hits" => [{
          "_type" => "protected_area",
          "_source" => {
            "id" => benaffleckburg.id
          }
        }, {
          "_type" => "protected_area",
          "_source" => {
            "id" => caseyaffleckistan.id
          }
        }]
      }
    }

    search_mock = mock().tap { |m| m.stubs(:search).returns(results_object) }
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    results = Search.search('affleck').with_coords

    assert_equal benaffleckburg.id, results.first.id
    assert_equal caseyaffleckistan.id, results.second.id
  end
end
