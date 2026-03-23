class GreenListStatus < ApplicationRecord
  has_one :protected_area
  has_one :protected_area_parcel
end
