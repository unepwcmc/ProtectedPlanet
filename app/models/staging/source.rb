module Staging
  class Source < ApplicationRecord
    self.table_name = 'staging_sources'

    has_and_belongs_to_many :staging_protected_areas

    def self.protected_areas_sources_junction_table_name
      'staging_protected_areas_sources'
    end 

    def self.protected_area_parcels_sources_junction_table_name
      'staging_protected_area_parcels_sources'
    end
  end
end
