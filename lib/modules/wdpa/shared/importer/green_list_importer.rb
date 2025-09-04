# frozen_string_literal: true

require 'csv'

module Wdpa::Shared::Importers
  class GreenListImporter
    # Portal-specific green list importer
    # Based on Wdpa::GreenListImporter but adapted for staging tables and portal workflow

    def self.import
      new.import
    end

    def import
      ActiveRecord::Base.transaction do
        # Clear existing staging green list data
        clear_existing_data

        # Process CSV file
        result = process_csv_file

        # Return import results
        result
      end
    rescue StandardError => e
      Rails.logger.error "Green list import failed: #{e.message}"
      {
        success: false,
        imported_count: 0,
        errors: ["Green list import failed: #{e.message}"],
        invalid_wdpa_ids: [],
        not_found_wdpa_ids: [],
        duplicates: []
      }
    end

    private

    def clear_existing_data
      # Clear existing staging green list data
      Staging::ProtectedArea.where.not(green_list_status_id: nil)
        .update_all(green_list_status_id: nil)
      Staging::GreenListStatus.destroy_all

      Rails.logger.info 'Cleared existing staging green list data'
    end

    def process_csv_file
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

      # Log results
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

    def process_row(row)
      wdpa_id = validate_wdpa_id(row['wdpaid'])
      return { status: :invalid, wdpa_id: row['wdpaid'] } unless wdpa_id

      # Find staging protected area
      pa = Staging::ProtectedArea.find_by_wdpa_id(wdpa_id)
      return { status: :not_found, wdpa_id: wdpa_id } if pa.blank?

      # Check for duplicates
      return { status: :duplicate, wdpa_id: wdpa_id } if pa.green_list_status_id

      # Create or find green list status
      gls = Staging::GreenListStatus.find_or_create_by(
        row.to_h.slice('status', 'expiry_date')
      )

      # Update protected area
      pa.green_list_url = row['url']
      pa.green_list_status_id = gls.id
      pa.save!

      { status: :success, wdpa_id: wdpa_id }
    end

    def validate_wdpa_id(wdpa_id_string)
      Integer(wdpa_id_string)
    rescue StandardError
      false
    end

    def csv_file_path
      # Use configuration from StagingConfig
      ::Utilities::Files.latest_file_by_glob(Wdpa::Portal::Config::StagingConfig.green_list_csv_path)
    end

    def log_import_results(invalid, not_found, duplicates, imported_count)
      Rails.logger.info 'Green list import completed:'
      Rails.logger.info "  - Imported: #{imported_count} records"
      Rails.logger.info "  - Invalid WDPAIDs: #{invalid.join(',')}" if invalid.any?
      Rails.logger.info "  - Not found WDPAIDs: #{not_found.join(',')}" if not_found.any?
      Rails.logger.info "  - Duplicates: #{duplicates.join(',')}" if duplicates.any?
    end
  end
end
