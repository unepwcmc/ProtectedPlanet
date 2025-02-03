require_relative 'boot'

# Enable profiling for Garbage Collection (and
# get all the information on Newrelic
GC::Profiler.enable

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ProtectedPlanet
  class Application < Rails::Application
    # Ensuring that ActiveStorage routes are loaded before Comfy's globbing
    # route. Without this file serving routes are inaccessible.
    config.railties_order = [ActiveStorage::Engine, :main_app, :all]
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths += %W(
      #{config.root}/lib/modules
      #{config.root}/lib/cms_tags
      #{config.root}/app/presenters
      #{config.root}/app/serializers
    )
    # config.assets.paths << Rails.root.join('node_modules')
    config.assets.precompile += %w(base.js country.js home.js map.js protected_areas.js search.js resources.js content.js marine.js green_list.js region.js target_dashboard.js)
    config.assets.precompile += %w(d3/d3.js)
    config.assets.precompile += %w(d3/d3.min.js)
    config.tinymce.install = :compile

    config.active_record.schema_format = :sql
  end
end
