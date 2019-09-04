class Designation < ApplicationRecord
  belongs_to :jurisdiction
  has_many :protected_areas
end
