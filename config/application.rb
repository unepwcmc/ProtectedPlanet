require File.expand_path('../boot', __FILE__)

# Enable profiling for Garbage Collection (and
# get all the information on Newrelic
GC::Profiler.enable

require 'rails/all'
require_relative "../lib/modules/rack_x_robots_tag"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ProtectedPlanet
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.middleware.use Rack::XRobotsTag

    config.autoload_paths += %W(#{config.root}/lib/modules #{config.root}/app/presenters)
    config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components')
    config.assets.precompile += %w(base.js country.js home.js map.js protected_areas.js search.js resources.js content.js)
    config.assets.precompile += %w(protectedplanet-frontend/dist/*)
    config.assets.precompile += %w(html5shiv/dist/*)
    config.tinymce.install = :compile

    config.active_record.schema_format = :sql

    config.to_prepare do
      Devise::Mailer.layout "mailer"
    end
  end
end
