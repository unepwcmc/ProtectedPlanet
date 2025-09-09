# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class Source < Base
        def self.import_to_staging
          adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
          relation = adapter.sources_relation

          soft_errors = []
          imported_count = 0

          relation.each do |source_attributes|
            standardised_attributes = Wdpa::Portal::Utils::ColumnMapper.map_portal_sources_to_pp(source_attributes)
            Staging::Source.create!(standardised_attributes)
            imported_count += 1
          rescue StandardError => e
            soft_errors << "Row error: #{e.message}"
            Rails.logger.warn "Row processing failed: #{e.message}"
          end

          success_result(imported_count, soft_errors, [])
        rescue StandardError => e
          failure_result("Import failed: #{e.message}", 0)
        end
      end
    end
  end
end
