class Source < ApplicationRecord
  has_and_belongs_to_many :protected_areas
  
  def source_hash
    {
      title: title,
      date_updated: year,
      resp_party: responsible_party
    }
  end
end
