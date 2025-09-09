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
          fields_updated = attrs.keys.length
          Wdpa::Shared::ImporterBase::Base.success_result(fields_updated, soft_errors, [], { fields_updated: fields_updated })
        rescue StandardError => e
          Rails.logger.error "Global statistics import failed: #{e.message}"
          Wdpa::Shared::ImporterBase::Base.failure_result("Global statistics import failed: #{e.message}", 0)
        end

        def self.import_to_staging
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
          fields_updated = attrs.keys.length
          Wdpa::Shared::ImporterBase::Base.success_result(fields_updated, soft_errors, [], { fields_updated: fields_updated })
        rescue StandardError => e
          Rails.logger.error "Global statistics import failed: #{e.message}"
          Wdpa::Shared::ImporterBase::Base.failure_result("Global statistics import failed: #{e.message}", 0)
        end

        def self.parse_value(val)
          val.to_s.split(',').join('').to_f
        end
      end
    end
  end
end
