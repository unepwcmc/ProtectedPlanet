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

module Wdpa::GreenListImporter
  # Make sure headers are: site_id,status,expiry_date

  module_function

  def latest_green_list_sites_csv
    ::Utilities::Files.latest_file_by_glob('lib/data/seeds/green_list_sites_*.csv')
  end

  def import
    ActiveRecord::Base.transaction do
      ProtectedArea.where.not(green_list_status_id: nil)
        .update_all(green_list_status_id: nil)
      ProtectedAreaParcel.where.not(green_list_status_id: nil)
        .update_all(green_list_status_id: nil)
      GreenListStatus.destroy_all

      invalid = []
      not_found = []
      duplicates = []

      CSV.foreach(latest_green_list_sites_csv, headers: true) do |row|
        site_id = begin
          Integer(row['site_id'])
        rescue StandardError
          false
        end
        unless site_id
          invalid << row['site_id']
          next
        end

        pa = ProtectedArea.find_by_site_id(site_id)

        if pa.blank?
          not_found << site_id
        else
          if pa.green_list_status_id
            duplicates << site_id
            next
          end
          gls = GreenListStatus.find_or_create_by(row.to_h.slice('status', 'expiry_date'))

          # Link to IUCN profile of site
          pa.green_list_url = row['url']
          pa.green_list_status_id = gls.id
          pa.save

          # Update all protected area parcels for this site_id
          parcels = ProtectedAreaParcel.where(site_id: site_id)
          parcels.update_all(
            green_list_url: row['url'],
            green_list_status_id: gls.id
          )
        end
      end

      puts "Invalid WDPAIDs found: #{invalid.join(',')}"
      puts "PA with WDPAID not found: #{not_found.join(',')}"
      puts "Statuses rows for same WDPAID found: #{duplicates.join(',')}"
    end
  end
end
