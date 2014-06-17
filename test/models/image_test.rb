require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  test '#for_bounds returns Panoramio images for the given bounds array' do
    bounds = [[0, -1], [2, 1]]

    image_attributes = [{
      title: 'An image',
      url: 'http://panoramio.com/an-image.gif',
      lonlat: RGeo::Geographic.spherical_factory(:srid => 4326).point(1, 1)
    }]

    Panoramio.expects(:images_for_bounds).
      with(bounds).
      returns(image_attributes)

    images = Image.for_bounds bounds

    assert_not_nil images, "Expected #for_bounds to return an array"
    assert_equal   1, images.count

    image = images.first

    assert_kind_of Image, image
    assert_equal   'http://panoramio.com/an-image.gif', image.url
  end
end
