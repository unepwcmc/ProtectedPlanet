require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test '.index returns a 200 HTTP code' do
    get :index
    assert_response :success
  end

  test 'GET :index, given a query, searches for that query' do
    search_term = 'manbone'

    results = [
      FactoryGirl.create(:protected_area)
    ]
    results_mock = mock()
    results_mock.stubs(:results).returns(results)
    results_mock.stubs(:aggregations).returns([])
    results_mock.stubs(:total_pages).returns(0)
    results_mock.stubs(:current_page).returns(0)
    results_mock.stubs(:count).returns(0)

    Search.
      expects(:search).
      with(search_term, {filters: {}}).
      returns(results_mock)

    get :index, q: search_term

    assert_response :success
    assert_equal results_mock, assigns(:search)
  end

  test 'GET :index, given a query and a type filter, search for that
   query with the filter option' do
    search_term = 'manbone'

    results = [
      FactoryGirl.create(:protected_area)
    ]
    results_mock = mock()
    results_mock.stubs(:results).returns(results)
    results_mock.stubs(:aggregations).returns([])
    results_mock.stubs(:total_pages).returns(0)
    results_mock.stubs(:current_page).returns(0)
    results_mock.stubs(:count).returns(0)

    Search.
      expects(:search).
      with(search_term, {filters: {'type' => 'country'}}).
      returns(results_mock)

    get :index, q: search_term, type: 'country'

    assert_response :success
  end

  test 'GET :index, given a search term and a page number, paginates the
   results' do
    search_term = 'manbone'

    results_mock = mock()
    results_mock.stubs(:results).returns([])
    results_mock.stubs(:total_pages).returns(0)
    results_mock.stubs(:current_page).returns(0)
    results_mock.stubs(:aggregations).returns([])
    results_mock.stubs(:count).returns(0)

    Search.
      expects(:search).
      with(search_term, {filters: {}, page: 2}).
      returns(results_mock)

    get :index, q: search_term, page: 2

    assert_response :success
  end
end
