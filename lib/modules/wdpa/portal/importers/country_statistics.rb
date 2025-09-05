# frozen_string_literal: true

module Wdpa::Portal::Importers
  class CountryStatistics
    def self.latest_country_statistics_csv
      ::Utilities::Files.latest_file_by_glob('lib/data/seeds/country_statistics_*.csv')
    end

    def self.latest_pame_country_statistics_csv
      ::Utilities::Files.latest_file_by_glob('lib/data/seeds/pame_country_statistics_*.csv')
    end

    def self.import_staging
      geometry_result = nil
      country_result = nil
      pame_result = nil

      ActiveRecord::Base.transaction do
        geometry_result = import_geometry_statistics
        country_result = import_country_statistics
        pame_result = import_pame_statistics
      end

      Rails.logger.info 'Country statistics import completed'
      {
        country_stats_imported_success: country_result[:errors].empty?,
        country_stats_imported_errors: country_result[:errors],
        country_stats_imported: country_result[:country_stats_imported],

        countries_pame_stats_imported_success: pame_result[:errors].empty?,
        countries_pame_stats_imported_errors: pame_result[:errors],
        countries_pame_stats_imported: pame_result[:pame_stats_imported],

        countries_pa_geometry_counted_success: geometry_result[:errors].empty?,
        countries_pa_geometry_counted_errors: geometry_result[:errors],
        countries_pa_geometry_counted: geometry_result[:pa_geometry_counted]
      }
    end

    def self.import_geometry_statistics
      result = Wdpa::Portal::Importers::CountriesProtectedAreaGeometryStatistics.import_staging

      {
        pa_geometry_counted: result[:processed_countries_count] || 0,
        errors: result[:errors] || []
      }
    end

    def self.import_country_statistics
      imported = import_stats(latest_country_statistics_csv, Staging::CountryStatistic)
      {
        country_stats_imported: imported,
        errors: []
      }
    rescue StandardError => e
      {
        country_stats_imported: 0,
        errors: ["Country statistics import failed: #{e.message}"]
      }
    end

    def self.import_pame_statistics
      imported = import_stats(latest_pame_country_statistics_csv, Staging::PameStatistic)
      {
        pame_stats_imported: imported,
        errors: []
      }
    rescue StandardError => e
      {
        pame_stats_imported: 0,
        errors: ["PAME statistics import failed: #{e.message}"]
      }
    end

    def self.import_stats(path, model)
      countries = Country.pluck(:id, :iso_3).each_with_object({}) do |(id, iso_3), hash|
        hash[iso_3] = id
      end

      imported_count = 0
      CSV.foreach(path, headers: true) do |row|
        country_iso3 = row.delete('iso3').last
        country_id = countries[country_iso3]
        # If the value is na (not applicable) use nil
        row.each { |key, value| row[key] = nil if value && value.downcase == 'na' }
        attrs = { country_id: country_id }.merge(row)
        attrs = attrs.merge(pame_assessments(country_id)) if model == Staging::PameStatistic

        model.create(attrs)
        imported_count += 1
      end

      imported_count
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
