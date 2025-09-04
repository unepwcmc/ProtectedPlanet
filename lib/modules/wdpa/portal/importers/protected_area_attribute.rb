module Wdpa::Portal::Importers
  class ProtectedAreaAttributeImporter
    def self.import
      # Import protected area attributes (non-spatial data only) to staging tables
      # Handles both Staging::ProtectedArea and Staging::ProtectedAreaParcel
      # Geometry data is handled separately by GeometryImporter

      # Get mapping of WDPA IDs with multiple parcels (similar to existing importer)
      wdpaids_multiple_parcels_map = protected_area_ids_with_multiple_parcels

      adapter = Wdpa::Portal::Adapters::ImportViewsAdapter.new
      relation = adapter.protected_areas_relation

      imported_count = 0
      errors = []

      relation.find_in_batches do |batch|
        batch_result = process_batch(batch, wdpaids_multiple_parcels_map)
        imported_count += batch_result[:count]
        errors.concat(batch_result[:errors])
      rescue StandardError => e
        errors << "Batch processing error: #{e.message}"
        Rails.logger.error("Batch processing failed: #{e.message}")
      end

      {
        success: errors.empty?,
        imported_count: imported_count,
        errors: errors
      }
    end

    def self.process_batch(batch, wdpaids_multiple_parcels_map)
      imported_count = 0
      errors = []

      batch.each do |pa_attributes|
        # Determine if this should go to ProtectedArea and/or ProtectedAreaParcel
        entry_info = current_entry_parcel_info(pa_attributes, wdpaids_multiple_parcels_map)
        add_to_protected_areas = entry_info[:is_first_or_only_parcel]
        add_to_protected_area_parcels = entry_info[:has_multiple_parcels]

        if add_to_protected_areas
          pa_attrs = Wdpa::Portal::Utils::ColumnMapper.map_portal_to_pp_protected_area(pa_attributes)
          Staging::ProtectedArea.create!(pa_attrs)
          imported_count += 1
        end

        if add_to_protected_area_parcels
          parcel_attrs = Wdpa::Portal::Utils::ColumnMapper.map_portal_to_pp_protected_area_parcel(pa_attributes)
          Staging::ProtectedAreaParcel.create!(parcel_attrs)
          imported_count += 1
        end
      rescue StandardError => e
        errors << "Error processing SITE_ID #{pa_attributes['wdpaid']} SITE_PID #{pa_attributes['wdpa_pid']}: #{e.message}"
      end

      { count: imported_count, errors: errors }
    end

    def self.current_entry_parcel_info(protected_area_attributes, wdpaids_multiple_parcels_map)
      wdpa_id = protected_area_attributes['wdpaid']
      wdpa_pid = protected_area_attributes['wdpa_pid']
      parcel_info = wdpaids_multiple_parcels_map[wdpa_id]

      {
        is_first_or_only_parcel: parcel_info.nil? || parcel_info == wdpa_pid,
        has_multiple_parcels: !parcel_info.nil?
      }
    end

    def self.protected_area_ids_with_multiple_parcels
      pa_ids_with_multiple_parcels = {}

      Wdpa::Portal::Config::StagingConfig.portal_protected_area_views.each do |view|
        # Find WDPA IDs that have more than one parcel
        find_wdpa_ids_with_multiple_parcels_command = <<~SQL
          SELECT wdpaid, MIN(wdpa_pid) AS first_wdpa_pid
          FROM #{view}
          GROUP BY wdpaid
          HAVING COUNT(*) > 1
        SQL

        ActiveRecord::Base.connection.execute(find_wdpa_ids_with_multiple_parcels_command).each do |row|
          pa_ids_with_multiple_parcels[row['wdpaid']] = row['first_wdpa_pid']
        end
      end

      pa_ids_with_multiple_parcels
    end
  end
end
