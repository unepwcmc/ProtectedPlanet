class StagingSource < ApplicationRecord
  self.table_name = "staging_sources"
  
  has_and_belongs_to_many :staging_protected_areas
end
