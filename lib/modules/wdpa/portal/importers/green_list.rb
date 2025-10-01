# frozen_string_literal: true

# As of 29Sep2025, Greenlist is imported into both the `protected_areas` and `protected_area_parcels` tables.

# Current Implementation:
# - The system greenlists entire protected areas in the `protected_areas` table
# - All associated parcels in `protected_area_parcels` are also updated with the same green list status
# - This ensures consistency between the main protected area record and all its parcels

# Future Considerations:
# - If greenlist status needs to apply only to specific parcels (not entire protected area)
# - then the following actions would be needed:
# - Modify the import logic to handle parcel-specific green list status
# - Update the data model to support different green list statuses per parcel
# - `green_list_url` and `green_list_status_id` columns exist in both tables

# See app/models/protected_area_parcel.rb to link up
require 'csv'

module Wdpa
  module Portal
    module Importers
      class GreenList < Base
        def self.import_to_staging(notifier: nil)
          clear_existing_data
          results = process_csv_file

          notifier&.phase("#{results[:imported_count]} Green list import completed")
          results
        rescue StandardError => e
          notifier&.phase("Import failed: #{e.message}")
          failure_result("Import failed: #{e.message}", 0)
        end

        def self.clear_existing_data
          Staging::ProtectedArea.where.not(green_list_status_id: nil)
            .update_all(green_list_status_id: nil)
          Staging::ProtectedAreaParcel.where.not(green_list_status_id: nil)
            .update_all(green_list_status_id: nil)
          Staging::GreenListStatus.destroy_all

          Rails.logger.info 'Cleared existing staging green list data'
        end

        def self.process_csv_file
          invalid = []
          not_found = []
          duplicates = []
          imported_count = 0
          soft_errors = []

          CSV.foreach(csv_file_path, headers: true) do |row|
            # Wrap each row in its own transaction to prevent batch failure
            ActiveRecord::Base.transaction do
              result = process_row(row)

              case result[:status]
              when :success
                imported_count += 1
              when :invalid
                invalid << result[:site_id]
              when :not_found
                not_found << result[:site_id]
              when :duplicate
                duplicates << result[:site_id]
              when :error
                soft_errors << result[:error]
              end
            end
          rescue StandardError => e
            soft_errors << "Row error processing #{row['site_id']}: #{e.message}"
            Rails.logger.warn "Green list row processing failed: #{e.message}"
          end

          Rails.logger.info 'Green list import completed:'
          Rails.logger.info "  - Imported: #{imported_count} records"
          Rails.logger.info "  - Invalid SITE_IDs: #{invalid.join(',')}" if invalid.any?
          Rails.logger.info "  - Not found SITE_IDs: #{not_found.join(',')}" if not_found.any?
          Rails.logger.info "  - Duplicates: #{duplicates.join(',')}" if duplicates.any?

          build_result(imported_count, soft_errors, [], {
            invalid_site_ids: invalid,
            not_found_site_ids: not_found,
            duplicates: duplicates
          })
        end

        def self.process_row(row)
          site_id = validate_site_id(row['site_id'])
          return { status: :invalid, site_id: row['site_id'] } unless site_id

          pa = Staging::ProtectedArea.find_by_site_id(site_id)
          return { status: :not_found, site_id: site_id } if pa.blank?

          # Check for duplicates
          return { status: :duplicate, site_id: site_id } if pa.green_list_status_id

          gls = Staging::GreenListStatus.find_or_create_by(
            row.to_h.slice('status', 'expiry_date')
          )

          # Update protected area
          pa.green_list_url = row['url']
          pa.green_list_status_id = gls.id
          pa.save!

          # Update all protected area parcels for this site_id
          parcels = Staging::ProtectedAreaParcel.where(site_id: site_id)
          parcels.update_all(
            green_list_url: row['url'],
            green_list_status_id: gls.id
          )

          { status: :success, site_id: site_id }
        end

        def self.validate_site_id(site_id_string)
          Integer(site_id_string)
        rescue StandardError
          false
        end

        def self.csv_file_path
          ::Utilities::Files.latest_file_by_glob('lib/data/seeds/green_list_sites_*.csv')
        end
      end
    end
  end
end
