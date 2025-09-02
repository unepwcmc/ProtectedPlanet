module Wdpa
  module Portal
    module Utils
      class ColumnMapper
        # Portal to ProtectedPlanet column mapping based on STANDARD_ATTRIBUTES from Wdpa::DataStandard
        # This ensures consistency with the existing WDPA import logic
        PORTAL_TO_PP_MAPPING = {
          # Core WDPA identifiers
          'wdpaid' => 'wdpa_id',                    # WDPA ID (primary identifier)
          'wdpa_pid' => 'wdpa_pid',                 # WDPA Parcel ID
          
          # Names and descriptions
          'name' => 'name',                         # Protected Area Name
          'orig_name' => 'original_name',           # Original Name
          
          # Area measurements
          'rep_m_area' => 'reported_marine_area',   # Reported Marine Area
          'rep_area' => 'reported_area',            # Reported Area
          'gis_m_area' => 'gis_marine_area',        # GIS Marine Area
          'gis_area' => 'gis_area',                 # GIS Area
          
          # Geographic and administrative
          'iso3' => 'countries',                    # Country (ISO3 code)
          'status' => 'legal_status',               # Legal Status
          'status_yr' => 'legal_status_updated_at', # Status Year
          
          # Conservation classification
          'iucn_cat' => 'iucn_category',           # IUCN Category
          'gov_type' => 'governance',               # Governance Type
          
          # Management information
          'mang_auth' => 'management_authority',    # Management Authority
          'mang_plan' => 'management_plan',         # Management Plan
          'int_crit' => 'international_criteria',   # International Criteria
          
          # Marine and protection status
          'marine' => 'marine_type',                # Marine Type (will be converted to boolean)
          'no_take' => 'no_take_status',            # No-take Status
          'no_take_area' => 'no_take_area',         # No-take Area
          
          # Designation details
          'desig_eng' => 'designation',             # Designation
          'desig_type' => 'jurisdiction',           # Jurisdiction (will be used by designation)
          
          # Geometry and metadata
          'wkb_geometry' => 'the_geom',             # Geometry (PostGIS)
          # 'is_polygon' => 'is_polygon',             # Geometry Type Flag
          'metadataid' => 'sources'                 # Source Reference
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

        # Maps portal attributes to ProtectedPlanet attributes using the standard mapping
        def self.map_portal_to_pp(portal_attributes)
          attributes = {}
          
          portal_attributes.each do |portal_key, value|
            if PORTAL_TO_PP_MAPPING.key?(portal_key)
              pp_key = PORTAL_TO_PP_MAPPING[portal_key]

              # Apply special transformations based on STANDARD_ATTRIBUTES
              case portal_key
              when 'marine'
                # Convert marine_type to boolean marine (as per data standard)
                attributes['marine_type'] = value
                attributes['marine'] = marine_type_to_boolean(value)
              when 'wkb_geometry'
                # Ensure geometry is properly formatted for PostGIS
                attributes[pp_key] = value
              when 'metadataid'
                # Always wrap sources as array for PortalRelation
                attributes[pp_key] = Array(value)
              else
                # Standard mapping
                attributes[pp_key] = value
              end
            else
              # Log unmapped columns for debugging
              Rails.logger.debug "Unmapped portal column: #{portal_key} (value: #{value})"
            end
          end

          # Process relational attributes using PortalRelation
          Wdpa::Portal::Utils::PortalRelation.new(attributes).create_models
        end

        private
        
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

        # Converts marine_type to boolean marine (as per data standard)
        def self.marine_type_to_boolean(marine_type)
          marine_type.to_i == 0 ? false : true
        end

      end
    end
  end
end
