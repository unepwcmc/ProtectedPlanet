class Source < ApplicationRecord
  def self.protected_areas_sources_junction_table_name
    'protected_areas_sources'
  end

  def self.protected_area_parcels_sources_junction_table_name
    'protected_area_parcels_sources'
  end
  
  has_and_belongs_to_many :protected_areas
  has_and_belongs_to_many :protected_area_parcels


end
