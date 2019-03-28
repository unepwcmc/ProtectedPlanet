require 'test_helper'

class DownloadRequestersSearchTest < ActiveSupport::TestCase
  test '#request starts a search download and returns token and status' do
    token = 'f6dee0d0d7e7c5ccb7b48f8539ba5fbc29648ec06ac1ebfb97d4691b1acda44a'
    search_term = 'tiogo'
    filters = {}

    $redis.stubs(:get).returns(nil, '{"status":"generating"}')
    $redis.stubs(:set).with("downloads:searches:#{token}", '{"status":"generating"}')
    DownloadWorkers::Search.
      expects(:perform_async).
      with(token, search_term, {})

    requester = Download::Requesters::Search.new search_term, filters
    assert_equal({'status' => 'generating', 'token' => token}, requester.request)
  end

  test '#request, given a search term and filters, returns an existing download when found' do
    $redis.stubs(:get).returns('{"status":"generating"}')
    DownloadWorkers::Search.expects(:perform_async).never

    Download::Requesters::Search.new('san guillermo', {}).request
  end
end
