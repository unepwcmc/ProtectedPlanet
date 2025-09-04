# frozen_string_literal: true

module Wdpa::Portal::Relation
  class ProtectedAreaParcel
    def initialize(current_attributes)
      @current_attributes = current_attributes
    end

    # Process all attributes and convert relational ones to model objects
    def create_models
      @current_attributes.each do |key, value|
        @current_attributes[key] = send(key, value) if respond_to?(key, true)
      end

      # Remove temporary fields that were only used for lookups
      @current_attributes.delete('jurisdiction')
      @current_attributes.delete('no_take_area')

      @current_attributes
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
      IucnCategory.where(name: value).first
    end

    def governance(value)
      Governance.where(name: value).first
    end

    def management_authority(value)
      ManagementAuthority.where(name: value).first_or_create
    end

    def no_take_status(value)
      Staging::NoTakeStatus.create({
        name: value,
        area: @current_attributes[:no_take_area]
      })
    end

    def designation(value)
      jurisdiction_name = @current_attributes[:jurisdiction]
      jurisdiction = jurisdiction_name ? Jurisdiction.where(name: jurisdiction_name).first : nil
      Designation.where({
        name: value,
        jurisdiction: jurisdiction
      }).first_or_create
    end

    def sources(values)
      Array(values).map { |id| Staging::Source.find_by(metadataid: id) }.compact
    end
  end
end
