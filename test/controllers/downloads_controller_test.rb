require 'test_helper'

class DownloadsControllerTest < ActionController::TestCase
  test '#show redirects to the S3 bucket URL for the provided country ISO3 and
   type' do
    type = 'csv'
    country = FactoryGirl.create(:country, iso_3: 'CAN')
    link = "https://bucket.s3.com/#{country.iso_3}.#{type}"

    Download.expects(:link_to).returns(link)

    get :show, id: country.iso_3, type: type
    assert_redirected_to link
  end
end
