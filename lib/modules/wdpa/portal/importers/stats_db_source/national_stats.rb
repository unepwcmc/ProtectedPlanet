# frozen_string_literal: true

module Wdpa
  module Portal
    module Importers
      module StatsDbSource
        # Reads stats.national_stats and maps to staging_country_statistics attributes.
        # NR fields are not in the stats server — merged from CSV by the importer.
        class NationalStats
          extend Wdpa::Portal::Importers::StatsDbSource::Base

          FIELDS = %w[
            pa_marine_area pa_land_area marine_area land_area
            oecms_pa_marine_area oecms_pa_land_area
            percentage_pa_marine_cover percentage_pa_land_cover
            percentage_oecms_pa_marine_cover percentage_oecms_pa_land_cover
          ].freeze

          # Countries absent from the stats server run genuinely have zero PA
          # coverage (rather than unknown data), so they default to 0 here.
          def self.default_attrs
            FIELDS.each_with_object({}) { |field, hash| hash[field] = 0.0 }
          end

          def self.rows
            run_id = select_run_id(table: 'national_stats', run_column: 'metadata_ns_uuid')
            quoted_run_id = ActiveRecord::Base.lease_connection.quote(run_id)

            sql = <<~SQL
              SELECT iso3,
                     pa_marine, pa_terrestrial,
                     total_marine, total_terrestrial,
                     pa_oecm_marine, pa_oecm_terrestrial,
                     pa_marine_pct, pa_terrestrial_pct,
                     pa_oecm_marine_pct, pa_oecm_terrestrial_pct
              FROM stats.national_stats
              WHERE metadata_ns_uuid = #{quoted_run_id}
            SQL

            fetch_rows(sql).map do |row|
              {
                iso3: row['iso3'],
                attrs: {
                  'pa_marine_area' => num(row['pa_marine']),
                  'pa_land_area' => num(row['pa_terrestrial']),
                  'marine_area' => num(row['total_marine']),
                  'land_area' => num(row['total_terrestrial']),
                  'oecms_pa_marine_area' => num(row['pa_oecm_marine']),
                  'oecms_pa_land_area' => num(row['pa_oecm_terrestrial']),
                  'percentage_pa_marine_cover' => pct(row['pa_marine_pct']),
                  'percentage_pa_land_cover' => pct(row['pa_terrestrial_pct']),
                  'percentage_oecms_pa_marine_cover' => pct(row['pa_oecm_marine_pct']),
                  'percentage_oecms_pa_land_cover' => pct(row['pa_oecm_terrestrial_pct'])
                }
              }
            end
          end
        end
      end
    end
  end
end
