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
          CSV.foreach(latest_global_statistics_csv, headers: true) do |row|
            field = row['type']
            value = parse_value(row['value'])

            attrs.merge!("#{field}": value) if field.present?
          end

          stats = GlobalStatistic.first_or_initialize(attrs)
          stats.update(attrs)

          Rails.logger.info "Global statistics import completed: #{attrs.keys.length} fields updated"
          { success: true, fields_updated: attrs.keys.length, errors: [] }
        end

        def self.import_staging
          attrs = { singleton_guard: 0 }
          CSV.foreach(latest_global_statistics_csv, headers: true) do |row|
            field = row['type']
            value = parse_value(row['value'])

            attrs.merge!("#{field}": value) if field.present?
          end

          stats = Staging::GlobalStatistic.first_or_initialize(attrs)
          stats.update(attrs)

          Rails.logger.info "Global statistics import completed: #{attrs.keys.length} fields updated"
          { success: true, fields_updated: attrs.keys.length, errors: [] }
        end

        def self.parse_value(val)
          val.to_s.split(',').join('').to_f
        end
      end
    end
  end
end
