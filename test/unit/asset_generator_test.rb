require 'test_helper'

class AssetGeneratorTest < ActiveSupport::TestCase
  def setup
    @options = {size: {x: 25, y: 25}}
    @protected_area = FactoryGirl.create(:protected_area)
    @protected_area.stubs(:geojson).returns('{}')
  end

  test '#protected_area_tile, given a protected area without images and an
   options hash, sends a request to Mapbox and returns the content' do

    response_mock = mock
    response_mock.stubs(:body).returns('the image')
    response_mock.stubs(:code).returns('200')

    Rails.application.secrets.
      stubs(:mapbox).
      returns({'base_url' => 'http://mapbox.com/', 'access_token' => '123'})
    Net::HTTP.expects(:get_response).
      with('mapbox.com', '/geojson({})/auto/25x25@2x.png?access_token=123').
      returns(response_mock)

    pa_image = AssetGenerator.protected_area_tile(@protected_area, @options)
    assert_equal 'the image', pa_image
  end

  test '#protected_area_tile, when an exception occurs during the retrieval of the
   tile, returns the fallback tile' do
    response_mock = mock
    response_mock.stubs(:code).returns('404')
    Net::HTTP.stubs(:get_response).returns(response_mock)

    File.expects(:read).with(AssetGenerator::FALLBACK_PATH).returns('fallback image')

    pa_image = AssetGenerator.protected_area_tile(@protected_area, @options)
    assert_equal 'fallback image', pa_image
  end
end
