module Wdpa
  module Portal
    module Importers
      class SourceImporter
        def self.import

          adapter = Wdpa::Portal::Adapters::ImportTablesAdapter.new
          relation = adapter.sources_relation
          
          imported_count = 0
          errors = []

          relation.find_each do |source_attributes|
            begin
              standardised_attributes = standardize_source_attributes(source_attributes)
              StagingSource.create!(standardised_attributes)
              imported_count += 1
            rescue => e
              errors << "Source import error: #{e.message}"
              Rails.logger.warn("Source import failed: #{e.message}")
            end
          end

          {
            success: errors.empty?,
            imported_count: imported_count,
            errors: errors
          }
        end

        private

        def self.standardize_source_attributes(source_attributes)
          # Use the ColumnMapper system for consistent field mapping and transformation
          # This follows the same pattern as AttributeImporter.standardize_attributes
          Wdpa::Portal::Utils::ColumnMapper.map_portal_sources_to_pp(source_attributes)
        end
      end
    end
  end
end
