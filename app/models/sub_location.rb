class SubLocation < ApplicationRecord
  has_and_belongs_to_many :protected_areas
  has_and_belongs_to_many :protected_area_parcels

  belongs_to :country
end
