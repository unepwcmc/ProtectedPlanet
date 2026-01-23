# frozen_string_literal: true

module Wdpa
  module Portal
    module Utils
      class ProtectedAreaSourceColumnMapper

        # Portal to ProtectedPlanet SOURCES column mapping based on STANDARD_ATTRIBUTES from Wdpa::DataStandard::Source
        # This ensures consistency with the existing WDPA source import logic
        PORTAL_TO_PP_SOURCES_MAPPING = {
          'data_title' => 'title',
          'resp_party' => 'responsible_party',
          'year' => 'year',
          'language' => 'language',
          'char_set' => 'character_set',
          'ref_system' => 'reference_system',
          'scale' => 'scale',
          'lineage' => 'lineage',
          'citation' => 'citation',
          'metadataid' => 'metadataid',
          'disclaimer' => 'disclaimer',
          'update_yr' => 'update_year',
          'verifier' => 'verifier'
        }.freeze

        # Source columns in portal views that are intentionally not mapped and should not log
        PORTAL_SOURCES_IGNORED_COLUMNS = %w[index_id].freeze

        # Maps portal SOURCE attributes to ProtectedPlanet attributes using the standard mapping
        def self.map_portal_sources_to_pp(portal_attributes)
          mapped = {}

          # Determine destination table (prefer staging if present)
          dest_table = Staging::Source.table_name

          portal_attributes.each do |portal_key, value|
            if PORTAL_TO_PP_SOURCES_MAPPING.key?(portal_key)
              pp_key = PORTAL_TO_PP_SOURCES_MAPPING[portal_key]

              # Only include mapped column if it exists in the destination table
              if ActiveRecord::Base.connection.column_exists?(dest_table, pp_key)
                # `year` and `update_year` are DATE columns in the DB, but the portal
                # exposes them as 4‑digit strings. Normalise them to a proper Date
                # using the shared `:year` converter (YYYY-01-01).
                if %w[year update_year].include?(pp_key.to_s)
                  mapped[pp_key] = Wdpa::Shared::TypeConverter.convert(value, as: :year)
                else
                  mapped[pp_key] = value
                end
              else
                Rails.logger.debug "Skipping source column not present in #{dest_table}: #{pp_key} (from #{portal_key})"
              end
            else
              # Log unmapped columns for debugging
              next if PORTAL_SOURCES_IGNORED_COLUMNS.include?(portal_key)

              Rails.logger.debug "Unmapped portal source column: #{portal_key} (value: #{value})"
            end
          end

          mapped
        end
      end
    end
  end
end
