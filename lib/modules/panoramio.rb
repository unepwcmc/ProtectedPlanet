class Panoramio
  include HTTParty

  def initialize
    self.class.base_uri "http://www.panoramio.com/map/get_panoramas.php"
    @options = {
      query: {
        set: 'public',
        size: 'square',
        from: 0,
        to: 20
      }
    }
  end

  def self.images_for_bounds bounds
    panoramio = Panoramio.new
    panoramio.images_for_bounds bounds
  end

  def images_for_bounds bounds
    query = @options[:query].merge params_from_bounds(bounds)
    response = self.class.get '', query: query

    images = JSON.parse(response.body)["photos"]
    images.map { |image| attributes_for_image(image) }
  end

  private

  def attributes_for_image image
    attributes = {}

    attributes[:title]       = image["photo_title"]
    attributes[:url]         = image["photo_file_url"]
    attributes[:details_url] = image["photo_url"]

    latitude = image["latitude"]
    longitude = image["longitude"]
    attributes[:lonlat] = point_from_lon_lat(
      longitude, latitude
    )

    attributes
  end

  def point_from_lon_lat longitude, latitude
    RGeo::Geographic.spherical_factory(:srid => 4326).
      point(longitude, latitude)
  end

  def params_from_bounds bounds
    {
      miny: bounds[0][0],
      minx: bounds[0][1],

      maxy: bounds[1][0],
      maxx: bounds[1][1]
    }
  end
end
