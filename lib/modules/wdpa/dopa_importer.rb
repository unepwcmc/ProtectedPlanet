module Wdpa::DopaImporter
  DOPA_LIST = "#{Rails.root}/lib/data/seeds/dopa4_pas_list.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      # Clear all previously set DOPA areas
      ProtectedArea.update_all(is_dopa: false)
      logger = Logger.new(STDOUT)

      pas_to_update = []

      # Read the CSV to get the WDPA IDs
      CSV.foreach(DOPA_LIST, headers: true) do |row| 
        # Find the associated Protected Area with each WDPA ID mentioned and update the is_dopa column to true
        dopa_pa = ProtectedArea.where('reported_area > 0.5e1')
                  .or(ProtectedArea.where('reported_marine_area > 0.5e1'))
                  .find_by_wdpa_id(row['wdpaid'])

        if dopa_pa.nil? 
          logger.info "DOPA site #{row['wdpaid']} not present in DB"
          next
        end

       pas_to_update << ProtectedArea.find_by_wdpa_id(row['wdpaid'])
      end
      
      ProtectedArea.where(id: pas_to_update.map(&:id)).update_all(is_dopa: true)
    end
  end

end