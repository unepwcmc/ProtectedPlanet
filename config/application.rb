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

    # Rails 6.0 upgrade, step 2: Zeitwerk autoloading. Framework defaults stay
    # at pre-6.0 (no `config.load_defaults` call) so this step changes only the
    # autoloader -- `load_defaults 6.0` is a separate follow-up step.
    # See upgrade-plan/backend/03-rails-6.md.
    config.autoloader = :zeitwerk

    # app/presenters and app/serializers are NOT listed here: Rails 6 already adds
    # every app/* subdirectory to both autoload and eager load paths, so naming
    # them again only duplicated them across the two lists.
    # lib/cms_tags is likewise absent -- its files are explicitly required from
    # config/initializers/comfortable_mexican_sofa.rb (see the note there).
    # lib/modules is autoloaded but deliberately NOT eager loaded. Its naming has
    # been verified against Zeitwerk by temporarily adding it to eager_load_paths
    # and running `rails zeitwerk:check` (clean), but it cannot stay there:
    # Download::Generators::Shapefile computes QUERY_CONDITIONS in its class body,
    # which queries `releases`. Eager loading would make boot require a reachable,
    # migrated database. Make that constant lazy before eager loading this tree.
    config.autoload_paths += %W[#{config.root}/lib/modules]
    config.tinymce.install = :compile

    config.active_record.schema_format = :sql
  end
end
