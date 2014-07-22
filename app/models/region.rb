class Region < ActiveRecord::Base
  has_many :countries
  has_one :regional_statistic

  def bounds
    rgeo_factory = RGeo::Geos.factory srid: 4326
    bounds = RGeo::Cartesian::BoundingBox.new rgeo_factory
    bounds.add bounding_box

    [
      [bounds.min_y, bounds.min_x],
      [bounds.max_y, bounds.max_x]
    ]
  end
end
