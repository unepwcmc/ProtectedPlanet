class ProtectedArea < ActiveRecord::Base
  has_and_belongs_to_many :countries
  has_and_belongs_to_many :sub_locations

  has_many :images

  belongs_to :legal_status
  belongs_to :iucn_category
  belongs_to :governance
  belongs_to :management_authority
  belongs_to :no_take_status
  belongs_to :designation
  belongs_to :wikipedia_article

  def bounds
    rgeo_factory = RGeo::Geos.factory srid: 4326
    bounding_box = RGeo::Cartesian::BoundingBox.new rgeo_factory
    bounding_box.add the_geom

    [
      [bounding_box.min_y, bounding_box.min_x],
      [bounding_box.max_y, bounding_box.max_x]
    ]
  end
end
