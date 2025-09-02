class Source < ApplicationRecord
  has_and_belongs_to_many :protected_areas

  def table_name
    "sources"
  end
end
