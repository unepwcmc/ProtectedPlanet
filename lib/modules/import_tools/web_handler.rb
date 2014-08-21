class ImportTools::WebHandler
  include Rails.application.routes.url_helpers

  def self.maintenance_on
    web_handler = self.new
    web_handler.maintenance_mode = true
    web_handler
  end

  def self.maintenance_off
    web_handler = self.new
    web_handler.maintenance_mode = false
    web_handler
  end

  def self.under_maintenance
    maintenance_on
    yield
    maintenance_off
  end

  def self.clear_cache
    web_handler = self.new
    web_handler.clear_cache
    web_handler
  end

  def maintenance_mode=(mode_on)
    admin_request(:put, :maintenance_url, {maintenance_mode_on: mode_on})
  end

  def clear_cache
    admin_request(:put, :clear_cache_url)
  end

  private

  def admin_request method, url, query={}
    host = Rails.application.secrets.host
    url = send(url, host: host)

    authentication_key = Rails.application.secrets.maintenance_mode_key
    headers = {'X-Auth-Key' => authentication_key}

    HTTParty.public_send(method, url, query: query, headers: headers)
  end
end
