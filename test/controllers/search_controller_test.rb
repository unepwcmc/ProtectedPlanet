require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    @user = FactoryGirl.create(:user)
    sign_in @user
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
    results_mock.stubs(:search_term).returns(search_term)
    results_mock.stubs(:options).returns({filters: {}})

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
    results_mock.stubs(:search_term).returns(search_term)
    results_mock.stubs(:options).returns({filters: {}})

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
    results_mock.stubs(:search_term).returns(search_term)
    results_mock.stubs(:options).returns({filters: {}})

    Search.
      expects(:search).
      with(search_term, {filters: {}, page: 2}).
      returns(results_mock)

    get :index, q: search_term, page: 2

    assert_response :success
  end

  test 'GET :map, given a search term, returns success' do
    search_term = 'manbone'

    results_mock = mock()
    results_mock.stubs(:results).returns([])
    results_mock.stubs(:total_pages).returns(0)
    results_mock.stubs(:current_page).returns(0)
    results_mock.stubs(:aggregations).returns([])
    results_mock.stubs(:count).returns(0)
    results_mock.stubs(:search_term).returns(search_term)
    results_mock.stubs(:options).returns({filters: {}})

    Search.expects(:search).with(search_term, {filters: {}}).returns(results_mock)

    get :map, q: search_term

    assert_response :success
  end

  test 'POST :create, given a search term, filters, and a project id,
   creates a Search object linked to the given project' do
    search_term = 'san guillermo'

    @project = FactoryGirl.create(:project, user: @user)
    assert_difference('SavedSearch.count', 1) do
      post :create, search_term: search_term, project_id: @project.id
    end

    assert_equal @project, SavedSearch.last.project
  end
end
