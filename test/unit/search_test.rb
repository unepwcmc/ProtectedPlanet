require 'test_helper'

class TestSearch < ActiveSupport::TestCase
  test '#search queries ElasticSearch with the given term, and returns the matching models' do
    protected_area = FactoryGirl.create(:protected_area)
    country = FactoryGirl.create(:country)

    search_query = "manbone"

    query_object = { :index => 'protectedareas_test,cms_test', :body => {:size => 20.0, :from => 0.0, :indices_boost => [{'countries_test' => 3}, {'protectedareas_test' => 1}], :query => {'bool' => {'must' => {'bool' => {'should' => [{'nested' => {'path' => 'sub_location', 'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['sub_location.english_name'], 'fuzziness' => '0'}}}}, {'nested' => {'path' => 'designation', 'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['designation.name'], 'fuzziness' => '0'}}}}, {'nested' => {'path' => 'iucn_category', 'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['iucn_category.name'], 'fuzziness' => '0'}}}}, {'nested' => {'path' => 'governance', 'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['governance.name'], 'fuzziness' => '0'}}}}, {'terms' => {'site_id' => []}}, {'function_score' => {'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['iso_3', 'name', 'original_name'], 'fuzziness' => '0'}}, 'boost' => '5', 'functions' => [{'filter' => {'match' => {'type' => 'country'}}, 'weight' => 20}, {'filter' => {'match' => {'type' => 'region'}}, 'weight' => 10}]}}, {'multi_match' => {'query' => 'manbone', 'fields' => ['label', 'label.english', 'label.french', 'label.spanish'], 'fuzziness' => '0'}}, {'nested' => {'path' => 'fragments_for_index', 'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['fragments_for_index.content', 'fragments_for_index.content.english', 'fragments_for_index.content.french', 'fragments_for_index.content.spanish'], 'fuzziness' => '0'}}}}, {'nested' => {'path' => 'translations_for_index.fragments_for_index', 'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['translations_for_index.fragments_for_index.content', 'translations_for_index.fragments_for_index.content.english', 'translations_for_index.fragments_for_index.content.french', 'translations_for_index.fragments_for_index.content.spanish'], 'fuzziness' => '0'}}}}, {'nested' => {'path' => 'categories', 'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['categories.label'], 'fuzziness' => '0'}}}}, {'nested' => {'path' => 'ancestors', 'query' => {'multi_match' => {'query' => 'manbone', 'fields' => ['ancestors.label'], 'fuzziness' => '0'}}}}]}}}}, :aggs => {'is_green_list' => {'terms' => {'field' => 'is_green_list'}}, 'has_irreplaceability_info' => {'terms' => {'field' => 'has_irreplaceability_info'}}, 'is_oecm' => {'terms' => {'field' => 'is_oecm'}}, 'country' => {'nested' => {'path' => 'countries_for_index'}, 'aggs' => {'aggregation' => {'terms' => {'field' => 'countries_for_index.id', 'size' => 500}}}}, 'region' => {'nested' => {'path' => 'countries_for_index.region_for_index'}, 'aggs' => {'aggregation' => {'terms' => {'field' => 'countries_for_index.region_for_index.id', 'size' => 500}}}}, 'designation' => {'nested' => {'path' => 'designation'}, 'aggs' => {'aggregation' => {'terms' => {'field' => 'designation.id', 'size' => 500}}}}, 'iucn_category' => {'nested' => {'path' => 'iucn_category'}, 'aggs' => {'aggregation' => {'terms' => {'field' => 'iucn_category.id', 'size' => 500}}}}, 'governance' => {'nested' => {'path' => 'governance'}, 'aggs' => {'aggregation' => {'terms' => {'field' => 'governance.id', 'size' => 500}}}}, 'category' => {'nested' => {'path' => 'categories'}, 'aggs' => {'aggregation' => {'terms' => {'field' => 'categories.id', 'size' => 500}}}}}}}

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
      with(query_object).
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

    expected_query = {
      size: 20,
      from: 20,
      indices_boost: [{Search::COUNTRY_INDEX => 3}, {Search::PA_INDEX => 1} ],
      query: {},
      aggs: {}
    }

    search_mock = mock()
    search_mock.
      expects(:search).
      with(index: 'protectedareas_test,cms_test', body: expected_query)
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
