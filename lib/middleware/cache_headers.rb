module Middleware
  # Sets one long-lived Cache-Control by path. Runs ahead of ActionDispatch::Static
  # and last on the way out, so it overrides whatever downstream set -- a
  # controller's own header included.
  #
  # Safe only for urls that change when their content changes. Never add a stable one.
  #
  #   long_lived (here)      /vite/assets/*, /vite-dev/assets/*,
  #                          /assets/<name>-<digest>.<ext> (flags, logos, comfy)
  #   max-age=0 (env files)  the rest of public/ -- favicon.ico, manifest.json,
  #                          robots.txt, images/, fonts/, icons/, /vite/ root
  #   not ours               /vite-dev/entrypoints/*  Vite dev server, no-cache
  #                          /assets/flags/ITA.svg    Sprockets, must-revalidate
  #                          /assets/tiles/*          AssetsController (sets long_lived itself)
  #                          html, /sitemap*.xml, /downloads/*  own policies
  #
  # dev vs staging/production:
  #   - dev applies none of this unless tmp/caching-dev.txt exists
  #   - dev serves /assets/* from a Sprockets mount (assets.compile); staging and
  #     production serve public/assets via Static, where the non-digested twin 404s
  #   - dev serves js/css from the Vite dev server unless that container is stopped
  class CacheHeaders
    # max-age comes from app_secrets (browser_cache_max_age). Read lazily, not into
    # a constant: AppSecrets is an initializer, so it does not exist when this file
    # is required. Fallback keeps a missing key from shipping a bare "max-age=".
    FALLBACK_MAX_AGE = 31_536_000

    PATHS = [
      %r{\A/vite/assets/},     # vite build output, all hashed
      %r{\A/vite-dev/assets/}, # dev build output, only served when vite is off
      # Digest required, not the bare prefix: every Sprockets asset also answers its
      # non-digested (stable) url, and /assets/tiles/ must stay with its controller.
      %r{\A/assets/.+-[0-9a-f]{32,64}\.\w+\z}
    ].freeze

    # Not 404 (a miss falls through to routing) and not 302 (the tile placeholder).
    CACHEABLE_STATUSES = [200, 304].freeze

    CACHE_CONTROL = 'cache-control'.freeze

    def self.long_lived
      @long_lived ||= "public, max-age=#{max_age}, must-revalidate"
    end

    def self.max_age
      AppSecrets.browser_cache_max_age.presence&.to_i || FALLBACK_MAX_AGE
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      # Read before the call: a mounted app (Sprockets at /assets) rewrites
      # PATH_INFO in place.
      path = env['PATH_INFO']

      @app.call(env).tap do |status, headers, _body|
        next unless CACHEABLE_STATUSES.include?(status)
        next unless fingerprinted?(path)

        # Rack 2 header keys are case-sensitive; plain assignment would send two.
        headers.delete_if { |name, _| name.to_s.downcase == CACHE_CONTROL }
        headers[CACHE_CONTROL] = self.class.long_lived
      end
    end

    private

    def fingerprinted?(path)
      return false if path.nil?

      PATHS.any? { |pattern| path.match?(pattern) }
    end
  end
end
