# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class ProtectedAreaSource < Base
        def self.import_to_staging(notifier: nil)
          adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
          relation = adapter.protected_area_sources_relation

          soft_errors = []
          imported_count = 0

          relation.each do |source_attributes|
            standardised_attributes = Wdpa::Portal::Utils::ProtectedAreaSourceColumnMapper.map_portal_sources_to_pp(source_attributes)
            Staging::Source.create!(standardised_attributes)
            imported_count += 1
          rescue StandardError => e
            soft_errors << "Row error: #{e.message}"
            Rails.logger.warn "Row processing failed: #{e.message}"
          end

          Rails.logger.info 'Sources imported successfully'
          notifier&.phase("#{imported_count} Sources imported")
          build_result(imported_count, soft_errors, [])
        rescue StandardError => e
          notifier&.phase("Import failed: #{e.message}")
          failure_result("Import failed: #{e.message}", 0)
        end
      end
    end
  end
end
