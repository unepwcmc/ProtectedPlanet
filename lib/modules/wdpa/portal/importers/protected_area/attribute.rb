# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class ProtectedArea::Attribute < Base
        def self.import_to_staging
          # Import protected area attributes (non-spatial data only) to staging tables
          # Handles both Staging::ProtectedArea and Staging::ProtectedAreaParcel
          # Geometry data is handled separately by GeometryImporter

          # Get mapping of WDPA IDs with multiple parcels (similar to existing importer)
          wdpaids_multiple_parcels_map = protected_area_ids_with_multiple_parcels

          adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
          relation = adapter.protected_areas_relation

          imported_count = 0
          soft_errors = []

          relation.find_in_batches do |batch|
            batch_result = process_batch(batch, wdpaids_multiple_parcels_map)
            imported_count += batch_result[:count]
            soft_errors.concat(batch_result[:soft_errors])
          rescue StandardError => e
            Rails.logger.error("Batch processing failed: #{e.message}")
            raise e # Re-raise as hard error to stop import
          end

          success_result(:imported_count, soft_errors, [])
        end

        def self.process_batch(batch, wdpaids_multiple_parcels_map)
          imported_count = 0
          soft_errors = []

          batch.each do |pa_attributes|
            # Wrap each record in its own transaction to prevent batch failure
            ActiveRecord::Base.transaction do
              # Determine if this should go to ProtectedArea and/or ProtectedAreaParcel
              entry_info = current_entry_parcel_info(pa_attributes, wdpaids_multiple_parcels_map)
              add_to_protected_areas = entry_info[:is_first_or_only_parcel]
              add_to_protected_area_parcels = entry_info[:has_multiple_parcels]

              if add_to_protected_areas
                pa_attrs = Wdpa::Portal::Utils::ColumnMapper.map_portal_to_pp_protected_area(pa_attributes)
                Staging::ProtectedArea.create!(pa_attrs)
                imported_count += 1
              end

              # Always add to parcels if there are multiple parcels (including the first one)
              if add_to_protected_area_parcels
                parcel_attrs = Wdpa::Portal::Utils::ColumnMapper.map_portal_to_pp_protected_area_parcel(pa_attributes)
                Staging::ProtectedAreaParcel.create!(parcel_attrs)
                # Don't count the first parcel as it's already counted in protected_area
                # Only count additional parcels (when add_to_protected_areas is false)
                imported_count += 1 unless add_to_protected_areas
              end
            end
          rescue StandardError => e
            soft_errors << "Row error processing SITE_ID #{pa_attributes['site_id']} SITE_PID #{pa_attributes['site_pid']}: #{e.message}"
          end

          { count: imported_count, soft_errors: soft_errors }
        end

        def self.current_entry_parcel_info(protected_area_attributes, wdpaids_multiple_parcels_map)
          wdpa_id = protected_area_attributes['site_id']
          wdpa_pid = protected_area_attributes['site_pid']
          first_parcel_id = wdpaids_multiple_parcels_map[wdpa_id]

          {
            is_first_or_only_parcel: first_parcel_id.nil? || first_parcel_id == wdpa_pid,
            has_multiple_parcels: !first_parcel_id.nil?
          }
        end

        def self.protected_area_ids_with_multiple_parcels
          pa_ids_with_multiple_parcels = {}

          Wdpa::Portal::Config::StagingConfig.portal_protected_area_views.each do |view|
            # Find WDPA IDs that have more than one parcel
            find_wdpa_ids_with_multiple_parcels_command = <<~SQL
              SELECT site_id, MIN(site_pid) AS first_site_pid
              FROM #{view}
              GROUP BY site_id
              HAVING COUNT(*) > 1
            SQL

            ActiveRecord::Base.connection.execute(find_wdpa_ids_with_multiple_parcels_command).each do |row|
              pa_ids_with_multiple_parcels[row['site_id']] = row['first_site_pid']
            end
          end
          pa_ids_with_multiple_parcels
        end
      end
    end
  end
end
