# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class ProtectedArea::Attribute < Base
        def self.import_to_staging(notifier: nil)
          # Import protected area attributes (non-spatial data only) to staging tables
          # Handles both Staging::ProtectedArea and Staging::ProtectedAreaParcel
          # Geometry data is handled separately by GeometryImporter

          # Get mapping of SITE IDs with multiple parcels (similar to existing importer)
          site_ids_with_multiple_site_pids = get_site_ids_with_multiple_site_pids_map

          adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
          relation = adapter.protected_areas_relation

          # Get total count for progress tracking
          total_count = relation.count
          Rails.logger.info "Starting protected area attributes import: #{total_count} records"

          imported_count = 0
          imported_pa_count = 0
          imported_parcel_count = 0
          soft_errors = []
          progress_interval = Wdpa::Portal::Config::PortalImportConfig.progress_notification_interval

          relation.find_in_batches do |batch|
            batch_result = process_batch(batch, site_ids_with_multiple_site_pids)
            imported_count += batch_result[:count]
            imported_pa_count += (batch_result[:pa_count] || 0)
            imported_parcel_count += (batch_result[:parcel_count] || 0)
            soft_errors.concat(batch_result[:soft_errors])

            # Send progress notification if we've hit the interval
            if notifier && imported_count % progress_interval == 0
              notifier.progress(imported_count, total_count, 'protected area attributes')
            end
          rescue StandardError => e
            Rails.logger.error("Batch processing failed: #{e.message}")
            raise e # Re-raise as hard error to stop import
          end
          Rails.logger.info "#{imported_pa_count} Protected area attributes imported, #{imported_parcel_count} Protected area parcel attributes imported"
          notifier&.phase("#{imported_pa_count} Protected area attributes imported, #{imported_parcel_count} Protected area parcel attributes imported")

          build_result(imported_count, soft_errors, [], {
            protected_areas_imported_count: imported_pa_count,
            protected_area_parcels_imported_count: imported_parcel_count
          })
        end

        def self.process_batch(batch, site_ids_with_multiple_site_pids)
          imported_count = 0
          imported_pa_count = 0
          imported_parcel_count = 0
          soft_errors = []

          batch.each do |pa_attributes|
            # Wrap each record in its own transaction to prevent batch failure
            ActiveRecord::Base.transaction do
              # Determine if this should go to ProtectedArea and/or ProtectedAreaParcel
              entry_info = current_entry_parcel_info(pa_attributes, site_ids_with_multiple_site_pids)
              add_to_protected_areas = entry_info[:is_first_or_only_parcel]
              add_to_protected_area_parcels = entry_info[:has_multiple_parcels]

              if add_to_protected_areas
                pa_attrs = Wdpa::Portal::Utils::ColumnMapper.map_portal_to_pp_protected_area(pa_attributes)
                Staging::ProtectedArea.create!(pa_attrs)
                imported_count += 1
                imported_pa_count += 1
              end

              # Always add to parcels if there are multiple parcels (including the first one)
              if add_to_protected_area_parcels
                parcel_attrs = Wdpa::Portal::Utils::ColumnMapper.map_portal_to_pp_protected_area_parcel(pa_attributes)
                Staging::ProtectedAreaParcel.create!(parcel_attrs)
                # Don't count the first parcel as it's already counted in protected_area
                # Only count additional parcels (when add_to_protected_areas is false)
                unless add_to_protected_areas
                  imported_count += 1
                  imported_parcel_count += 1
                end
              end
            end
          rescue StandardError => e
            soft_errors << "Row error processing SITE_ID #{pa_attributes['site_id']} SITE_PID #{pa_attributes['site_pid']}: #{e.message}"
          end

          { count: imported_count,
            pa_count: imported_pa_count,
            parcel_count: imported_parcel_count,
            soft_errors: soft_errors }
        end

        def self.current_entry_parcel_info(protected_area_attributes, site_ids_with_multiple_site_pids)
          site_id = protected_area_attributes['site_id']
          site_pid = protected_area_attributes['site_pid']
          first_parcel_id = site_ids_with_multiple_site_pids[site_id]

          {
            is_first_or_only_parcel: first_parcel_id.nil? || first_parcel_id == site_pid,
            has_multiple_parcels: !first_parcel_id.nil?
          }
        end

        # A site that has multiple site_pids is a site that has multiple parcels
        def self.get_site_ids_with_multiple_site_pids_map
          sites_with_multiple_parcels = {}

          Wdpa::Portal::Config::PortalImportConfig.portal_protected_area_materialised_views.each do |view|
            # Find WDPA IDs that have more than one parcel
            find_site_ids_with_multiple_parcels_command = <<~SQL
              SELECT site_id, MIN(site_pid) AS first_site_pid
              FROM #{view}
              GROUP BY site_id
              HAVING COUNT(*) > 1
            SQL

            ActiveRecord::Base.connection.execute(find_site_ids_with_multiple_parcels_command).each do |row|
              sites_with_multiple_parcels[row['site_id']] = row['first_site_pid']
            end
          end
          sites_with_multiple_parcels
        end
      end
    end
  end
end
