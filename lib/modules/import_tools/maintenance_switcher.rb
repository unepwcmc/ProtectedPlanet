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
    authentication_key = Rails.application.secrets.maintenance_mode_key

    HTTParty.put(
      url_for(:maintenance),
      query: {maintenance_mode_on: mode_on},
      headers: {'Authorization' => authentication_key}
    )
  end
end
