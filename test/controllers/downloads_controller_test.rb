require 'test_helper'

class DownloadsControllerTest < ActionController::TestCase
  test '#show redirects to the S3 bucket URL for the provided country ISO3 and
   type' do
    type = 'csv'
    country = FactoryGirl.create(:country, iso_3: 'CAN')
    link = "https://bucket.s3.com/#{country.iso_3}.#{type}"

    Download.expects(:link_to).returns(link)

    get :show, iso_3: country.iso_3, type: type
    assert_redirected_to link
  end

  test 'POST :create, given a search term, initiates a download generation' do
    search_term = 'manbone'
    options = {filters: {'type' => 'protected_area'}}
    token = '12345'

    search_mock = mock
    search_mock.stubs(:token).returns(token)
    Search.expects(:download).with(search_term, options).returns(search_mock)


    post :create, q: search_term, type: 'protected_area'

    json_response = JSON.parse(@response.body)
    assert_equal({'token' => token}, json_response)
  end
end
