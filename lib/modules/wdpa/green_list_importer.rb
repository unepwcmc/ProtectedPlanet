module Wdpa::GreenListImporter
  GREEN_LIST_SITES_CSV = "#{Rails.root}/lib/data/seeds/green_list_sites.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      old_green_list = ProtectedArea.where(is_green_list: true)
      old_green_list.update_all(is_green_list: false)
      csv = CSV.read(GREEN_LIST_SITES_CSV)
      csv.shift # remove headers

      # sites = csv.map { |row| row }.flatten.uniq

      csv.each do |row|
        site, status, date = row[0], row[1], row[2]
        wdpa_id = Integer(site) rescue false
        if wdpa_id
          pa = ProtectedArea.find_by_wdpa_id(wdpa_id)
        else
          pa = ProtectedArea.find_by_slug(site)
        end

        unless pa.blank?
          # pa.is_green_list = true
          # pa.save
          pa.update_attributes(is_green_list: true,
                               green_list_status: status,
                               green_list_status_date: date)
          # puts "Marked #{site} as a green list site"
          puts "Updated green list site #{site}"
        end
      end
    end
  end
end
