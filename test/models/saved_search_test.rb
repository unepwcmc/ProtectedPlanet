require 'test_helper'

class SavedSearchTest < ActiveSupport::TestCase
  test '::create_and_populate creates a new SavedSearch instance and
   starts the SearchWorkers::ResultsPopulator worker' do
    params = {search_term: 'san guillermo', filters: '{}'}
    search_mock_id = 123
    search_mock = mock
    search_mock.expects(:id).returns(search_mock_id)

    SavedSearch.expects(:create!).returns(search_mock).with(params)
    SearchWorkers::ResultsPopulator.expects(:perform_async).with(search_mock_id)

    SavedSearch.create_and_populate params
  end
end
