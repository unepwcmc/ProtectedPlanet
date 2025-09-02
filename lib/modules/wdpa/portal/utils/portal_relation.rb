# frozen_string_literal: true

module Wdpa
  module Portal
    module Utils
      class PortalRelation
        def initialize(current_attributes)
          @current_attributes = current_attributes
        end

        # Process all attributes and convert relational ones to model objects
        def create_models
          # Process each attribute - directly call conversion methods if they exist
          @current_attributes.each do |key, value|
            if respond_to?(key, true)
              @current_attributes[key] = send(key, value)
            end
          end
          
          # Remove temporary fields that were only used for lookups
          @current_attributes.delete('jurisdiction')
          @current_attributes.delete('no_take_area')
          
          @current_attributes
        end

        # Convert ISO3 codes to Country objects for HABTM association
        def countries(iso_codes)          
          # Convert ISO3 codes to Country objects
          countries = iso_codes.map do |iso_3|
            Country.find_by(iso_3: iso_3)
          end.compact
          
          Rails.logger.debug "PortalRelation: Converted #{iso_codes} to #{countries.count} countries"
          countries
        end

        # Convert legal status names to LegalStatus objects
        def legal_status(value)
          LegalStatus.where(name: value).first_or_create
        end

        # Convert IUCN category names to IucnCategory objects
        def iucn_category(value)
          IucnCategory.where(name: value).first
        end

        # Convert governance names to Governance objects
        def governance(value)
          Governance.where(name: value).first
        end

        # Convert management authority names to ManagementAuthority objects
        def management_authority(value)
          ManagementAuthority.where(name: value).first_or_create
        end

        # Convert no-take status names to NoTakeStatus objects
        def no_take_status(value)
          NoTakeStatus.where(name: value).first
        end

        # Convert designation names to Designation objects with jurisdiction
        def designation(value)
          jurisdiction_name = @current_attributes[:jurisdiction]
          jurisdiction = jurisdiction_name ? Jurisdiction.where(name: jurisdiction_name).first : nil
          Designation.where({
            name: value,
            jurisdiction: jurisdiction
          }).first_or_create
        end

        # Convert green list status names to GreenListStatus objects
        def green_list_status(value)
          GreenListStatus.where(name: value).first
        end

        # Convert source metadata IDs to StagingSource objects for HABTM association
        def sources(values)
          Array(values).map { |id| StagingSource.find_by(metadataid: id) }.compact
        end

      end
    end
  end
end
