require 'test_helper'

class DownloadRouterTest < ActiveSupport::TestCase

  def setup
    Rails.cache.clear
  end

  test '.request, called with search domain and an hash of parameters, sends a
   request to the correct requester' do
    expected_response = {'status' => 'generating', 'token' => '123'}
    domain = 'search'
    params = {'format' => 'csv', 'q' => 'san guillermo', 'filters' => {}}

    Download::Requesters::Search.expects(:request).
      with('csv', 'san guillermo', {}).
      returns(expected_response)

    assert_equal expected_response, Download::Router.request(domain, params)
  end

  test '.request, called with general domain and an hash of parameters, sends a
   request to the correct requester' do
    expected_response = {'status' => 'ready', 'token' => '123'}
    domain = 'general'
    params = {'format' => 'csv', 'id' => 'USA'}

    Download::Requesters::General.expects(:request).
      with('csv', 'USA').
      returns(expected_response)

    assert_equal expected_response, Download::Router.request(domain, params)
  end

  test '.set_email, called with a domain and params including an email, sets
   the email in the properties of the given token' do
    domain = 'general'
    params = {'id' => '123', 'email' => 'test@test.com'}

    $redis.expects(:set).with('downloads:general:123', regexp_matches(/test@test.com/))

    Download::Router.set_email(domain, params)
  end
end
