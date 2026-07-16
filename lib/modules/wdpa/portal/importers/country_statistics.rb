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

        def self.latest_country_statistics_merge_fields_csv
          ::Utilities::Files.latest_file_by_glob('lib/data/seeds/country_stats_merge_fields_*.csv')
        end

        def self.import_to_staging(notifier: nil)
          country_result = import_country_statistics
          pame_result = import_pame_statistics
          geometry_result = Wdpa::Portal::Importers::CountriesProtectedAreaGeometryStatistics.import_to_staging

          Rails.logger.info "Country PA geometry: #{geometry_result[:imported_count]}, Country general stats: #{country_result[:imported_count]}, Country PAME: #{pame_result[:imported_count]}"
          notifier&.phase("#{geometry_result[:imported_count]} Country PA geometry, #{country_result[:imported_count]} Country general, #{pame_result[:imported_count]} Country PAME imported")
          {
            country_pa_geometry: geometry_result,
            country_general_stats: country_result,
            country_pame_stats: pame_result
          }
        end

        def self.import_country_statistics
          if Wdpa::Portal::ImportRuntimeConfig.stats_from_db?
            import_stats_from_db(Wdpa::Portal::Importers::StatsDbSource::NationalStats, Staging::CountryStatistic)
          else
            import_stats(latest_country_statistics_csv, Staging::CountryStatistic)
          end
        rescue StandardError => e
          failure_result("Country statistics import failed: #{e.message}", 0)
        end

        def self.import_pame_statistics
          if Wdpa::Portal::ImportRuntimeConfig.stats_from_db?
            import_stats_from_db(Wdpa::Portal::Importers::StatsDbSource::PameStats, Staging::PameStatistic)
          else
            import_stats(latest_pame_country_statistics_csv, Staging::PameStatistic)
          end
        rescue StandardError => e
          failure_result("PAME statistics import failed: #{e.message}", 0)
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

            record = model.find_or_initialize_by(country_id: country_id)
            record.assign_attributes(attrs)
            record.save!
            imported_count += 1
          rescue StandardError => e
            soft_errors << "Row error processing country #{row['iso3']}: #{e.message}"
          end

          build_result(imported_count, soft_errors, [])
        end

        # DB path: rows come pre-mapped from the stats schema; NR fields are not in
        # the stats server so they are merged from the merge-fields CSV by iso3.
        def self.import_stats_from_db(source_class, model)
          countries = Country.pluck(:id, :iso_3).each_with_object({}) do |(id, iso_3), hash|
            hash[iso_3] = id
          end

          imported_count = 0
          soft_errors = []
          nr_attrs = model == Staging::CountryStatistic ? nr_attrs_by_iso3 : {}

          source_class.rows.each do |row|
            iso3 = row[:iso3]
            country_id = countries[iso3]
            attrs = { country_id: country_id }.merge(row[:attrs])

            if model == Staging::CountryStatistic
              attrs = attrs.merge(nr_attrs.fetch(iso3, {}))
            elsif model == Staging::PameStatistic
              attrs = attrs.merge(pame_assessments(country_id))
            end

            record = model.find_or_initialize_by(country_id: country_id)
            record.assign_attributes(attrs)
            record.save!
            imported_count += 1
          rescue StandardError => e
            soft_errors << "Row error processing country #{iso3}: #{e.message}"
          end

          build_result(imported_count, soft_errors, [])
        end

        def self.nr_attrs_by_iso3
          CSV.foreach(latest_country_statistics_merge_fields_csv, headers: true).each_with_object({}) do |row, hash|
            iso3 = row['iso3']
            next unless iso3

            hash[iso3] = row.to_h.reject { |k, _| k == 'iso3' }.transform_values do |value|
              value && value.downcase == 'na' ? nil : value
            end
          end
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
