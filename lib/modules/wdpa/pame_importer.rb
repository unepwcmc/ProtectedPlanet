require 'csv'

module Wdpa::PameImporter
  PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/pame_data-2019-05-31.csv".freeze

  def self.import
    puts "Importing PAME evaluations..."
    delete_evaluations = []

    CSV.foreach(PAME_EVALUATIONS, headers: true) do |row|
      wdpa_id         = row[1].to_i
      methodology     = row[3]
      year            = row[4].to_i
      protected_area  = ProtectedArea.find_by_wdpa_id(wdpa_id) || nil
      metadata_id     = row[6].to_i
      name            = row[7]
      url             = row[5]
      restricted      = row[13] == "FALSE" ? false : true
      iso3s           = row[2]
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

      if protected_area.nil? && (restricted == false) # If PameEvaluation doesn’t have a PA and isn’t restricted it should be deleted.
        delete_evaluations << wdpa_id
      elsif (protected_area.nil? && restricted) || (protected_area.present?) # If PameEvaluation doesn’t have a PA and is restricted then it's restricted.
        pame_evaluation = PameEvaluation.where({
          protected_area: protected_area,
          methodology: methodology,
          year: year,
          metadata_id: metadata_id,
          url: url,
          pame_source: pame_source,
          restricted: restricted
        }).first_or_create do |pe|
          # If the record doesn't exist, create it...
          pe.protected_area = protected_area
          pe.methodology    = methodology
          pe.year           = year
          pe.metadata_id    = metadata_id
          pe.url            = url
          pe.pame_source    = pame_source
          pe.restricted     = restricted

          if protected_area.nil? && restricted
            pe.wdpa_id = wdpa_id
            pe.name    = name
          end
        end
        if protected_area.nil? && restricted
          countries = []
          iso3s.split(",").each do |iso3|
            country = Country.find_by(iso_3: iso3)
            pame_evaluation.countries << country unless pame_evaluation.countries.include? country
          end
        end
      elsif protected_area.nil? && !restricted # If PameEvaluation doesn’t have a PA and isn’t restricted it should be deleted.
        delete_evaluations << wdpa_id
      end
    end

    puts "Import finished!"
    puts "Please delete the following: #{delete_evaluations.count}"
    puts delete_evaluations.join(",")
  end
end
