class LegalStatus < ApplicationRecord
  has_many :protected_areas
  has_many :protected_area_parcels
end
