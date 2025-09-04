# frozen_string_literal: true

require 'csv'

module Wdpa::Portal::Importers
  class Pame
    def self.latest_pame_data_csv
      ::Utilities::Files.latest_file_by_glob('lib/data/seeds/pame_data_*.csv')
    end

    def self.import(csv_file = nil)
      Rails.logger.info 'Deleting old staging PAME evaluations...'
      Staging::PameEvaluation.delete_all
      Rails.logger.info 'Importing staging PAME evaluations...'
      site_ids_not_recognised = []
      errors = []

      csv_file ||= latest_pame_data_csv

      CSV.foreach(csv_file, headers: true) do |row|
        ActiveRecord::Base.transaction do
          id                   = row[0].to_i
          wdpa_id              = row[1].to_i
          methodology          = row[3]
          year                 = row[4].to_i
          protected_area       = Staging::ProtectedArea.find_by_wdpa_id(wdpa_id) || nil
          metadata_id          = row[6].to_i
          name                 = row[7]
          url                  = row[5]
          restricted           = row[13] != 'FALSE'
          assessment_is_public = row[14] != 'FALSE'

          url = if assessment_is_public
                  url.blank? ? 'Not reported' : url
                else
                  'Not public'
                end

          iso3s           = row[2]
          pame_source     = Staging::PameSource.where({
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

          pame_evaluation = Staging::PameEvaluation.where({
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
          site_ids_not_recognised << wdpa_id if protected_area.nil?

          iso3s.split(';').each do |iso3|
            country = Country.find_by(iso_3: iso3)
            pame_evaluation.countries << country if country.present? && !(pame_evaluation.countries.include? country)
          end
        end
      rescue StandardError => e
        errors << "Error processing row id #{row[0]}: #{e.message}"
        Rails.logger.error "Error processing PAME row: #{e.message}"
      end

      total_evaluations = Staging::PameEvaluation.count
      total_sources = Staging::PameSource.count

      Rails.logger.info 'Staging PAME import completed successfully'
      Rails.logger.info "Total PAME evaluations imported: #{total_evaluations}"
      Rails.logger.info "Total PAME sources imported: #{total_sources}"

      {
        success: errors.empty?,
        evaluations_imported: total_evaluations,
        sources_imported: total_sources,
        site_ids_not_recognised: site_ids_not_recognised,
        errors: errors
      }
    end
  end
end
