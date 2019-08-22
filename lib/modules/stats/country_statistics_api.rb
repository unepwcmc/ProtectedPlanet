class Stats::CountryStatisticsApi
  BASE_URL = 'https://dopa-services.jrc.ec.europa.eu/services/d6dopa30/'.freeze
  ENDPOINTS = {
    representative: {
      endpoint: 'habitats_and_biotopes/get_ecoregion_all_inds',
      field: 'prot_perc'
    },
    well_connected: {
      endpoint: 'administrative_units/get_country_all_inds',
      field: 'protconn'
    },
    importance: {
      endpoint: 'administrative_units/get_country_all_inds',
      field: 'kba_avg_prot_perc'
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

  def self.get_stats(endpoint, iso3=nil)
    if iso3.present? && endpoint.to_s == 'representative'
      raise ArgumentError, ERRORS[:representative]
    end
    url = "#{BASE_URL}#{ENDPOINTS[endpoint][:endpoint]}?format=json"

    begin
      res = HTTParty.public_send('get', url)

      data = res.parsed_response['records']
      data = data.select { |d| d['country_iso3'] == iso3 } if iso3
    rescue HTTParty::Error
      return { error: ERRORS[:httparty] }
    rescue StandardError => e
      Rails.logger.info(e.backtrace)
      return { error: ERRORS[:data] }
    end

    format_data(data, endpoint)
  end

  private

  def self.format_data(data, endpoint)
    data.map do |d|
      {
        name: d['country_name'],
        iso3: d['country_iso3'],
        value: d[ENDPOINTS[endpoint][:field]]
      }
    end
  end
end
