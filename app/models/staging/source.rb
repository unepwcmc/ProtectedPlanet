module Staging
  class Source < ApplicationRecord
    self.table_name = 'staging_sources'
    self.primary_key = 'id'

    def self.protected_areas_sources_junction_table_name
      'staging_protected_areas_sources'
    end

    def self.protected_area_parcels_sources_junction_table_name
      'staging_protected_area_parcels_sources'
    end
    
    has_and_belongs_to_many :protected_areas,
      join_table: protected_areas_sources_junction_table_name,
      foreign_key: 'protected_area_id',
      association_foreign_key: 'source_id'

    has_and_belongs_to_many :protected_area_parcels,
      join_table: protected_area_parcels_sources_junction_table_name,
      foreign_key: 'protected_area_parcel_id',
      association_foreign_key: 'source_id'


  end
end
