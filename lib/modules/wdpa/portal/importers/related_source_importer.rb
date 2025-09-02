module Wdpa
  module Portal
    module Importers
      class RelatedSourceImporter
        def self.import
          # Execute both imports and return results
          parcc_result = parcc_import
          irreplaceability_result = irreplaceability_import
          
          {
            parcc: parcc_result,
            irreplaceability: irreplaceability_result
          }
        end

        def self.parcc_import
          # Use shared service with same configuration as GDB
          Wdpa::Shared::RelatedSourceImporter.parcc_import(
            target_table: Wdpa::Portal::Config::StagingConfig.get_staging_table_name_from_live_table('protected_areas')
          )
        end

        def self.irreplaceability_import
          # Use shared service with same configuration as GDB
          Wdpa::Shared::RelatedSourceImporter.irreplaceability_import(
            target_table: Wdpa::Portal::Config::StagingConfig.get_staging_table_name_from_live_table('protected_areas')
          )
        end
      end
    end
  end
end
