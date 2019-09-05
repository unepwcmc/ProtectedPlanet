class Stats::CountryStatisticsApi
  STATISTICS_API = Rails.application.secrets[:country_statistics_api].freeze
  BASE_URL = STATISTICS_API['url'].freeze
  ENDPOINTS = {
    representative: {
      endpoint: STATISTICS_API['global_endpoint'],
      field: STATISTICS_API['representative_field']
    },
    well_connected: {
      endpoint: STATISTICS_API['national_endpoint'],
      field: STATISTICS_API['well_connected_field']
    },
    importance: {
      endpoint: STATISTICS_API['national_endpoint'],
      field: STATISTICS_API['importance_field']
    }
  }.freeze

  ERRORS = {
    representative: """
      Country level stats cannot be fetched for the representative endpoint.
      Please invoke this function without an iso code.
    """,
    httparty: 'We are sorry but something went wrong while connecting to the API.',
    data: 'We are sorry but something went wrong while processing the data from the API.',
  }.freeze

  ISO3_ATTRIBUTE = 'country_iso3'.freeze
  NAME_ATTRIBUTE = 'country_name'.freeze

  def self.import(iso3=nil)
    endpoints = ENDPOINTS.slice(:well_connected, :importance)
    # Get stats for each endpoint
    # Representative stat is exlcuded because that is a global level stat
    endpoints.each do |name, attributes|
      url = endpoint_url(attributes[:endpoint])
      # Connect to the API and fetch the data
      data = fetch(url, iso3)

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

  def self.get_stats(endpoint, iso3=nil)
    if iso3.present? && endpoint.to_s == 'representative'
      raise ArgumentError, ERRORS[:representative]
    end
    url = endpoint_url(ENDPOINTS[endpoint.to_sym][:endpoint])
    data = fetch(url, iso3)

    return data if data.is_a?(Hash) && data.key?(:error)

    format_data(data, endpoint)
  end

  private

  def self.format_data(data, endpoint)
    field = ENDPOINTS[endpoint.to_sym][:field]
    if endpoint.to_s == 'representative'
      _sum = data.inject(0) do |sum, x|
        sum + (x[field] ? x[field] : 0)
      end
      # TODO Need to confirm if this is the correct calculation
      value = (_sum / data.length).round(2)
      { value: value }
    else
      data.map do |d|
        {
          name: d[NAME_ATTRIBUTE],
          iso3: d[ISO3_ATTRIBUTE],
          value: d[field]
        }
      end
    end
  end

  def self.endpoint_url(endpoint)
    "#{BASE_URL}#{endpoint}?format=json"
  end

  def self.fetch(url, iso3 = nil)
    begin
      res = HTTParty.public_send('get', url)

      data = res.parsed_response['records']
      data =  data.select { |d| d[ISO3_ATTRIBUTE] == iso3 } if iso3
    rescue HTTParty::Error
      return { error: ERRORS[:httparty] }
    rescue StandardError => e
      Rails.logger.info(e.backtrace)
      return { error: ERRORS[:data] }
    end
    data
  end

  def self.log_not_found_objects(obj, records)
    return if records.empty?
    Rails.logger.info(not_found_error(obj, records.join(',')))
  end

  def self.not_found_error(obj, iso_codes)
    "#{obj} with iso code #{iso_codes} has been fetched from the API but not found in the database."
  end
end
