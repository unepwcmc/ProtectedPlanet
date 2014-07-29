class ImportTools::MaintenanceSwitcher
  include Rails.application.routes.url_helpers

  def self.on
    switcher = self.new
    switcher.switch(true)
  end

  def self.off
    switcher = self.new
    switcher.switch(false)
  end

  def switch(mode_on)
    host = Rails.application.secrets.host
    authentication_key = Rails.application.secrets.maintenance_mode_key

    HTTParty.put(
      maintenance_url(host: host),
      query: {maintenance_mode_on: mode_on},
      headers: {'X-Auth-Key' => authentication_key}
    )
  end
end
