require 'test_helper'

class AssetGeneratorTest < ActiveSupport::TestCase
  def setup
    # request_tile sets a Referer header from root_url, and the test env has no
    # default host configured for route helpers.
    Rails.application.routes.default_url_options[:host] ||= 'test.host'
    @options = {size: {x: 25, y: 25}}
    @protected_area = FactoryGirl.create(:protected_area)
    @protected_area.stubs(:geojson).returns('{}')
  end

  test '#protected_area_tile, given a protected area without images and an
   options hash, sends a request to Mapbox and returns the content' do

    response_mock = mock
    response_mock.stubs(:body).returns('the image')
    response_mock.stubs(:code).returns('200')


    AppSecrets.
      stubs(:mapbox).
      returns({'base_url' => 'http://mapbox.com/', 'access_token' => '123'})
    # The GeoJSON is URI-escaped into the path, and the request is made through a
    # Net::HTTP instance (it sets a Referer header for Mapbox's URL restrictions).
    http_mock = mock
    http_mock.stubs(:use_ssl=)
    http_mock.expects(:request).with { |req|
      req.uri.host == 'mapbox.com' &&
        req.uri.request_uri == '/geojson(%7B%7D)/auto/304x138@2x?access_token=123'
    }.returns(response_mock)
    Net::HTTP.expects(:new).with('mapbox.com', 80).returns(http_mock)

    pa_image = AssetGenerator.protected_area_tile(@protected_area)
    assert_equal 'the image', pa_image
  end

  test '#protected_area_tile, when an exception occurs during the retrieval of the
   tile, returns the fallback tile' do
    skip('no longer try to provide a backend-generated fallback image')
    response_mock = mock
    response_mock.stubs(:code).returns('404')
    Net::HTTP.stubs(:get_response).returns(response_mock)

    File.expects(:read).with(AssetGenerator::FALLBACK_PATH).returns('fallback image')

    pa_image = AssetGenerator.protected_area_tile(@protected_area)
    assert_equal 'fallback image', pa_image
  end

  test '#protected_area_tile, given a Protected Area with no geometry, returns
   the fallback tile' do
    skip('no longer try to provide a backend-generated fallback image')
    AssetGenerator.expects(:fallback_tile).returns('fallback image')

    protected_area = FactoryGirl.create(:protected_area)
    protected_area.stubs(:geojson).returns(nil)

    pa_image = AssetGenerator.protected_area_tile(protected_area)
    assert_equal 'fallback image', pa_image
  end
end
