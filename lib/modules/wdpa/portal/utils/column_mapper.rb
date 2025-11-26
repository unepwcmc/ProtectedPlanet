# frozen_string_literal: true

module Wdpa
  module Portal
    module Utils
      class ColumnMapper
        PORTAL_TO_PP_MAPPING = {
          # Core WDPA identifiers
          'site_id' => { name: 'site_id', type: :integer },
          'site_pid' => { name: 'site_pid', type: :string },

          # Names and descriptions
          'name_eng' => { name: 'name', type: :string },
          'name' => { name: 'original_name', type: :string },

          # Marine and protection status
          'realm' => { name: 'realm', type: :string }, # Will be converted to boolean marine
          'site_type' => { name: :site_type, type: :string },

          # Area measurements
          'rep_m_area' => { name: 'reported_marine_area', type: :float },
          'rep_area' => { name: 'reported_area', type: :float },
          'gis_m_area' => { name: 'gis_marine_area', type: :float },
          'gis_area' => { name: 'gis_area', type: :float },

          # Geographic and administrative
          'iso3' => { name: 'countries', type: :csv }, # CSV type for semicolon-separated values
          'prnt_iso3' => { name: :parent_iso3, type: :string },

          'status' => { name: 'legal_status', type: :string },
          'status_yr' => { name: 'legal_status_updated_at', type: :year },

          # Conservation classification
          'iucn_cat' => { name: 'iucn_category', type: :string },
          'gov_type' => { name: 'governance', type: :string },
          'govsubtype' => { name: 'governance_subtype', type: :string },

          # Management information
          'mang_auth' => { name: 'management_authority', type: :string },
          'mang_plan' => { name: 'management_plan', type: :string },
          'int_crit' => { name: 'international_criteria', type: :string },
          'no_take' => { name: 'no_take_status', type: :string },
          'no_tk_area' => { name: 'no_take_area', type: :float },

          # Designation details
          'desig_eng' => { name: 'designation', type: :string },
          'desig_type' => { name: 'jurisdiction', type: :string }, # Will be used by designation

          # Geometry and metadata
          'wkb_geometry' => { name: 'the_geom', type: :geometry },
          'metadataid' => { name: 'sources', type: :integer }, # Will be processed as array

          'own_type' => { name: :owner_type, type: :string },
          'ownsubtype' => { name: 'ownership_subtype', type: :string },

          'supp_info' => { name: :supplementary_info, type: :string },
          'cons_obj' => { name: :conservation_objectives, type: :string },
          'verif' => { name: :verif, type: :string },

          'inlnd_wtrs' => { name: 'inland_waters', type: :string },
          'oecm_asmt' => { name: 'oecm_assessment', type: :string }
        }.freeze

        PROTECTED_AREA_COLUMNS_TO_BE_REMOVED_BEFORE_INSERT = [
          PORTAL_TO_PP_MAPPING['desig_type'][:name],
          PORTAL_TO_PP_MAPPING['no_tk_area'][:name]
        ]

        PROTECTED_AREA_PARCEL_COLUMNS_TO_BE_REMOVED_BEFORE_INSERT = [
          PORTAL_TO_PP_MAPPING['desig_type'][:name],
          PORTAL_TO_PP_MAPPING['no_tk_area'][:name]
        ]

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

        # Maps portal attributes to ProtectedArea attributes (non-spatial data only)
        def self.map_portal_to_pp_protected_area(portal_attributes)
          map_portal_to_pp_with_relation(portal_attributes, Wdpa::Portal::Relation::ProtectedArea)
        end

        # Maps portal attributes to ProtectedAreaParcel attributes (non-spatial data only)
        def self.map_portal_to_pp_protected_area_parcel(portal_attributes)
          map_portal_to_pp_with_relation(portal_attributes, Wdpa::Portal::Relation::ProtectedAreaParcel)
        end

        # Common logic for mapping portal attributes with different relation classes
        def self.map_portal_to_pp_with_relation(portal_attributes, relation_class)
          attributes = {}

          portal_attributes.each do |portal_key, value|
            if PORTAL_TO_PP_MAPPING.key?(portal_key)
              mapping = PORTAL_TO_PP_MAPPING[portal_key]
              pp_key = mapping[:name]
              type = mapping[:type]

              # Skip geometry data - it's handled separately by GeometryImporter
              next if type == :geometry

              # Default type conversion using the shared type system
              attributes[pp_key] = Wdpa::Shared::TypeConverter.convert(value, as: type)

              # Additional setup for specific portal keys
              case portal_key
              when 'realm'
                # Derive marine and marine_type from realm
                attributes['marine'] = realm_is_marine(value)

                # TODO: This should become a legacy field at some point
                # consider removing the field as realm is now used instead
                # Check usuage in protected_planet_api and if not used, remove the field
                # make sure to remove 'marine_type' in s3 bucket way of importers
                attributes['marine_type'] = realm_to_marine_type(value)
              when 'site_type'
                # TODO: This should become a legacy field at some point
                # consider removing the field as realm is now used instead of is_oecm
                attributes['is_oecm'] = Wdpa::Shared::TypeConverter.convert(value, as: :oecm_string)
              end
            else
              # Log unmapped columns for debugging
              Rails.logger.debug "Unmapped portal column: #{portal_key} (value: #{value})"
            end
          end

          # Process relational attributes using the specified relation class
          relation_class.new(attributes).create_models
        end

        # Converts marine_type to boolean marine (as per data standard)
        # Handles string values: Terrestrial = 0, Coastal = 1, Marine = 2
        def self.realm_to_marine_type(realm)
          realm_str = realm.to_s.downcase.strip

          case realm_str
          when 'terrestrial'
            0 # Terrestrial
          when 'coastal'
            1 # Coastal
          when 'marine'
            2 # Marine
          else
            Rails.logger.warn "Unknown or missing realm '#{realm}'. Defaulting marine_type to Terrestrial (0)"
            0
          end
        end

        def self.realm_is_marine(realm)
          realm_str = realm.to_s.downcase.strip
          case realm_str
          when 'terrestrial'
            false
          when 'coastal', 'marine'
            true
          else
            Rails.logger.warn "Unknown or missing realm '#{realm}'. Defaulting marine=false"
            false
          end
        end

        # Maps portal SOURCE attributes to ProtectedPlanet attributes using the standard mapping
        def self.map_portal_sources_to_pp(portal_attributes)
          mapped = {}

          # Determine destination table (prefer staging if present)
          dest_table = begin
            if ActiveRecord::Base.connection.table_exists?(Staging::Source.table_name)
              Staging::Source.table_name
            else
              Source.table_name
            end
          rescue StandardError
            # Fallback to live sources table
            'sources'
          end

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
