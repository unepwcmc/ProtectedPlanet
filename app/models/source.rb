class Source < ApplicationRecord
  has_and_belongs_to_many :protected_areas
  
  def source_json
    self.as_json(
      only: [:title, :year, :responsible_party]
    )
  end
end
