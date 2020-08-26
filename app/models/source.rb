class Source < ApplicationRecord
  has_and_belongs_to_many :protected_areas
end
