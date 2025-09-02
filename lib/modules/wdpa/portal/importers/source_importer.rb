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
            standardised_attributes = Wdpa::Portal::Utils::ColumnMapper.map_portal_sources_to_pp(source_attributes)
            Staging::Source.create!(standardised_attributes)
            imported_count += 1
          rescue StandardError => e
            errors << "Source import error: #{e.message}"
            Rails.logger.warn("Source import failed: #{e.message}")
          end

          {
            success: errors.empty?,
            imported_count: imported_count,
            errors: errors
          }
        end
      end
    end
  end
end
