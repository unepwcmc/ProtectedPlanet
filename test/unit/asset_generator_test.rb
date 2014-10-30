require 'test_helper'

class AssetGeneratorTest < ActiveSupport::TestCase
  test '#protected_area_tile, given a protected area without images and an
   options hash, sends a request to Mapbox and returns the content' do
    options = {size: {x: 25, y: 25}}

    response_mock = mock
    response_mock.stubs(:body).returns('the image')

    protected_area = FactoryGirl.create(:protected_area)
    protected_area.stubs(:geojson).returns('{}')

    Rails.application.secrets.
      stubs(:mapbox).
      returns({'base_url' => 'http://mapbox.com/', 'access_token' => '123'})
    Net::HTTP.expects(:get_response).
      with('mapbox.com', '/geojson({})/auto/25x25.png?access_token=123').
      returns(response_mock)

    pa_image = AssetGenerator.protected_area_tile(protected_area, options)
    assert_equal 'the image', pa_image
  end
end
