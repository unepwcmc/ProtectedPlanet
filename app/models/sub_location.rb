class SubLocation < ActiveRecord::Base
  has_and_belongs_to_many :protected_areas

  belongs_to :country
end
