require 'csv'

module Wdpa::PameImporter
  PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/pame_evaluations.csv".freeze

  def self.import
    CSV.foreach(PAME_EVALUATIONS, headers: true) do |row|
      wdpa_id         = row[0].to_i
      methodology     = row[2]
      year            = row[3].to_i
      protected_area  = ProtectedArea.find_by_wdpa_id(wdpa_id)

      if protected_area.nil?
        puts "Could not find Protected Area with wdpa #{wdpa_id}"
      else
        PameEvaluation.where({
          protected_area: protected_area,
          methodology: methodology,
          year: year
        }).first_or_create do |pe|
          # If the record doesn't exist, create it...
          pe.protected_area = protected_area
          pe.methodology    = methodology
          pe.year           = year
          puts "Created Pame Evaluation for #{protected_area.name}: #{methodology} #{year}"
        end
      end
    end

    puts "Import finished!"
  end
end
