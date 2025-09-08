# frozen_string_literal: true

module Wdpa
  module Shared
    module Importer
      class GlobalStats
        def self.latest_global_statistics_csv
          ::Utilities::Files.latest_file_by_glob('lib/data/seeds/global_statistics_*.csv')
        end

        def self.import_live
          attrs = { singleton_guard: 0 }
          soft_errors = []

          CSV.foreach(latest_global_statistics_csv, headers: true) do |row|
            field = row['type']
            value = parse_value(row['value'])

            attrs.merge!("#{field}": value) if field.present?
          rescue StandardError => e
            soft_errors << "Failed to process row: #{e.message}"
            Rails.logger.warn "Failed to process row: #{e.message}"
          end

          stats = GlobalStatistic.first_or_initialize(attrs)
          stats.update(attrs)

          Rails.logger.info "Global statistics import completed: #{attrs.keys.length} fields updated"
          { success: true, fields_updated: attrs.keys.length, soft_errors: soft_errors, hard_errors: [] }
        rescue StandardError => e
          Rails.logger.error "Global statistics import failed: #{e.message}"
          { success: false, fields_updated: 0, soft_errors: [],
            hard_errors: ["Global statistics import failed: #{e.message}"] }
        end

        def self.import_staging
          attrs = { singleton_guard: 0 }
          soft_errors = []

          CSV.foreach(latest_global_statistics_csv, headers: true) do |row|
            field = row['type']
            value = parse_value(row['value'])

            attrs.merge!("#{field}": value) if field.present?
          rescue StandardError => e
            soft_errors << "Failed to process row: #{e.message}"
            Rails.logger.warn "Failed to process row: #{e.message}"
          end

          stats = Staging::GlobalStatistic.first_or_initialize(attrs)
          stats.update(attrs)

          Rails.logger.info "Global statistics import completed: #{attrs.keys.length} fields updated"
          { success: true, fields_updated: attrs.keys.length, soft_errors: soft_errors, hard_errors: [] }
        rescue StandardError => e
          Rails.logger.error "Global statistics import failed: #{e.message}"
          { success: false, fields_updated: 0, soft_errors: [],
            hard_errors: ["Global statistics import failed: #{e.message}"] }
        end

        def self.parse_value(val)
          val.to_s.split(',').join('').to_f
        end
      end
    end
  end
end
