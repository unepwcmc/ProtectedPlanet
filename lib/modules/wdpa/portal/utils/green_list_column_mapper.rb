# frozen_string_literal: true

module Wdpa
  module Portal
    module Utils
      class GreenListColumnMapper
        # Maps staging_portal_standard_greenlist view columns to importer attributes.
        # for_create: true = include in Staging::GreenListStatus.create!; false = lookup-only (e.g. site_id, site_pid).
        PORTAL_TO_PP_GREENLIST_MAPPING = {
          'site_id' => { name: 'site_id', type: :integer, for_create: false },
          'site_pid' => { name: 'site_pid', type: :string, for_create: false },
          'gl_status' => { name: 'gl_status', type: :string, for_create: true },
          'gl_expiry' => { name: 'gl_expiry', type: :gl_expiry_date, for_create: true },
          'gl_link' => { name: 'gl_link', type: :string, for_create: true }
        }.freeze

        # Column names to exclude from Staging::GreenListStatus.create! (for_create: false; used for lookup only).
        def self.columns_not_for_create
          PORTAL_TO_PP_GREENLIST_MAPPING.values
            .select { |config| config[:for_create] == false }
            .map { |config| config[:name].to_s }
            .uniq
        end

        # Single entry point: map portal row then resolve PA/parcel (mirrors PameColumnMapper.map_portal_pame_to_pp_evaluation).
        # Returns { pa: Staging::ProtectedArea | Staging::ProtectedAreaParcel, attributes_for_create: Hash }.
        def self.map_portal_greenlist_to_pp_greenlist(portal_attributes)
          attributes = map_portal_greenlist_to_attributes(portal_attributes)
          Wdpa::Portal::Relation::GreenList.new(attributes).create_models
        end

        def self.map_portal_greenlist_to_attributes(portal_attributes)
          greenlist_attributes = {}

          portal_attributes.each do |portal_key, value|
            key_str = portal_key.to_s
            next unless PORTAL_TO_PP_GREENLIST_MAPPING.key?(key_str)

            mapping = PORTAL_TO_PP_GREENLIST_MAPPING[key_str]
            db_column_name = mapping[:name]
            column_type = mapping[:type]
            greenlist_attributes[db_column_name] = Wdpa::Shared::TypeConverter.convert(value, as: column_type)
          end

          greenlist_attributes
        end

        # Returns only attributes suitable for Staging::GreenListStatus.create! (excludes columns_not_for_create).
        # Pass the result of map_portal_greenlist_to_attributes.
        def self.attributes_for_green_list_status_create(mapped_attributes)
          return {} if mapped_attributes.blank?

          keys_to_exclude = columns_not_for_create
          mapped_attributes.reject { |key, _| keys_to_exclude.include?(key.to_s) }
        end
      end
    end
  end
end
