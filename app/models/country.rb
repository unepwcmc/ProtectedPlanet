class Country < ActiveRecord::Base
  has_and_belongs_to_many :protected_areas

  has_many :sub_locations
end
