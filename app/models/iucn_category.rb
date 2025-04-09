class IucnCategory < ApplicationRecord
  has_many :protected_areas
  has_many :protected_area_parcels
end
