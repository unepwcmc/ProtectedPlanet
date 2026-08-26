# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      module StatsDbSource
        # Shared helpers for reading stats-server results from the `stats` schema.
        # Values in *_pct columns are fractions (0-1); PP columns store 0-100.
        module Base
          class MissingStatsError < StandardError; end
          def vintage
            label = Wdpa::Portal::ImportRuntimeConfig.label
            if label.nil? || label.to_s.strip.empty?
              raise MissingStatsError, 'Release label is not set (PP_RELEASE_LABEL) — required to select stats vintage'
            end

            label.to_s.strip
          end

          # Pick the run covering the most rows for the vintage; tie-break latest timestamp.
          # Partial runs (single-country test runs) are naturally ignored.
          def select_run_id(table:, run_column:)
            quoted_vintage = ActiveRecord::Base.lease_connection.quote(vintage)
            sql = <<~SQL
              SELECT #{run_column} AS run_id
              FROM stats.#{table}
              WHERE metadata_vintage = #{quoted_vintage}
              GROUP BY #{run_column}
              ORDER BY COUNT(*) DESC, MAX(metadata_run_timestamp) DESC
              LIMIT 1
            SQL
            run_id = ActiveRecord::Base.lease_connection.select_value(sql)
            if run_id.nil?
              raise MissingStatsError,
                "No rows in stats.#{table} for vintage #{vintage} — fix stats mirror or set PP_STATS_SOURCE=csv"
            end

            run_id
          end

          def fetch_rows(sql)
            ActiveRecord::Base.lease_connection.select_all(sql).to_a
          end

          # Fraction (0-1) -> percentage (0-100); NaN/nil -> nil
          def pct(value)
            v = num(value)
            v.nil? ? nil : v * 100
          end

          def num(value)
            return nil if value.nil?
            return nil if value.respond_to?(:nan?) && value.nan?
            return nil if value.is_a?(String) && value.strip.casecmp('nan').zero?

            value.to_f
          end
        end
      end
    end
  end
end
