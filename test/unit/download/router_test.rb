require 'test_helper'

class DownloadRouterTest < ActiveSupport::TestCase

  def setup
    Rails.cache.clear
  end

  test '.request, called with search domain and an hash of parameters, sends a
   request to the correct requester' do
    expected_response = {'status' => 'generating', 'token' => '123'}
    domain = 'search'
    # the router reads the search term from params['search']
    params = {'format' => 'csv', 'search' => 'san guillermo', 'filters' => {}}

    Download::Requesters::Search.expects(:request).
      with('csv', 'san guillermo', {}).
      returns(expected_response)

    assert_equal expected_response, Download::Router.request(domain, params)
  end

  test '.request, called with general domain and an hash of parameters, sends a
   request to the correct requester' do
    expected_response = {'status' => 'ready', 'token' => '123'}
    domain = 'general'
    # the router reads the identifier from params['token']
    params = {'format' => 'csv', 'token' => 'USA'}

    Download::Requesters::General.expects(:request).
      with('csv', 'USA').
      returns(expected_response)

    assert_equal expected_response, Download::Router.request(domain, params)
  end

  test '.set_email, called with a domain and params including an email, sets
   the email in the properties of the given token' do
    domain = 'general'
    # Download::Utils.key now includes the format segment
    params = {'id' => '123', 'email' => 'test@test.com', 'format' => 'csv'}

    $redis.expects(:set).with('downloads:general:csv:123', regexp_matches(/test@test.com/))

    Download::Router.set_email(domain, params)
  end
end
