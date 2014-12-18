require 'test_helper'

class DownloadsControllerTest < ActionController::TestCase
  test 'GET :show responds with a json containing the link to s3, when domain is general' do
    type = 'csv'
    country = FactoryGirl.create(:country, iso_3: 'CAN')
    link = "https://bucket.s3.com/#{country.iso_3}.#{type}"

    Download.expects(:link_to).returns(link)

    get :show, id: country.iso_3, type: type, domain: :general
    assert_redirected_to link
  end

  test 'POST :create, given a search term and filters, initiates a download generation' do
    search_term = 'manbone'
    token = '12345'
    expected_json = {'status' => 'generating', 'token' => token}

    Download.expects(:request).
      with('q' => search_term, 'type' => 'protected_area', 'controller' => 'downloads', 'action' => 'create').
      returns(expected_json)

    post :create, q: search_term, type: 'protected_area'

    json_response = JSON.parse(@response.body)
    assert_equal(expected_json, json_response)
  end

  test 'GET :poll, given a token, returns the properties of the given download' do
    token = '12345'
    expected_json = {'status' => 'generating', 'token' => token}

    Download.expects(:poll).
      with('domain' => 'project', 'token' => '12345', 'controller' => 'downloads', 'action' => 'poll').
      returns(expected_json)

    get :poll, domain: 'project', token: token

    json_response = JSON.parse(@response.body)
    assert_equal(expected_json, json_response)
  end

  test 'PUT :update, given a token and an email, adds a users email
   address to the Search properties' do
    token = '12345'
    email = 'stephen@fakename.com'

    Download.expects(:set_email).with({
      'id' => token,
      'email' => email,
      'action' => 'update',
      'controller' => 'downloads'
    })

    put :update, id: token, email: email

    assert_response :success
  end
end
