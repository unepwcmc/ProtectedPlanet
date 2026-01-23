# frozen_string_literal: true

module Wdpa
  module Portal
    module Utils
      class PameSourceColumnMapper
        PORTAL_TO_PP_PAME_SOURCES_MAPPING = {
          'eff_metaid' => { name: 'id', type: :integer },
          'data_title' => { name: 'data_title', type: :string },
          'resp_party' => { name: 'resp_party', type: :string },
          'year' => { name: 'year', type: :integer },
          'language' => { name: 'language', type: :string }
        }.freeze

        PORTAL_PAME_SOURCES_IGNORED_COLUMNS = %w[resp_email resp_pers update_yr].freeze

        def self.map_portal_pame_sources_to_pp(portal_attributes)
          mapped = {}

          portal_attributes.each do |portal_key, value|
            key = portal_key.to_s.downcase
            if PORTAL_TO_PP_PAME_SOURCES_MAPPING.key?(key)
              mapping = PORTAL_TO_PP_PAME_SOURCES_MAPPING[key]
              mapped[mapping[:name]] = Wdpa::Shared::TypeConverter.convert(value, as: mapping[:type])
            else
              next if PORTAL_PAME_SOURCES_IGNORED_COLUMNS.include?(key)

              Rails.logger.debug "Unmapped portal pame source column: #{portal_key} (value: #{value})"
            end
          end

          mapped
        end
      end
    end
  end
end
