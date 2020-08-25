module Stats::CountryStatisticsApi
  class << self
    STATISTICS_API = Rails.application.secrets[:country_statistics_api].freeze
    BASE_URL = STATISTICS_API[:url].freeze

    ERRORS = {
      representative: """
        Country level stats cannot be fetched for the representative endpoint.
        Please invoke this function without an iso code.
      """,
      httparty: 'We are sorry but something went wrong while connecting to the API.',
      data: 'We are sorry but something went wrong while processing the data from the API.'
    }.freeze

    ISO3_ATTRIBUTE = STATISTICS_API[:iso3_attribute].freeze
    NAME_ATTRIBUTE = STATISTICS_API[:country_name_attribute].freeze
    COUNTRY_AREA_ATTRIBUTE = STATISTICS_API[:jrc_country_area_attribute].freeze
    TERR_AREA_ATTRIBUTE = STATISTICS_API[:jrc_terr_area_attribute].freeze


    def import(iso3 = nil)
      # Representative stat is exlcuded because that is a global level stat only
      # Connect to the API and fetch the data

      kba_data = fetch_kba_data(iso3)
      # Return if there's an error
      return kba_data if kba_data.is_a?(Hash) && kba_data.key?(:error)

      connect_data = fetch_connection_data(iso3)
      # Return if there's an error
      return connect_data if connect_data.is_a?(Hash) && connect_data.key?(:error)

      protection_data = fetch_protection_data(iso3)
      # Return if there's an error
      return protection_data if protection_data.is_a?(Hash) && protection_data.key?(:error)

      countries_not_found = []
      statistics_not_found = []

      # Update stat for each country
      Country.all.each do |country|
        iso3 = country.iso_3
        country_statistic = country.country_statistic
        # byebug

        unless country_statistic
          statistics_not_found << iso3
          next
        end

        country_kba_data = kba_data.select { |d| d[ISO3_ATTRIBUTE] == iso3 }.first
        country_connect_data = connect_data.select { |d| d[ISO3_ATTRIBUTE] == iso3 }.first
        country_protection_data = protection_data.select { |d| d[ISO3_ATTRIBUTE] == iso3 }.first

        unless (country_kba_data && country_connect_data && country_protection_data)
          countries_not_found << iso3
          next
        end

        attrs = {
          jrc_country_area: country_protection_data[COUNTRY_AREA_ATTRIBUTE],
          jrc_terr_area: country_protection_data[TERR_AREA_ATTRIBUTE]
        }

        attribute = STATISTICS_API[:well_connected][:attribute]
        attr_name = 'percentage_well_connected'

        attrs[attr_name] = country_connect_data[attribute]

        attribute = STATISTICS_API[:importance][:attribute]
        attr_name = 'percentage_importance'

        attrs[attr_name] = country_kba_data[attribute]

        country_statistic.update_attributes(attrs)
      end

      log_not_found_objects('country', countries_not_found)
      log_not_found_objects('statistic', statistics_not_found)
    end

    def global_stats_for_import
      global_stats = fetch_global_stats do |data, attr_name|
        column_name = "#{attr_name}_global_value"
        { "#{column_name}" => calculate_value(data, attr_name) }
      end
      global_stats.inject(:merge)
    end

    def get_global_stats
      fetch_global_stats do |data, attr_name|
        format_data(data, attr_name)
      end
    end

    def fetch_global_stats(endpoint=nil)
      endpoints = endpoint ? Aichi11Target::ATTRIBUTES.slice(endpoint.to_sym) : Aichi11Target::ATTRIBUTES
      global_stats = []
      endpoints.keys.each do |name|
        data = fetch_national_data

        # Return if there's an error
        return data if data.nil? || (data.is_a?(Hash) && data.key?(:error))

        global_stats << yield(data, name)
      end
      global_stats
    end

    def format_data(data, endpoint)
      Aichi11TargetSerializer.new.format_data(endpoint) do
        calculate_value(data, endpoint)
      end
    end

    private

    def calculate_value(data, attr_name)
      stat_attributes = STATISTICS_API[attr_name]
      attribute = stat_attributes["attribute"]
      area_attribute = stat_attributes["area_attribute"] || COUNTRY_AREA_ATTRIBUTE

      attr_area_sum = total_area_sum = 0
      data.map do |x|
        next if contains_exception?(x, attr_name)
        attr_perc = x[attribute] || 0
        total_area = x[area_attribute] || 0
        attr_area_sum += attr_perc * total_area / 100
        total_area_sum += total_area
      end
      begin
        (attr_area_sum / total_area_sum * 100).round(2)
      rescue ZeroDivisionError => e
        Rails.logger.info(e.backtrace)
        return { error: ERRORS[:data] }
      end
    end

    def endpoint_url(end_type)
      endpoint = STATISTICS_API[:"#{end_type}_endpoint"]
      "#{BASE_URL}#{endpoint}"
    end

    def fetch_protection_data(iso3 = nil)
      fetch('prot', iso3)
    end

    def fetch_kba_data(iso3 = nil)
      fetch('kba', iso3)
    end

    def fetch_connection_data(iso3 = nil)
      fetch('conn', iso3)
    end

    def fetch(endpoint, iso3 = nil)
      url = endpoint_url(endpoint)
      begin
        res = HTTParty.public_send('get', url)

        data = res.parsed_response['records']
        data = data.select { |d| d[ISO3_ATTRIBUTE] == iso3 } if iso3
      rescue HTTParty::Error
        return { error: ERRORS[:httparty] }
      rescue StandardError => e
        Rails.logger.info(e.backtrace)
        return { error: ERRORS[:data] }
      end
      data
    end

    def contains_exception?(stat, attr_name)
      attr_name.to_s == 'well_connected' && stat[ISO3_ATTRIBUTE] == 'ATA'
    end

    def log_not_found_objects(obj, records)
      return if records.empty?
      Rails.logger.info(not_found_error(obj, records.join(',')))
    end

    def not_found_error(obj, iso_codes)
      "#{obj} with iso code #{iso_codes} has been fetched from the DB but not found in the API data."
    end
  end
end
