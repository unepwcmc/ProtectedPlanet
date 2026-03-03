# frozen_string_literal: true

module Wdpa
  module Portal
    module Utils
      class PameColumnMapper
        PORTAL_TO_PP_PAME_MAPPING = {
          'asmt_id' => { name: 'asmt_id', type: :integer },
          'site_id' => { name: 'site_id', type: :integer },
          'method' => { name: 'method', type: :string },
          'submityear' => { name: 'submit_year', type: :integer },
          'asmt_year' => { name: 'asmt_year', type: :integer },
          'asmt_url' => { name: 'asmt_url', type: :string },
          'eff_metaid' => { name: 'eff_metaid', type: :integer },
          'site_pid' => { name: 'site_pid', type: :string },
          'verif_eff' => { name: 'verif_eff', type: :string },
          'info_url' => { name: 'info_url', type: :string },
          'gov_act' => { name: 'gov_act', type: :string },
          'gov_asmt' => { name: 'gov_asmt', type: :string },
          'dp_bio' => { name: 'dp_bio', type: :string },
          'dp_other' => { name: 'dp_other', type: :string },
          'mgmt_obset' => { name: 'mgmt_obset', type: :string },
          'mgmt_obman' => { name: 'mgmt_obman', type: :string },
          'mgmt_adapt' => { name: 'mgmt_adapt', type: :string },
          'mgmt_staff' => { name: 'mgmt_staff', type: :string },
          'mgmt_budgt' => { name: 'mgmt_budgt', type: :string },
          'mgmt_thrts' => { name: 'mgmt_thrts', type: :string },
          'mgmt_mon' => { name: 'mgmt_mon', type: :string },
          'out_bio' => { name: 'out_bio', type: :string }
        }.freeze

        PORTAL_PAME_IGNORED_COLUMNS = %w[].freeze

        def self.map_portal_pame_to_pp_evaluation(portal_attributes)
          attributes = map_portal_pame_to_attributes(portal_attributes)
          Wdpa::Portal::Relation::PameEvaluation.new(attributes).create_models
        end

        def self.map_portal_pame_to_attributes(portal_attributes)
          pame_attributes = {}

          portal_attributes.each do |portal_key, value|
            if PORTAL_TO_PP_PAME_MAPPING.key?(portal_key)
              mapping = PORTAL_TO_PP_PAME_MAPPING[portal_key]
              db_column_name = mapping[:name]
              column_type_for_conversion = mapping[:type]
              pame_attributes[db_column_name] = Wdpa::Shared::TypeConverter.convert(value, as: column_type_for_conversion)
            else
              next if PORTAL_PAME_IGNORED_COLUMNS.include?(portal_key)

              Rails.logger.debug "Unmapped portal pame column: #{portal_key} (value: #{value})"
            end
          end

          pame_attributes
        end
      end
    end
  end
end
