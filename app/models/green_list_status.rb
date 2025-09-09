class GreenListStatus < ApplicationRecord
  has_one :protected_area

  validates :status, uniqueness: { scope: :expiry_date }
end
