require 'test_helper'

class PanoramioTest < ActiveSupport::TestCase
  test '.new assigns an options object with the default params and the base uri' do
    panoramio = Panoramio.new

    query = panoramio.instance_variable_get(:@options)[:query]

    assert_equal({set: 'public', size: 'square', from: 0, to: 20}, query)
    assert_equal "http://www.panoramio.com/map/get_panoramas.php", Panoramio.base_uri
  end

  test '#images_for_bounds returns image attributes for the given bounds' do
    bounds = [[0, -1], [2, 1]]

    attributes = {
      "photo_file_url" => 'http://google.com/image.gif',
      "photo_title" => "An photo",
      "longitude" => 11.280727,
      "latitude" => 59.643198
    }

    query = {
      set: 'public',
      size: 'square',
      from: 0,
      to: 20,
      miny: 0,
      minx: -1,
      maxy: 2,
      maxx: 1
    }

    stub_request(:get, 'http://www.panoramio.com/map/get_panoramas.php').
      with({query: query}).
      to_return(:status => 200, :body => {"photos" => [attributes]}.to_json)

    images = Panoramio.images_for_bounds bounds

    assert_not_nil images, "Expected #images_for_bounds to return an array"
    assert_equal   1, images.count

    image = images.first

    assert_equal attributes["photo_title"], image[:title]
    assert_equal attributes["photo_file_url"], image[:url]

    latitude = attributes["latitude"]
    longitude = attributes["longitude"]
    assert_equal "POINT (#{longitude} #{latitude})", image[:lonlat].to_s
  end
end
