require_relative 'boot'

# Enable profiling for Garbage Collection (and
# get all the information on Newrelic
GC::Profiler.enable

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# Not autoloadable: lib/ is not an autoload path, and the environment files insert
# this as middleware at config time, before any autoloader exists. Required here
# rather than per-environment because AssetsController references long_lived, so it
# has to resolve in test too.
require_relative '../lib/middleware/cache_headers'

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

    config.load_defaults 8.1

    # Two 8.1 defaults are worth knowing about here.
    #
    # `config.yjit = !Rails.env.local?` is inert on this image: the Ruby 3.3.7
    # build in the Dockerfile is compiled without YJIT (`RubyVM::YJIT` is not
    # defined), and railties guards the initializer on
    # `defined?(RubyVM::YJIT.enable)` -- so staging and production get no YJIT
    # and no error. Rebuilding Ruby with --enable-yjit is what would turn it on.
    #
    # `action_on_path_relative_redirect = :raise` turns any `redirect_to` with a
    # path-relative string into a PathRelativeRedirectError. Every literal
    # redirect in this app is absolute; the two rescue handlers that redirect to
    # the client-supplied Referer header now go through
    # ApplicationController#safe_referrer_path, which handles both this and the
    # off-host case. See the note there.

    # Opted out of one default. Every belongs_to foreign key in this schema is
    # nullable, so nothing at the database level backs a presence validation, and
    # the WDPA importer legitimately produces NULLs -- Wdpa::Portal::Relation::
    # ProtectedArea#designation assigns a nil jurisdiction when the source row has
    # none (57 of 1831 designations in the dev database). Turning this on would
    # fail those imports. Tightening the ~35 associations individually is a data
    # integrity exercise that needs measuring against a full production dump, not
    # a side effect of the framework bump.
    config.active_record.belongs_to_required_by_default = false

    # app/presenters and app/serializers are NOT listed here: Rails 6 already adds
    # every app/* subdirectory to both autoload and eager load paths, so naming
    # them again only duplicated them across the two lists.
    # lib/cms_tags is likewise absent -- its files are explicitly required from
    # config/initializers/comfortable_mexican_sofa.rb (see the note there).
    # lib/modules is eager loaded so `rails zeitwerk:check` covers it and so its
    # constants are not autoloaded on demand from request threads. This is only
    # safe now that the download generators build their query conditions lazily
    # -- as class-body constants they queried `releases`, which would have made
    # boot require a reachable, migrated database.
    config.autoload_paths += %W[#{config.root}/lib/modules]
    config.eager_load_paths += %W[#{config.root}/lib/modules]

    config.active_record.schema_format = :sql

    # secret_key_base used to come from config/secrets.yml via Rails' auto-load. That
    # is deprecated (7.1) / removed (7.2), and we renamed the file to app_secrets.yml,
    # so set it explicitly from the same YAML (ENV-driven for prod/staging).
    #
    # Only assign when we actually have one. `assets:precompile` in the deploy image
    # runs with SECRET_KEY_BASE unset and SECRET_KEY_BASE_DUMMY=1 -- Rails' escape
    # hatch for generating a throwaway key at build time. Assigning nil here bypasses
    # that hatch: Rails 8's secret_key_base= raises on a blank value outside dev/test,
    # which broke the image build. Leaving it unset lets Rails resolve it itself
    # (SECRET_KEY_BASE_DUMMY at build, ENV["SECRET_KEY_BASE"] at runtime).
    if (key = config_for(:app_secrets)[:secret_key_base]).present?
      config.secret_key_base = key
    end

    # Host for absolute URL generation outside a request -- only
    # Download::Generators::Pdf needs it (every other route-helper call site is
    # either in a request or uses a *_path helper). Resolved once here rather than
    # per call: config_for re-parses the YAML and its ERB every time.
    config.x.app_host = config_for(:app_secrets)[:host]
  end
end
