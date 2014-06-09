class Designation < ActiveRecord::Base
  belongs_to :jurisdiction
  has_many :protected_areas
end
