class Network < ActiveRecord::Base
  has_many :networks_protected_areas
  has_many :protected_areas, through: :networks_protected_areas
end
