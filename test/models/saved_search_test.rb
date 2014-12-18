require 'test_helper'

class SavedSearchTest < ActiveSupport::TestCase
  test '.wdpa_ids executes a search and returns all wdpa_ids' do
    results_ids = [1,2,3,4]
    saved_search = FactoryGirl.create(:saved_search)

    search_mock = mock
    results_mock = mock
    results_mock.stubs(:pluck).returns(results_ids)
    search_mock.stubs(:results).returns(results_mock)

    Search.expects(:search).returns(search_mock)

    assert_same_elements results_ids, saved_search.wdpa_ids
  end
end
