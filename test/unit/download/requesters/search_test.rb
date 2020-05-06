require 'test_helper'

class DownloadRequestersSearchTest < ActiveSupport::TestCase
  test '#request starts a search download and returns token and status' do
    token = '1c6dce662e4cb3187ae5892b5db09553e54e9f638b6fd2d8a03b2ad821be64eb'
    search_term = 'tiogo'
    filters = {}

    $redis.stubs(:get).returns(nil, '{"status":"generating"}')
    $redis.stubs(:set).with("downloads:searches:#{token}", '{"status":"generating"}')
    DownloadWorkers::Search.
      expects(:perform_async).
      with(token, search_term, '{}')

    requester = Download::Requesters::Search.new search_term, filters
    assert_equal({'status' => 'generating', 'token' => token}, requester.request)
  end

  test '#request, given a search term and filters, returns an existing download when found' do
    $redis.stubs(:get).returns('{"status":"generating"}')
    DownloadWorkers::Search.expects(:perform_async).never

    Download::Requesters::Search.new('san guillermo', {}).request
  end

  test "token should depend on search term and all filters" do
    no_filter_token = Download::Requesters::Search.new('badger', {}).token
    fra_filter_token = Download::Requesters::Search.new('badger', {country: 'fra'}).token
    bra_filter_token = Download::Requesters::Search.new('badger', {country: 'bra'}).token

    assert_not_equal no_filter_token, fra_filter_token
    assert_not_equal no_filter_token, bra_filter_token
    assert_not_equal bra_filter_token, fra_filter_token
  end

  test "token should be agnostic to order of filters" do
    one_filter_token = Download::Requesters::Search.new('badger', {country: 'fra', designation: 'Conservation Area'}).token
    two_filter_token = Download::Requesters::Search.new('badger', {designation: 'Conservation Area', country: 'fra'}).token

    assert_equal one_filter_token, two_filter_token
  end



end
