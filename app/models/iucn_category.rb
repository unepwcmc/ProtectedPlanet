class IucnCategory < ActiveRecord::Base
  has_many :protected_areas
end
