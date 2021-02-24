require 'csv'

module Wdpa::PameImporter
  PAME_EVALUATIONS = "#{Rails.root}/lib/data/seeds/pame_data_2021-02-01.csv".freeze

  def self.import(csv_file=nil)
    puts "Deleting old PAME evaluations..."
    PameEvaluation.delete_all
    puts "Importing PAME evaluations..."
    hidden_evaluations = []

    csv_file = csv_file || PAME_EVALUATIONS

    CSV.foreach(csv_file, headers: true) do |row|
      id                   = row[0].to_i
      wdpa_id              = row[1].to_i
      methodology          = row[3]
      year                 = row[4].to_i
      protected_area       = ProtectedArea.find_by_wdpa_id(wdpa_id) || nil
      metadata_id          = row[6].to_i
      name                 = row[7]
      url                  = row[5]
      restricted           = row[13] == "FALSE" ? false : true
      assessment_is_public = row[14] == "FALSE" ? false : true

      if assessment_is_public
        url = url.blank? ? "Not currently public" : url
      else
        url = "Not reported"
      end

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

      pame_evaluation = PameEvaluation.where({
        id: id,
        protected_area: protected_area,
        methodology: methodology,
        year: year,
        metadata_id: metadata_id,
        url: url,
        pame_source: pame_source,
        restricted: restricted
      }).first_or_create do |pe|
        # If the record doesn't exist, create it...
        pe.id                   = id
        pe.protected_area       = protected_area
        pe.methodology          = methodology
        pe.year                 = year
        pe.metadata_id          = metadata_id
        pe.url                  = url
        pe.pame_source          = pame_source
        pe.restricted           = restricted
        pe.wdpa_id              = wdpa_id
        pe.name                 = name
        pe.assessment_is_public = assessment_is_public
      end
      if protected_area.nil?
        hidden_evaluations << wdpa_id unless restricted
      end

      iso3s.split(",").each do |iso3|
        country = Country.find_by(iso_3: iso3)
        if country.present?
          pame_evaluation.countries << country unless pame_evaluation.countries.include? country
        end
      end
    end

    puts "Import finished!"
    puts "The following are hidden: #{hidden_evaluations.count}"
    puts hidden_evaluations.join(",")
  end
end
