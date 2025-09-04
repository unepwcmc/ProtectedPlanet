# frozen_string_literal: true

# As of 04Apr2025, Greenlist is only imported into the `protected_areas` table.

# Protential future Issue:
# - At the moment, the system only greenlists entire a protected area in the `protected_areas` table
#   the entire site is greenlisted which might not be the case in future.

# In future if greenlist is only applying to parcel A, B but not C (not entire protected area)
# then the following actions are needed to change the code here:
# - Parcels in `protected_area_parcels` also need to be updated/imported for Greenlist status.
# - This is problematic for PAs with multiple parcels, where not all parcels are greenlisted.
# - `green_list_url` already exists in the `protected_area_parcels` table.
# - Add `green_list_status_id` column to `protected_area_parcels` to track individual parcel status.

# See app/models/protected_area_parcel.rb to link up
require 'csv'

module Wdpa::Portal::Importers
  class GreenList
    def self.import_staging
      ActiveRecord::Base.transaction do
        clear_existing_data
        process_csv_file
      end
    end

    private

    def self.clear_existing_data
      Staging::ProtectedArea.where.not(green_list_status_id: nil)
        .update_all(green_list_status_id: nil)
      Staging::GreenListStatus.destroy_all

      Rails.logger.info 'Cleared existing staging green list data'
    end

    def self.process_csv_file
      invalid = []
      not_found = []
      duplicates = []
      imported_count = 0
      errors = []

      CSV.foreach(csv_file_path, headers: true) do |row|
        result = process_row(row)

        case result[:status]
        when :success
          imported_count += 1
        when :invalid
          invalid << result[:wdpa_id]
        when :not_found
          not_found << result[:wdpa_id]
        when :duplicate
          duplicates << result[:wdpa_id]
        when :error
          errors << result[:error]
        end
      rescue StandardError => e
        errors << "Error processing row #{row['wdpaid']}: #{e.message}"
        Rails.logger.warn "Green list row processing failed: #{e.message}"
      end

      log_import_results(invalid, not_found, duplicates, imported_count)

      {
        success: errors.empty?,
        imported_count: imported_count,
        errors: errors,
        invalid_wdpa_ids: invalid,
        not_found_wdpa_ids: not_found,
        duplicates: duplicates
      }
    end

    def self.process_row(row)
      wdpa_id = validate_wdpa_id(row['wdpaid'])
      return { status: :invalid, wdpa_id: row['wdpaid'] } unless wdpa_id

      pa = Staging::ProtectedArea.find_by_wdpa_id(wdpa_id)
      return { status: :not_found, wdpa_id: wdpa_id } if pa.blank?

      # Check for duplicates
      return { status: :duplicate, wdpa_id: wdpa_id } if pa.green_list_status_id

      gls = Staging::GreenListStatus.find_or_create_by(
        row.to_h.slice('status', 'expiry_date')
      )

      # Update protected area
      pa.green_list_url = row['url']
      pa.green_list_status_id = gls.id
      pa.save!

      { status: :success, wdpa_id: wdpa_id }
    end

    def self.validate_wdpa_id(wdpa_id_string)
      Integer(wdpa_id_string)
    rescue StandardError
      false
    end

    def self.csv_file_path
      ::Utilities::Files.latest_file_by_glob(Wdpa::Portal::Config::StagingConfig.green_list_csv_path)
    end

    def self.log_import_results(invalid, not_found, duplicates, imported_count)
      Rails.logger.info 'Green list import completed:'
      Rails.logger.info "  - Imported: #{imported_count} records"
      Rails.logger.info "  - Invalid WDPAIDs: #{invalid.join(',')}" if invalid.any?
      Rails.logger.info "  - Not found WDPAIDs: #{not_found.join(',')}" if not_found.any?
      Rails.logger.info "  - Duplicates: #{duplicates.join(',')}" if duplicates.any?
    end
  end
end
