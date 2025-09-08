# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      class CountryStatistics < Base
        def self.latest_country_statistics_csv
          ::Utilities::Files.latest_file_by_glob('lib/data/seeds/country_statistics_*.csv')
        end

        def self.latest_pame_country_statistics_csv
          ::Utilities::Files.latest_file_by_glob('lib/data/seeds/pame_country_statistics_*.csv')
        end

        def self.perform_import
          ActiveRecord::Base.transaction do
            geometry_result = Wdpa::Portal::Importers::CountriesProtectedAreaGeometryStatistics.import_staging
            country_result = import_country_statistics
            pame_result = import_pame_statistics

            # Check if any sub-importer failed
            all_hard_errors = (country_result[:hard_errors] || []) +
                              (pame_result[:hard_errors] || []) +
                              (geometry_result[:hard_errors] || [])
            all_soft_errors = (country_result[:soft_errors] || []) +
                              (pame_result[:soft_errors] || []) +
                              (geometry_result[:soft_errors] || [])

            Rails.logger.info 'Country statistics import completed'
            {
              imported_count: 0, # Complex importer
              soft_errors: all_soft_errors,
              hard_errors: all_hard_errors,
              additional_fields: {
                country_pa_geometry: geometry_result,
                country_stats: country_result,
                country_pame_stats: pame_result
              }
            }
          end
        end

        def self.import_country_statistics
          import_stats(latest_country_statistics_csv, Staging::CountryStatistic)
        rescue StandardError => e
          { imported_count: 0, soft_errors: [], hard_errors: ["Country statistics import failed: #{e.message}"] }
        end

        def self.import_pame_statistics
          import_stats(latest_pame_country_statistics_csv, Staging::PameStatistic)
        rescue StandardError => e
          { imported_count: 0, soft_errors: [], hard_errors: ["PAME statistics import failed: #{e.message}"] }
        end

        def self.import_stats(path, model)
          countries = Country.pluck(:id, :iso_3).each_with_object({}) do |(id, iso_3), hash|
            hash[iso_3] = id
          end

          imported_count = 0
          soft_errors = []

          CSV.foreach(path, headers: true) do |row|
            country_iso3 = row.delete('iso3').last
            country_id = countries[country_iso3]
            # If the value is na (not applicable) use nil
            row.each { |key, value| row[key] = nil if value && value.downcase == 'na' }
            attrs = { country_id: country_id }.merge(row)
            attrs = attrs.merge(pame_assessments(country_id)) if model == Staging::PameStatistic

            model.create(attrs)
            imported_count += 1
          rescue StandardError => e
            soft_errors << "Row error processing country #{row['iso3']}: #{e.message}"
          end

          { imported_count: imported_count, soft_errors: soft_errors, hard_errors: [] }
        end

        def self.pame_assessments(country_id)
          return {} unless country_id

          country = Country.find(country_id)

          {
            assessments: country.staging_assessments,
            assessed_pas: country.staging_assessed_pas
          }
        end
      end
    end
  end
end
