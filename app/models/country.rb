class Country < ActiveRecord::Base
  has_and_belongs_to_many :protected_areas

  has_many :sub_locations
  belongs_to :region

  def bounds
    rgeo_factory = RGeo::Geos.factory srid: 4326
    bounds = RGeo::Cartesian::BoundingBox.new rgeo_factory
    if self.normalized_bounding_box?
      bounds.add normalized_bounding_box
    else 
      bounds.add bounding_box
    end
    
    [
      [bounds.min_y, bounds.min_x],
      [bounds.max_y, bounds.max_x]
    ]
  end
end
