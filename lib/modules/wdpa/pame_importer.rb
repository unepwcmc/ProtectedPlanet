require 'csv'

module Wdpa::PameImporter
  PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/pame_data-2019-01-31.csv".freeze

  def self.import
    puts "Importing PAME evaluations..."

    CSV.foreach(PAME_EVALUATIONS, headers: true) do |row|
      wdpa_id         = row[1].to_i
      methodology     = row[3]
      year            = row[4].to_i
      protected_area  = ProtectedArea.find_by_wdpa_id(wdpa_id)
      metadata_id     = row[6].to_i
      url             = row[5]
      pame_source     = PameSource.where({
        data_title: row[9],
        resp_party: row[10],
        year:       row[11].to_i,
        language:   row[12]
        }).first_or_create do |ps|
          # if the record doesn't exist, create it...
          ps.data_title = row[9]
          ps.resp_party = row[10]
          ps.year       = row[11].to_i
          ps.language   = row[12]
        end

      if protected_area.nil?
        puts "Could not find Protected Area with wdpa #{wdpa_id}" if Rails.env != 'test'
      else
        PameEvaluation.where({
          protected_area: protected_area,
          methodology: methodology,
          year: year,
          metadata_id: metadata_id,
          url: url,
          pame_source: pame_source
        }).first_or_create do |pe|
          # If the record doesn't exist, create it...
          pe.protected_area = protected_area
          pe.methodology    = methodology
          pe.year           = year
          pe.metadata_id    = metadata_id
          pe.url            = url
          pe.pame_source    = pame_source
        end
      end
    end

    puts "Import finished!"
  end
end
