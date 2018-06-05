require 'csv'
require 'byebug'

module Wdpa::PameImporter
  PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/pame_evaluations.csv".freeze

  def self.import
    CSV.foreach(PAME_EVALUATIONS, headers: true) do |row|
      wdpa_id = row[0].to_i
      method  = row[2]
      year    = row[3].to_i
      protected_area = ProtectedArea.find_by_wdpa_id(wdpa_id)

      PameEvaluation.where({
        protected_area: protected_area,
        method: method,
        year: year
      }).first_or_create do |pe|
        # If the record doesn't exist, create it...
        pe.protected_area = protected_area
        pe.method         = method
        pe.year           = year
        puts "Created Pame Evaluation for #{protected_area.name}: #{method} #{year}"
      end
    end

    puts "Import finished!"
  end
end
