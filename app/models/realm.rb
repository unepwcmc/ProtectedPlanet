class Realm < ApplicationRecord
  has_many :protected_areas
  has_many :protected_area_parcels

  has_many :staging_protected_areas, class_name: 'Staging::ProtectedArea'
  has_many :staging_protected_area_parcels, class_name: 'Staging::ProtectedAreaParcel'
end
