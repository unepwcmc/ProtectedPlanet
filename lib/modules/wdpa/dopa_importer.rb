# As of 05Sep2025, this doesn't seem to be used please double check though
module Wdpa::DopaImporter
  DOPA_LIST = "#{Rails.root}/lib/data/seeds/dopa4_pas_list.csv"
  extend self

  def import
    ActiveRecord::Base.transaction do
      # Clear all previously set DOPA areas
      ProtectedArea.in_batches.update_all(is_dopa: false)
      logger = Logger.new(STDOUT)

      pas_to_update = []

      # Read the CSV to get the WDPA IDs
      CSV.foreach(DOPA_LIST, headers: true) do |row| 
       pas_to_update << row['site_id']
      end

      # Find all WDPA IDs (if they exist) in the CSV
      areas = ProtectedArea.where(site_id: pas_to_update)
      
      # Turn off verbose logging
      ActiveRecord::Base.logger.silence do
        # Update all of them at once
        areas.in_batches.update_all(is_dopa: true)
      end

      # Missing WDPA IDs
      missing_pas = pas_to_update - areas.map(&:site_id)
      logger.info "Could not update #{missing_pas.join(', ')}"
    end
  end

end