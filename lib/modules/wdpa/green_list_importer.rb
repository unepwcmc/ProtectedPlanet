module Wdpa::GreenListImporter
  # Make sure headers are: wdpaid,status,expiry_date
  GREEN_LIST_SITES_CSV = "#{Rails.root}/lib/data/seeds/green_list_sites.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      ProtectedArea.where.not(green_list_status_id: nil).
        update_all(green_list_status_id: nil)
      GreenListStatus.destroy_all

      invalid = []
      not_found = []
      duplicates = []

      CSV.foreach(GREEN_LIST_SITES_CSV, headers: true) do |row|
        wdpa_id = Integer(row['wdpaid']) rescue false
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
