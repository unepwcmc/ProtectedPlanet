Raygun.setup do |config|
  config.api_key = Rails.application.secrets.raygun_api_key
  config.filter_parameters = Rails.application.config.filter_parameters
end
