# frozen_string_literal: true

class CountryRestrictedMessage
  extend ActiveSupport::NumberHelper

  CSV_PATH = Rails.root.join('lib/data/seeds/country_restricted_data.csv').freeze
  CACHE_KEY = 'country:restricted_messages'

  class << self
    def message_for(country)
      messages[country.iso_3.to_s.upcase]
    end

    private

    def messages
      Rails.cache.fetch(CACHE_KEY, expires_in: ApplicationController::CACHE_FETCH_TTL) do
        next {} unless File.exist?(CSV_PATH)

        figures_by_iso3 = CSV.foreach(CSV_PATH, headers: true).each_with_object({}) do |row, data|
          iso3 = row['iso3']&.strip&.upcase
          next if iso3.blank?

          data[iso3] = {
            protected_areas_count: row['protected_areas_count'].to_i,
            oecms_count: row['oecms_count'].to_i
          }
        end

        country_names = Country.unscoped
          .where(iso_3: figures_by_iso3.keys)
          .pluck(:iso_3, :name)
          .to_h { |iso_3, name| [iso_3.upcase, name] }

        figures_by_iso3.each_with_object({}) do |(iso3, figures), cached_messages|
          cached_messages[iso3] = build_message(country_names.fetch(iso3, iso3), figures)
        end
      end
    end

    def build_message(country_name, figures)
      protected_areas_msg = I18n.t(
        'country.message.restricted.protected_areas',
        formatted_count: number_to_delimited(figures[:protected_areas_count], delimiter: ',')
      )
      restricted_data = if figures[:oecms_count].positive?
        I18n.t(
          'country.message.restricted.protected_areas_and_oecms',
          protected_areas: protected_areas_msg,
          oecms: number_to_delimited(figures[:oecms_count], delimiter: ',')
        )
      else
        protected_areas_msg
      end

      I18n.t(
        'country.message.restricted.body',
        country_name: country_name,
        restricted_data: restricted_data
      )
    end
  end
end
