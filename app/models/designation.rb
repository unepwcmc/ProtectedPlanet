class Designation < ApplicationRecord
  belongs_to :jurisdiction
  has_many :protected_areas
  has_many :protected_area_parcels
end
