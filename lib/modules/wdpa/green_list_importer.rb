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
        end
      end

      puts "Invalid WDPAIDs found: #{invalid.join(',')}"
      puts "PA with WDPAID not found: #{not_found.join(',')}"
      puts "Statuses rows for same WDPAID found: #{duplicates.join(',')}"
    end
  end
end
