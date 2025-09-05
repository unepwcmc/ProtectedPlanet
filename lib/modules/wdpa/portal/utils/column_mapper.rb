# frozen_string_literal: true

module Wdpa
  module Portal
    module Utils
      class ColumnMapper
        PORTAL_TO_PP_MAPPING = {
          # Core WDPA identifiers
          'wdpaid' => { name: 'wdpa_id', type: :integer },
          'wdpa_pid' => { name: 'wdpa_pid', type: :string },

          # Names and descriptions
          'name' => { name: 'name', type: :string },
          'orig_name' => { name: 'original_name', type: :string },

          # Area measurements
          'rep_m_area' => { name: 'reported_marine_area', type: :float },
          'rep_area' => { name: 'reported_area', type: :float },
          'gis_m_area' => { name: 'gis_marine_area', type: :float },
          'gis_area' => { name: 'gis_area', type: :float },

          # Geographic and administrative
          'iso3' => { name: 'countries', type: :csv }, # CSV type for semicolon-separated values
          'status' => { name: 'legal_status', type: :string },
          'status_yr' => { name: 'legal_status_updated_at', type: :year },

          # Conservation classification
          'iucn_cat' => { name: 'iucn_category', type: :string },
          'gov_type' => { name: 'governance', type: :string },

          # Management information
          'mang_auth' => { name: 'management_authority', type: :string },
          'mang_plan' => { name: 'management_plan', type: :string },
          'int_crit' => { name: 'international_criteria', type: :string },

          # Marine and protection status
          'marine' => { name: 'marine_type', type: :integer }, # Will be converted to boolean marine
          'no_take' => { name: 'no_take_status', type: :string },
          'no_take_area' => { name: 'no_take_area', type: :float },

          # Designation details
          'desig_eng' => { name: 'designation', type: :string },
          'desig_type' => { name: 'jurisdiction', type: :string }, # Will be used by designation

          # Geometry and metadata
          'wkb_geometry' => { name: 'the_geom', type: :geometry },
          'metadataid' => { name: 'sources', type: :integer } # Will be processed as array
        }.freeze

        # Portal to ProtectedPlanet SOURCES column mapping based on STANDARD_ATTRIBUTES from Wdpa::DataStandard::Source
        # This ensures consistency with the existing WDPA source import logic
        PORTAL_TO_PP_SOURCES_MAPPING = {
          'title' => 'title',
          'responsible_party' => 'responsible_party',
          'responsible_email' => 'responsible_email',
          'year' => 'year',
          'language' => 'language',
          'character_set' => 'character_set',
          'reference_system' => 'reference_system',
          'scale' => 'scale',
          'lineage' => 'lineage',
          'citation' => 'citation',
          'metadataid' => 'metadataid',
          'disclaimer' => 'disclaimer'
        }.freeze

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

              # Use shared type converter for type conversion
              case portal_key
              when 'marine'
                # Convert marine_type to boolean marine (as per data standard)
                attributes['marine_type'] = Wdpa::Shared::TypeConverter.convert(value, as: type)
                attributes['marine'] = marine_type_to_boolean(attributes['marine_type'])
              else
                # Standard type conversion using the shared type system
                attributes[pp_key] = Wdpa::Shared::TypeConverter.convert(value, as: type)
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
        def self.marine_type_to_boolean(marine_type)
          !(marine_type.to_i == 0)
        end

        # Maps portal SOURCE attributes to ProtectedPlanet attributes using the standard mapping
        def self.map_portal_sources_to_pp(portal_attributes)
          mapped = {}

          portal_attributes.each do |portal_key, value|
            if PORTAL_TO_PP_SOURCES_MAPPING.key?(portal_key)
              pp_key = PORTAL_TO_PP_SOURCES_MAPPING[portal_key]
              # Apply transformations for source fields
              mapped[pp_key] = value
            else
              # Log unmapped columns for debugging
              Rails.logger.debug "Unmapped portal source column: #{portal_key} (value: #{value})"
            end
          end

          mapped
        end
      end
    end
  end
end
