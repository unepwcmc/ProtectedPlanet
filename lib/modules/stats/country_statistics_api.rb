module Stats::CountryStatisticsApi
  class << self
    STATISTICS_API = Rails.application.secrets[:country_statistics_api].freeze
    BASE_URL = STATISTICS_API['url'].freeze
    ENDPOINTS = {
      representative: {
        name: 'Representative',
        slug: 'representative',
        field: STATISTICS_API['representative_field']
      },
      well_connected: {
        name: 'Well connected',
        slug: 'well_connected',
        field: STATISTICS_API['well_connected_field']
      },
      importance: {
        name: 'Areas of importance for biodiversity',
        slug: 'importance',
        field: STATISTICS_API['importance_field']
      }
    }.freeze

    ERRORS = {
      representative: """
        Country level stats cannot be fetched for the representative endpoint.
        Please invoke this function without an iso code.
      """,
      httparty: 'We are sorry but something went wrong while connecting to the API.',
      data: 'We are sorry but something went wrong while processing the data from the API.'
    }.freeze

    ISO3_ATTRIBUTE = 'country_iso3'.freeze
    NAME_ATTRIBUTE = 'country_name'.freeze

    def import(iso3=nil)
      endpoints = ENDPOINTS.slice(:well_connected, :importance)
      # Get stats for each endpoint
      # Representative stat is exlcuded because that is a global level stat
      endpoints.each do |name, attributes|
        # Connect to the API and fetch the data
        data = fetch_national_data(iso3)

        # Return if there's an error
        return data if data.is_a?(Hash) && data.key?(:error)

        # Update stat for each country
        countries_not_found = []
        statistics_not_found = []
        data.each do |stat|
          _iso3 = stat[ISO3_ATTRIBUTE]
          next if _iso3.split('|').length > 1

          country = Country.find_by_iso_3(_iso3)
          unless country
            countries_not_found << _iso3
            next
          end

          field = attributes[:field]
          country_statistic = country.country_statistic
          unless country_statistic
            statistics_not_found << _iso3
            next
          end

          attr_name = "percentage_#{name}"
          country_statistic.update_attributes("#{attr_name}" => stat[field])
        end

        log_not_found_objects('country', countries_not_found)
        log_not_found_objects('statistic', statistics_not_found)
      end
    end

    def get_global_stats(endpoint=nil)
      endpoints = endpoint ? ENDPOINTS.slice(endpoint.to_sym) : ENDPOINTS
      global_stats = []
      endpoints.each do |name, attributes|
        data = fetch_global_data

        # Return if there's an error
        return data if data.is_a?(Hash) && data.key?(:error)

        data = data.reject { |stat| contains_exception?(stat) }
        global_stats << format_data(data, name)
      end
      global_stats
    end

    private

    # This is only used for global stats
    def format_data(data, endpoint)
      stat = ENDPOINTS[endpoint.to_sym]
      json = { id: stat[:slug], title: stat[:name], charts: [] }
      chart_json = Aichi11Target::DEFAULT_CHART_JSON.dup
      field = stat[:field]

      _sum = data.inject(0) do |sum, x|
        sum + (x[field] ? x[field] : 0)
      end
      value = (_sum / data.length).round(2)
      target = Aichi11Target.instance.public_send("#{endpoint.to_s}_global")
      json[:charts] << chart_json.merge!({ value: value, target: target })
      json
    end

    def national_endpoint_url
      "#{BASE_URL}#{STATISTICS_API['national_endpoint']}?format=json"
    end

    def global_endpoint_url
      "#{BASE_URL}#{STATISTICS_API['global_endpoint']}?format=json"
    end

    def fetch_national_data(iso3=nil)
      fetch('national', iso3)
    end

    def fetch_global_data
      fetch('global')
    end

    def fetch(endpoint, iso3 = nil)
      url = send("#{endpoint}_endpoint_url")
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

    EXCEPTIONS = {
      eco_name: ['Lake', 'Rock and Ice', 'Antarctic'],
      realm_name: ['Antarctic']
    }.freeze
    def contains_exception?(stat)
      EXCEPTIONS.map do |field, values|
        return true if values.include?(stat[field.to_s])
      end
      false
    end

    def log_not_found_objects(obj, records)
      return if records.empty?
      Rails.logger.info(not_found_error(obj, records.join(',')))
    end

    def not_found_error(obj, iso_codes)
      "#{obj} with iso code #{iso_codes} has been fetched from the API but not found in the database."
    end
  end
end
