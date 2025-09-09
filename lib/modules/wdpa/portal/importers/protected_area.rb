# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class ProtectedArea < Base
        def self.import_to_staging
          Rails.logger.info 'Starting comprehensive protected area import to staging tables...'

          start_time = Time.current
          attributes_result = import_attributes
          geometry_result = import_geometries

          # Only run related sources if no hard errors from previous imports
          related_sources_result = if attributes_result[:hard_errors].empty? && geometry_result[:protected_areas][:hard_errors].empty? && geometry_result[:protected_area_parcels][:hard_errors].empty?
                                     import_related_sources
                                   else
                                    error_msg = 'Skipping related sources import due to hard errors in attributes or geometry imports'
                                     Rails.logger.warn error_msg
                                     {
                                       parcc: failure_result(error_msg, 0),
                                       irreplaceability: failure_result(error_msg, 0)
                                     }
                                   end

          duration_hours = (Time.current - start_time) / 3600.0
          has_hard_errors = attributes_result[:hard_errors].any? ||
          geometry_result[:protected_areas][:hard_errors].any? || 
          geometry_result[:protected_area_parcels][:hard_errors].any? ? ["Hard errors detected in the protected area import"] : []
          Rails.logger.info "Protected Area Import completed in #{duration_hours.round(2)} hours"

          {
            hard_errors: has_hard_errors,
            duration_hours: duration_hours.round(2),
            protected_areas_attributes: attributes_result,
            protected_areas_geometries: geometry_result,
            related_sources_result: related_sources_result
          }
        end

        private

        def self.import_attributes
          result = Wdpa::Portal::Importers::ProtectedArea::Attribute.import_to_staging
          Rails.logger.info "✓ Attributes imported: #{result[:imported_count]} records"
          result
        rescue StandardError => e
          error_msg = "Failed to import protected area attributes: #{e.message}"
          Rails.logger.error error_msg
          failure_result(error_msg, 0)
        end

        def self.import_geometries
          result = Wdpa::Portal::Importers::ProtectedArea::Geometry.import_to_staging
          Rails.logger.info "✓ Geometries imported: #{result[:imported_count]} records"
          result
        rescue StandardError => e
          error_msg = "Failed to import protected area geometries: #{e.message}"
          Rails.logger.error error_msg
          failure_result(error_msg, 0)
        end

        def self.import_related_sources
          result = Wdpa::Shared::Importer::ProtectedAreasRelatedSource.import_to_staging

          Rails.logger.info "✓ PARCC imported: #{result[:parcc][:imported_count]} records"
          Rails.logger.info "✓ Irreplaceability imported: #{result[:irreplaceability][:imported_count]} records"
          result
        rescue StandardError => e
          error_msg = "Failed to import related protected area sources (parcc and irreplaceability): #{e.message}"
          Rails.logger.error error_msg
          {
            parcc: failure_result(error_msg, 0),
            irreplaceability: failure_result(error_msg, 0)
          }
        end

        private_class_method :import_attributes, :import_geometries, :import_related_sources
      end
    end
  end
end
