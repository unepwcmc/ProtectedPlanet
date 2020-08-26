class Source < ApplicationRecord
  has_and_belongs_to_many :protected_areas
  
  def source_hash
    {
      title: title,
      # TODO - sources which have no data for `date_updated` are currently set to '-' 
      date_updated: year ? year.strftime('%Y') : '-',
      resp_party: responsible_party
    }
  end
end
