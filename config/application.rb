require_relative 'boot'

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
    # ActiveStorage's routes must load before Comfy's globbing route, or file
    # serving is unreachable.
    config.railties_order = [ActiveStorage::Engine, :main_app, :all]

    config.load_defaults 8.1

    # One 8.1 default worth knowing about: `action_on_path_relative_redirect =
    # :raise` turns any `redirect_to` with a path-relative string into a
    # PathRelativeRedirectError. Every literal redirect here is absolute; the two
    # rescue handlers that redirect to the client-supplied Referer header go
    # through ApplicationController#safe_referrer_path, which handles this and the
    # off-host case. See the note there.

    # Opted out of one default. Every belongs_to foreign key in this schema is
    # nullable, so nothing at the database level backs a presence validation, and
    # the WDPA importer legitimately produces NULLs -- Wdpa::Portal::Relation::
    # ProtectedArea#designation assigns a nil jurisdiction when the source row has
    # none (57 of 1831 designations in the dev database). Turning this on would
    # fail those imports. Tightening the ~35 associations individually is a data
    # integrity exercise that needs a full production dump to measure against, not
    # a side effect of the framework bump.
    config.active_record.belongs_to_required_by_default = false

    # app/presenters and app/serializers are NOT listed here: Rails 6 already adds
    # every app/* subdirectory to both autoload and eager load paths.
    # lib/cms_tags is likewise absent -- its files are explicitly required from
    # config/initializers/comfortable_media_surfer.rb (see the note there).
    # lib/modules is eager loaded so `rails zeitwerk:check` covers it and so its
    # constants are not autoloaded on demand from request threads. Only safe now
    # that the download generators build their query conditions lazily -- as
    # class-body constants they queried `releases`, which would have made boot
    # require a reachable, migrated database.
    config.autoload_paths += %W[#{config.root}/lib/modules]
    config.eager_load_paths += %W[#{config.root}/lib/modules]

    config.active_record.schema_format = :sql

    # secret_key_base used to come from config/secrets.yml via Rails' auto-load,
    # which is deprecated (7.1) and removed (7.2); the file is now app_secrets.yml.
    #
    # Only assign when we actually have one. `assets:precompile` in the deploy image
    # runs with SECRET_KEY_BASE unset and SECRET_KEY_BASE_DUMMY=1 -- Rails' escape
    # hatch for a throwaway build-time key. Assigning nil bypasses that hatch:
    # Rails 8's secret_key_base= raises on a blank value outside dev/test, which
    # broke the image build. Leaving it unset lets Rails resolve it itself.
    if (key = config_for(:app_secrets)[:secret_key_base]).present?
      config.secret_key_base = key
    end

    # Host for absolute URL generation outside a request -- only
    # Download::Generators::Pdf needs it. Resolved once here rather than per call:
    # config_for re-parses the YAML and its ERB every time.
    config.x.app_host = config_for(:app_secrets)[:host]
  end
end
