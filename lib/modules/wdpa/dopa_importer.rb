module Wdpa::DopaImporter
  DOPA_LIST = "#{Rails.root}/lib/data/seeds/dopa4_pas_list.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      # Clear all previously set DOPA areas
      ProtectedArea.update_all(is_dopa: false)

      # Read the CSV to get the WDPA IDs
      CSV.foreach(DOPA_LIST, headers: true) do |row| 
        # Find the associated Protected Area with each WDPA ID mentioned and update the is_dopa column to true
        dopa_pa = ProtectedArea.where(wdpa_id: row['wdpaid'])
        
        if dopa_pa.nil? 
          logger.info "#{row['wdpaid']} not present in DB"
          next
        end
        
        dopa_pa.update(is_dopa: true)
      end
    end
  end

end