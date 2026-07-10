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
          Wdpa::Shared::ImporterBase::Base.build_result(fields_updated, soft_errors, [],
            { fields_updated: fields_updated })
        rescue StandardError => e
          Rails.logger.error "Global statistics import failed: #{e.message}"
          Wdpa::Shared::ImporterBase::Base.failure_result("Global statistics import failed: #{e.message}", 0)
        end

        def self.import_to_staging(notifier: nil)
          soft_errors = []
          attrs = { singleton_guard: 0 }.merge(csv_attrs(soft_errors))

          # DB mode is a hybrid: CSV supplies the full base (incl. fields the stats
          # server doesn't emit, e.g. green_list_*); stats-server values win where present.
          db_fields_count = 0
          if Wdpa::Portal::ImportRuntimeConfig.stats_from_db?
            overlay = Wdpa::Portal::Importers::StatsDbSource::GlobalStats.overlay_attrs(soft_errors: soft_errors)
            db_fields_count = overlay.keys.length
            attrs.merge!(overlay.transform_keys(&:to_sym))
          end

          stats = Staging::GlobalStatistic.first_or_initialize(attrs)
          stats.update(attrs)

          fields_updated = attrs.keys.length
          Rails.logger.info "Global statistics import completed: #{fields_updated} fields updated (#{db_fields_count} from stats DB)"
          notifier&.phase("#{fields_updated} Global statistics imported/updated (#{db_fields_count} from stats DB).")
          Wdpa::Shared::ImporterBase::Base.build_result(fields_updated, soft_errors, [],
            { fields_updated: fields_updated })
        rescue StandardError => e
          notifier&.phase("Global statistics import failed: #{e.message}")
          Rails.logger.error "Global statistics import failed: #{e.message}"
          Wdpa::Shared::ImporterBase::Base.failure_result("Global statistics import failed: #{e.message}", 0)
        end

        def self.csv_attrs(soft_errors)
          attrs = {}
          CSV.foreach(latest_global_statistics_csv, headers: true) do |row|
            field = row['type']
            value = parse_value(row['value'])

            attrs.merge!("#{field}": value) if field.present?
          rescue StandardError => e
            soft_errors << "Failed to process row: #{e.message}"
            Rails.logger.warn "Failed to process row: #{e.message}"
          end
          attrs
        end

        def self.parse_value(val)
          val.to_s.split(',').join('').to_f
        end
      end
    end
  end
end
