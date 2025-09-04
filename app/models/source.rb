class Source < ApplicationRecord
  has_and_belongs_to_many :protected_areas

  def self.protected_areas_sources_junction_table_name
    'protected_areas_sources'
  end

  def self.protected_area_parcels_sources_junction_table_name
    'protected_area_parcels_sources'
  end
end
