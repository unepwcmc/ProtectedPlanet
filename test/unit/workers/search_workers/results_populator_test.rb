require 'test_helper'

class SearchWorkersResultsPopulatorTest < ActiveSupport::TestCase
  test '.perform, given a SavedSearch id, saves all the results in
   the results_ids array field' do
    results_ids = ["1","2","3","4"]
    saved_search = FactoryGirl.create(:saved_search)

    search_mock = mock
    search_mock.stubs(:pluck).returns(results_ids)
    Search.expects(:search).returns(search_mock)

    SearchWorkers::ResultsPopulator.new.perform(saved_search.id)

    assert_same_elements results_ids, saved_search.reload.results_ids
  end
end
