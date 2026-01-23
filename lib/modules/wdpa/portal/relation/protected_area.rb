# frozen_string_literal: true

# If you change here you might need to also include the changes to protected_area_parcel.rb in this folder
module Wdpa
  module Portal
    module Relation
      class ProtectedArea
        def initialize(current_attributes)
          @current_attributes = current_attributes
        end

        # Process all attributes and convert relational ones to model objects
        def create_models
          @current_attributes.each do |key, value|
            @current_attributes[key] = send(key, value) if respond_to?(key, true)
          end

          # Remove fields that should not be inserted
          remove_fields

          @current_attributes
        end

        # Remove temporary fields that were only used for lookups
        def remove_fields
          Wdpa::Portal::Utils::ProtectedAreaColumnMapper::PROTECTED_AREA_COLUMNS_TO_BE_REMOVED_BEFORE_INSERT.each do |column_name|
            next unless column_name

            @current_attributes.delete(column_name)
          end
        end

        def countries(iso_codes)
          iso_codes.map do |iso_3|
            Country.find_by(iso_3: iso_3)
          end.compact
        end

        def legal_status(value)
          LegalStatus.where(name: value).first_or_create
        end

        def iucn_category(value)
          IucnCategory.where(name: value).first_or_create
        end

        def governance(value)
          Governance.where(name: value).first_or_create
        end

        def management_authority(value)
          ManagementAuthority.where(name: value).first_or_create
        end

        def realm(value)
          Realm.where(name: value).first_or_create
        end

        def no_take_status(value)
          Staging::NoTakeStatus.create({
            name: value,
            area: @current_attributes['no_take_area']
          })
        end

        # Convert designation names to Designation objects with jurisdiction
        def designation(value)
          jurisdiction_name = @current_attributes['jurisdiction']
          jurisdiction = jurisdiction_name ? Jurisdiction.where(name: jurisdiction_name).first_or_create : nil
          Designation.where({
            name: value,
            jurisdiction: jurisdiction
          }).first_or_create
        end

        # Convert source metadata IDs to Staging::Source objects for HABTM association
        def sources(values)
          Array(values).map { |id| Staging::Source.find_by(metadataid: id) }.compact
        end
      end
    end
  end
end
