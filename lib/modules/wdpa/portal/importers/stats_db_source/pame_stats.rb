# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      module StatsDbSource
        # Reads stats.pame_stats and maps to staging_pame_statistics attributes.
        # assessments/assessed_pas are merged from PP data by the importer.
        class PameStats
          extend Wdpa::Portal::Importers::StatsDbSource::Base

          def self.rows
            run_id = select_run_id(table: 'pame_stats', run_column: 'metadata_pame_uuid')
            quoted_run_id = ActiveRecord::Base.connection.quote(run_id)

            sql = <<~SQL
              SELECT iso3,
                     pame_pa_marine, pame_pa_terrestrial,
                     pame_pa_marine_pct, pame_pa_terrestrial_pct
              FROM stats.pame_stats
              WHERE metadata_pame_uuid = #{quoted_run_id}
            SQL

            fetch_rows(sql).map do |row|
              {
                iso3: row['iso3'],
                attrs: {
                  'pame_pa_marine_area' => num(row['pame_pa_marine']),
                  'pame_pa_land_area' => num(row['pame_pa_terrestrial']),
                  'pame_percentage_pa_marine_cover' => pct(row['pame_pa_marine_pct']),
                  'pame_percentage_pa_land_cover' => pct(row['pame_pa_terrestrial_pct'])
                }
              }
            end
          end
        end
      end
    end
  end
end
