require 'test_helper'

class DownloadRequestersSearchTest < ActiveSupport::TestCase
  test '#request starts a search download and returns token and status' do
    search_term = 'tiogo'
    opts = {filters: {}}

    search_mock = mock
    search_mock.expects(:token).returns('123')
    search_mock.expects(:properties).returns({'status' => 'generating'})
    Search.expects(:download).with(search_term, opts).returns(search_mock)

    requester = Download::Requesters::Search.new search_term, opts
    assert_equal({status: 'generating', token: '123'}, requester.request)
  end
end
