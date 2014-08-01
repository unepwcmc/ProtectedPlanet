class Country < ActiveRecord::Base
  has_one :country_statistic

  belongs_to :region

  has_many :sub_locations
  has_many :designations, -> { uniq }, through: :protected_areas
  has_many :iucn_categories, through: :protected_areas

  has_and_belongs_to_many :protected_areas

  def bounds
    rgeo_factory = RGeo::Geos.factory srid: 4326
    bounds = RGeo::Cartesian::BoundingBox.new rgeo_factory
    bounds.add bounding_box

    [
      [bounds.min_y, bounds.min_x],
      [bounds.max_y, bounds.max_x]
    ]
  end

  def protected_areas_with_iucn_categories
    valid_categories = "'Ia', 'Ib', 'II', 'II', 'IV', 'V', 'VI'"
    iucn_categories.where(
      "iucn_categories.name IN (#{valid_categories})"
    )
  end
end
