class Network < ActiveRecord::Base
  has_many :networks_protected_areas, dependent: :destroy
  has_many :protected_areas, through: :networks_protected_areas
end
