require 'test_helper'

class DownloadRequestersSearchTest < ActiveSupport::TestCase
  test '#request starts a search download and returns token and status' do
    format = 'shp'
    search_term = 'tiogo'
    filters = {}

    requester = Download::Requesters::Search.new format, search_term, filters
    # Derive the token from the requester rather than hard-coding the digest, so
    # the test tracks Download::Utils.search_token instead of going stale.
    token = requester.token

    $redis.stubs(:get).returns(nil, '{"status":"generating"}')
    # enqueue_generation_once only yields if it wins the redis lock (SET NX).
    $redis.stubs(:set).returns(true)
    DownloadWorkers::Search.
      expects(:perform_async).
      with(format, token, search_term, '{}')

    response = requester.request

    assert_equal "#{token}-#{format}", response['id']
    assert_equal token, response['token']
  end

  test '#request, given a search term and filters, returns an existing download when found' do
    $redis.stubs(:get).returns('{"status":"generating"}')
    DownloadWorkers::Search.expects(:perform_async).never

    Download::Requesters::Search.new('shp', 'san guillermo', {}).request
  end

  test "token should depend on search term and all filters" do
    no_filter_token = Download::Requesters::Search.new('csv', 'badger',{}).token
    fra_filter_token = Download::Requesters::Search.new('csv', 'badger',{country: 'fra'}).token
    bra_filter_token = Download::Requesters::Search.new('csv', 'badger',{country: 'bra'}).token

    assert_not_equal no_filter_token, fra_filter_token
    assert_not_equal no_filter_token, bra_filter_token
    assert_not_equal bra_filter_token, fra_filter_token
  end

  test "token should be agnostic to order of filters" do
    one_filter_token = Download::Requesters::Search.new('csv', 'badger',{country: 'fra', designation: 'Conservation Area'}).token
    two_filter_token = Download::Requesters::Search.new('csv', 'badger',{designation: 'Conservation Area', country: 'fra'}).token

    assert_equal one_filter_token, two_filter_token
  end



end
