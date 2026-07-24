require 'test_helper'

class TestSearch < ActiveSupport::TestCase
  test '#search queries ElasticSearch with the given term, and returns the matching models' do
    protected_area = FactoryGirl.create(:protected_area)
    country = FactoryGirl.create(:country)

    search_query = "manbone"

    # The full query body is asserted in search/query_test.rb and
    # search/aggregation_test.rb; here we only care that the search hits the
    # configured indices and that results are mapped back to models.

    results_object = {
      "hits" => {
        "hits" => [{
          "_index" => Search::PA_INDEX,
          "_source" => {
            "id" => protected_area.id
          }
        }, {
          "_index" => Search::COUNTRY_INDEX,
          "_source" => {
            "id" => country.id
          }
        }]
      }
    }

    search_mock = mock()
    search_mock.
      expects(:search).
      with { |args| args[:index] == Search::DEFAULT_INDEX_NAME }.
      returns(results_object)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    results = Search.search(search_query).results
    assert_equal 1, results['ProtectedArea'].length
    returned_protected_area = results['ProtectedArea'][0]
    assert_kind_of ProtectedArea, returned_protected_area
    assert_equal   protected_area.id, returned_protected_area.id

    assert_equal 1, results['Country'].length
    returned_country = results['Country'][0]
    assert_kind_of Country, returned_country
    assert_equal   country.id, returned_country.id
  end

  test '.aggregations returns all the aggregations' do
    country = FactoryGirl.create(:country)
    expected_aggregations = {
      'country' => {
        model: country.id,
        count: 59
      }
    }

    es_response = {
      'country' => {
        'doc_count'=> 169,
        'aggregation' => {
          'buckets'=> [
            {'key' => country.id, 'doc_count' => 59},
          ]
        }
      }
    }

    search_mock = mock()
    search_mock.stubs(:search).returns(es_response)
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    Search::Aggregation.expects(:parse).returns(expected_aggregations)
    assert_equal expected_aggregations, Search.search('manbone').aggregations
  end

  test '#search, given a search term and a page, offsets the
   Elasticsearch query to correctly paginate' do
    Search::Query.any_instance.stubs(:to_h).returns({})
    Search::Aggregation.stubs(:all).returns({})

    # size/from are computed as floats, and the country index boost is now 5.
    expected_query = {
      size: 20.0,
      from: 20.0,
      indices_boost: [{Search::COUNTRY_INDEX => 5}, {Search::PA_INDEX => 1} ],
      query: {},
      aggs: {}
    }

    search_mock = mock()
    search_mock.
      expects(:search).
      with(index: Search::DEFAULT_INDEX_NAME, body: expected_query)
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
    search_mock.stubs(:search).returns({"hits" => {"total" => {"value" => 400 }}})
    Elasticsearch::Client.stubs(:new).returns(search_mock)

    pages = Search.search("manbone").total_pages

    assert_equal 20, pages
  end
end
