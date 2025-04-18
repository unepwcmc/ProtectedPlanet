# frozen_string_literal: true

# TODO: 
# As of 04Apr2025 Greenlist is only imported to protected_areas (ProtectedArea) table 
# parcels in protected_area_parcels also need to be updated/imported for greenlist status
# protected_area_parcels
# Currently the system only greenlist PAs in protected_areas (ProtectedArea) table and thinking the whole site is greenlisted
# Reason: In case for a PA which has multiple parcels but not all parcels are greenlisted
# green_list_url is already in protected_area_parcels table green_list_status_id column needs adding 
# See app/models/protected_area_parcel.rb to link up

module Wdpa::GreenListImporter
  # Make sure headers are: wdpaid,status,expiry_date

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
        wdpa_id = begin
                    Integer(row['wdpaid'])
                  rescue StandardError
                    false
                  end
        unless wdpa_id
          invalid << row['wdpaid']
          next
        end

        pa = ProtectedArea.find_by_wdpa_id(wdpa_id)

        if pa.blank?
          not_found << wdpa_id
        else
          if pa.green_list_status_id
            duplicates << wdpa_id
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
