# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      module StatsDbSource
        # Reads stats.global_stats (stat_type/stat_value rows) and returns an overlay
        # hash of {column_name => value} for Staging::GlobalStatistic. Values are
        # already on a 0-100 scale — no conversion. stat_description is ignored.
        # stat_types with no matching column are skipped with a soft error.
        class GlobalStats
          extend Wdpa::Portal::Importers::StatsDbSource::Base

          # The stats server's green_list_perc includes Antarctica (ATA); PP publishes the
          # no-ATA figure under that name instead.
          RENAMED_STAT_TYPES = { 'green_list_perc_no_ata' => 'green_list_perc' }.freeze

          def self.overlay_attrs(soft_errors: [])
            run_id = select_run_id(table: 'global_stats', run_column: 'metadata_gs_uuid')
            quoted_run_id = ActiveRecord::Base.lease_connection.quote(run_id)

            sql = <<~SQL
              SELECT stat_type, stat_value
              FROM stats.global_stats
              WHERE metadata_gs_uuid = #{quoted_run_id}
            SQL

            known_columns = Staging::GlobalStatistic.column_names
            values = fetch_rows(sql).to_h { |row| [row['stat_type'].to_s.strip, row['stat_value']] }
            RENAMED_STAT_TYPES.each { |from, to| values[to] = values.delete(from) if values.key?(from) }

            attrs = {}
            values.each do |stat_type, stat_value|
              next if stat_type.empty?

              unless known_columns.include?(stat_type)
                soft_errors << "Unknown global stat_type '#{stat_type}' from stats server - skipped"
                next
              end

              attrs[stat_type] = Wdpa::Shared::Importer::GlobalStats.parse_value(stat_value)
            end
            attrs
          end
        end
      end
    end
  end
end
