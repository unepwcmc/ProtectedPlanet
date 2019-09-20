module Stats::CountryStatisticsApi
  class << self
    STATISTICS_API = Rails.application.secrets[:country_statistics_api].freeze
    BASE_URL = STATISTICS_API['url'].freeze
    ATTRIBUTES = {
      representative: {
        name: 'Representative',
        slug: 'representative',
        attribute: STATISTICS_API['representative_attribute']
      },
      well_connected: {
        name: 'Well connected',
        slug: 'well_connected',
        attribute: STATISTICS_API['well_connected_attribute']
      },
      importance: {
        name: 'Areas of importance for biodiversity',
        slug: 'importance',
        attribute: STATISTICS_API['importance_attribute']
      }
    }

    ERRORS = {
      representative: """
        Country level stats cannot be fetched for the representative endpoint.
        Please invoke this function without an iso code.
      """,
      httparty: 'We are sorry but something went wrong while connecting to the API.',
      data: 'We are sorry but something went wrong while processing the data from the API.'
    }.freeze

    ISO3_ATTRIBUTE = STATISTICS_API['iso3_attribute'].freeze
    NAME_ATTRIBUTE = STATISTICS_API['country_name_attribute'].freeze
    COUNTRY_AREA_ATTRIBUTE = STATISTICS_API['jrc_country_area_attribute'].freeze


    def import(iso3=nil)
      endpoints = ATTRIBUTES.slice(:well_connected, :importance)
      # Get stats for each endpoint
      # Representative stat is exlcuded because that is a global level stat
      # Connect to the API and fetch the data
      data = fetch_national_data(iso3)

      # Return if there's an error
      return data if data.is_a?(Hash) && data.key?(:error)

      countries_not_found = []
      statistics_not_found = []

      # Update stat for each country
      data.each do |stat|

        _iso3 = stat[ISO3_ATTRIBUTE]
        next if _iso3.split('|').length > 1

        country = Country.find_by_iso_3(_iso3)
        unless country
          countries_not_found << _iso3
          next
        end

        country_statistic = country.country_statistic
        unless country_statistic
          statistics_not_found << _iso3
          next
        end

        attrs = { jrc_country_area: stat[COUNTRY_AREA_ATTRIBUTE] }
        endpoints.each do |name, attributes|
          attribute = attributes[:attribute]
          attr_name = "percentage_#{name}"

          attrs[attr_name] = stat[attribute]
        end

        country_statistic.update_attributes(attrs)
      end

      log_not_found_objects('country', countries_not_found)
      log_not_found_objects('statistic', statistics_not_found)
    end

    def get_global_stats(endpoint=nil)
      endpoints = endpoint ? ATTRIBUTES.slice(endpoint.to_sym) : ATTRIBUTES
      global_stats = []
      endpoints.each do |name, attributes|
        data = fetch_global_data

        # Return if there's an error
        return data if data.nil? || (data.is_a?(Hash) && data.key?(:error))

        data = data.reject { |stat| contains_exception?(stat) }
        global_stats << format_data(data, name)
      end
      global_stats
    end

    private

    # This is only used for global stats
    def format_data(data, endpoint)
      json = {
        id: ATTRIBUTES[endpoint.to_sym][:slug],
        title: ATTRIBUTES[endpoint.to_sym][:name],
        charts: []
      }
      chart_json = Aichi11Target::DEFAULT_CHART_JSON.dup
      attribute = ATTRIBUTES[endpoint.to_sym][:attribute]

      attr_area_sum = total_area_sum = 0
      data.map do |x|
        attr_area = x[attribute] || 0
        total_area = x[COUNTRY_AREA_ATTRIBUTE] || 0
        attr_area_sum += attr_area * total_area / 100
        total_area_sum += total_area
      end
      value = 0
      begin
        value = (attr_area_sum / total_area_sum * 100).round(2)
      rescue ZeroDivisionError => e
        Rails.logger.info(e.backtrace)
        return { error: ERRORS[:data] }
      end
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
