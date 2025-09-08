# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      module ProtectedArea
        extend Base
        def self.perform_import
          Rails.logger.info 'Starting comprehensive protected area import to staging tables...'

          start_time = Time.current
          attributes_result = import_attributes
          geometry_result = import_geometries
          related_sources_result = import_related_sources

          duration_hours = (Time.current - start_time) / 3600.0
          Rails.logger.info "Protected Area Import completed in #{duration_hours.round(2)} hours"

          # Merge all errors
          all_errors = merge_errors([attributes_result, geometry_result, related_sources_result])

          {
            imported_count: 0, # Complex importers don't have simple count
            soft_errors: all_errors[:soft_errors],
            hard_errors: all_errors[:hard_errors],
            additional_fields: {
              duration_hours: duration_hours.round(2),
              protected_areas_attributes: attributes_result,
              protected_areas_geometries: geometry_result,
              protected_areas_related_sources: related_sources_result
            }
          }
        end

        private

        def self.import_attributes
          result = Wdpa::Portal::Importers::ProtectedArea::Attribute.import_staging
          Rails.logger.info "✓ Attributes imported: #{result[:imported_count]} records"
          result
        rescue StandardError => e
          error_msg = "Failed to import protected area attributes: #{e.message}"
          Rails.logger.error error_msg
          failure_result(error_msg)
        end

        def self.import_geometries
          result = Wdpa::Portal::Importers::ProtectedArea::Geometry.import_staging
          Rails.logger.info "✓ Geometries imported: #{result[:imported_count]} records"
          result
        rescue StandardError => e
          error_msg = "Failed to import protected area geometries: #{e.message}"
          Rails.logger.error error_msg
          failure_result(error_msg)
        end

        def self.import_related_sources
          result = Wdpa::Shared::Importer::ProtectedAreasRelatedSource.import_staging

          Rails.logger.info "✓ PARCC imported: #{result[:parcc][:imported_count]} records"
          Rails.logger.info "✓ Irreplaceability imported: #{result[:irreplaceability][:imported_count]} records"
          result
        rescue StandardError => e
          error_msg = "Failed to import related protected area sources (parcc and irreplaceability): #{e.message}"
          Rails.logger.error error_msg
          {
            parcc: failure_result(error_msg),
            irreplaceability: failure_result(error_msg)
          }
        end

        private_class_method :import_attributes, :import_geometries, :import_related_sources
      end
    end
  end
end
