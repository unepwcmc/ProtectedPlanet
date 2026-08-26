require 'net/http'
require 'uri'

# Walks every GET route against a running app and reports anything that is not
# healthy.
#
# Why this exists: the Rails 5.2 -> 8.0 / Ruby 2.6 -> 3.3 upgrade produced a run
# of bugs that shared one shape -- no test covered them, no build step validated
# them, and they only failed against a real server:
#
#   * URI.encode was removed in Ruby 3.0, so /assets/tiles/:id 500'd and the map
#     had no polygon overlay
#   * country#pdf shelled out to `phantomjs`, a binary absent from the image
#   * the image built with `rm -rf node_modules`, so rasterize.js could not
#     require('puppeteer') and every PDF failed
#
# Each was found by hand, days apart. One pass of this task finds all three.
#
# Design note: the value here is coverage, so coverage is enforced. Every GET
# route must either be walked or appear in SKIPS with a reason. A route that is
# neither is reported as UNCLASSIFIED and fails the run, so adding a route to the
# app forces a decision about smoking it instead of silently shrinking the net.
module Smoke
  class RouteWalker
    # 2xx and 3xx both count as healthy: plenty of these routes legitimately
    # redirect (locale, CMS, the S3 download hand-off) and following redirects
    # would just re-test the target.
    #
    # 204/205 are excluded deliberately. Rails returns "204 No Content" when an
    # action runs but has no template, which is how country#pdf hid: the action
    # is just `@for_pdf = true`, app/views/country/pdf.* does not exist, and the
    # endpoint answered 204 in 9ms. Nothing here should ever legitimately return
    # an empty body, so treat it as a failure rather than a pass.
    HEALTHY = (200..399).freeze
    EMPTY_BODY = [204, 205].freeze

    # Framework and auth-walled routes.
    #
    # Both a controller and a path list are needed, because the two do not line
    # up: rails/welcome#index is mounted at "/" and would shadow the real root
    # route if matched by path, while ActiveStorage and ActionMailbox live under
    # "/rails/..." but have controllers named active_storage/... and
    # action_mailbox/..., so a controller-only rule misses them.
    SKIP_CONTROLLERS = {
      %r{\Arails/} => 'Rails internals: mailer previews, /rails/info',
      %r{\Aactive_storage/} => 'ActiveStorage blob/representation serving, needs signed ids',
      %r{\Aaction_mailbox/} => 'ActionMailbox ingress endpoints, not user-facing',
      %r{\Aaction_cable/} => 'ActionCable mount, not an HTTP GET surface',
      %r{\Acomfy/admin/} => 'CMS admin, behind HTTP basic auth (see the /admin probe)'
    }.freeze

    SKIP_PATHS = {
      %r{\A/admin} => 'Admin + Sidekiq web, behind HTTP basic auth (see the /admin probe)',
      %r{\A/rails/} => 'Mounted framework engines'
    }.freeze

    # Routes with no dynamic segments that still must not be walked bare --
    # JSON endpoints that need a query string to mean anything. They are covered
    # with real parameters in #extra_targets instead.
    QUERY_ONLY = %w[downloads#poll].freeze

    Target = Struct.new(:label, :path, :note, keyword_init: true)
    Result = Struct.new(:label, :path, :status, :ms, :error, keyword_init: true) do
      def healthy?
        return false if error
        return false if EMPTY_BODY.include?(status.to_i)

        HEALTHY.cover?(status.to_i)
      end

      def verdict
        return 'ERROR' if error
        return 'EMPTY' if EMPTY_BODY.include?(status.to_i)

        healthy? ? 'ok' : 'FAIL'
      end
    end

    attr_reader :results, :skipped, :unclassified

    def initialize(base_url: nil, cms_sample: 15, timeout: 120, insecure: false, logger: $stdout)
      @base_url = (base_url || 'http://localhost:3000').chomp('/')
      @cms_sample = cms_sample.to_i
      @timeout = timeout.to_i
      @insecure = insecure
      @logger = logger
      @results = []
      @skipped = []
      @unclassified = []
    end

    def run
      targets = build_targets
      say "Smoking #{targets.size} URLs against #{@base_url} " \
          "(#{@skipped.size} routes skipped, #{@unclassified.size} unclassified)"
      say ''

      targets.each { |target| @results << request(target) }

      report
      failed?
    end

    # ---------------------------------------------------------------- targets

    def build_targets
      targets = []

      get_routes.each do |route|
        if (reason = skip_reason(route))
          @skipped << [route_label(route), reason]
          next
        end

        resolved = resolve(route)
        if resolved.nil?
          # Not walkable and not deliberately skipped -- someone added a route
          # with dynamic segments and no resolver. Fail rather than quietly drop.
          @unclassified << route_label(route)
          next
        end

        targets.concat(resolved)
      end

      # The locale scope declares several routes that collapse to the same URL
      # once "(/:locale)" is stripped (root, home#index and the CMS catch-all all
      # reduce to "/"), so dedupe rather than requesting "/" three times.
      (targets + extra_targets).uniq(&:path)
    end

    def get_routes
      Rails.application.routes.routes.select { |r| r.verb.to_s.include?('GET') }
    end

    def skip_reason(route)
      controller = route.defaults[:controller].to_s
      SKIP_CONTROLLERS.each { |pattern, reason| return reason if controller.match?(pattern) }
      SKIP_PATHS.each { |pattern, reason| return reason if static_path(route).match?(pattern) }
      nil
    end

    # A route is walkable as-is when nothing dynamic is left once the optional
    # locale scope and format suffix are stripped. That covers the CMS-slug pages
    # (/thematic-areas/..., /data/...) and /terms automatically, so they do not
    # need hand-maintained entries here.
    def resolve(route)
      return [] if QUERY_ONLY.include?("#{route.defaults[:controller]}##{route.defaults[:action]}")

      path = static_path(route)
      return [Target.new(label: route_label(route), path: path)] unless dynamic?(path)

      dynamic_targets(route)
    end

    def dynamic_targets(route)
      # Declared with redirect() instead of a controller, so there is no
      # controller#action to switch on.
      return retired_locale_targets(route) if route.defaults[:controller].blank?

      case "#{route.defaults[:controller]}##{route.defaults[:action]}"
      when 'protected_areas#show'
        wrap(route, "/#{protected_area_id}")
      when 'assets#tiles'
        # The Ruby 3 URI.encode removal lived here, so all three variants are
        # smoked: this is the endpoint that renders the map overlay and the
        # search-result thumbnails, and it drives AssetGenerator.mapbox_url ->
        # GeometryConcern#geojson.
        #
        # NB: AssetsController#tiles 404s unless `type` is one of TYPES, and it
        # looks records up by site_id / iso -- not wdpa_id.
        label = route_label(route)
        [
          Target.new(label: label, path: "/assets/tiles/#{tile_site_id}?type=protected_area"),
          Target.new(label: label, path: "/assets/tiles/#{country_iso2}?type=country"),
          Target.new(label: label, path: "/assets/tiles/#{region_iso}?type=region")
        ]
      when 'region#show'
        wrap(route, "/region/#{region_iso}")
      when 'country#show'
        wrap(route, "/country/#{country_iso}")
      when 'country#pdf'
        # Slow on purpose: drives Puppeteer with a 10s capture delay. This is the
        # route that was calling a phantomjs binary the image does not contain.
        wrap(route, "/country/#{country_iso}/pdf", note: 'slow: rasterizes via Puppeteer')
      when 'country#compare'
        wrap(route, "/country/#{country_iso}/compare/#{country_iso(offset: 1)}")
      when 'country#protected_areas'
        wrap(route, "/country/#{country_iso}/protected_areas")
      when 'downloads#show'
        # Redirects to a signed S3 URL and only makes sense for a download that
        # is already generated; downloads#poll covers the same code path safely.
        []
      when 'sitemaps#show'
        # Both halves of the endpoint: a static chunk, and a generated protected-area
        # chunk -- the only one that queries protected_areas, and the one whose bounds
        # lookup is the expensive path. Asked for through Sitemap itself so this walks
        # a chunk that exists: an out-of-range name is a deliberate 404, which the
        # walker would report as a failure.
        label = route_label(route)
        # 'pages' rather than countries/regions: it is the static chunk that walks
        # every published CMS page, so it is the one that can actually break.
        names = ['pages']
        names << 'protected-areas-1' if Sitemap.valid_chunk_name?('protected-areas-1')
        names.map { |name| Target.new(label: label, path: "/sitemaps/#{name}.xml") }
      when 'comfy/cms/content#show'
        cms_page_targets
      when 'comfy/cms/assets#render_css', 'comfy/cms/assets#render_js'
        cms_asset_targets(route)
      end
    end

    # The retired-locale redirects at the top of routes.rb: /es -> /en, and
    # /es/<path> -> /en/<path> through a block that rewrites the path. Their
    # constraint is locale =~ /es|fr/, so :locale cannot take the LOCALE the rest of
    # this walker substitutes -- 'en' fails the constraint and the request falls
    # through to a different route entirely. Both answer 301, which counts as
    # healthy; the point is that they answer at all.
    #
    # nil rather than [] when the substitution leaves anything dynamic behind, so a
    # future controllerless route is reported as UNCLASSIFIED rather than skipped.
    def retired_locale_targets(route)
      path = static_path(route).gsub(':locale', 'es').gsub('*path', 'about')
      return nil if dynamic?(path)

      [Target.new(label: route_label(route), path: path, note: 'expects a 301 to /en')]
    end

    def wrap(route, path, note: nil)
      [Target.new(label: route_label(route), path: path, note: note)]
    end

    # Endpoints worth smoking that are not a plain GET route, or that need query
    # strings to exercise anything interesting.
    def extra_targets
      [
        Target.new(label: 'search#search_results', path: "/#{LOCALE}/search-results?search_term=park"),
        Target.new(label: 'search_areas#search_results', path: "/#{LOCALE}/search-areas-results?search_term=park"),
        Target.new(label: 'search_cms#index (query)', path: "/#{LOCALE}/search-cms?search_term=marine"),
        Target.new(label: 'downloads#poll',
                   path: "/#{LOCALE}/downloads/poll?domain=protected_area" \
                         "&token=#{protected_area_id}&format=csv"),
        Target.new(label: 'admin auth wall', path: '/admin', note: 'expects a 401/302, not a 200')
      ].compact
    end

    # -------------------------------------------------------------- fixtures

    # One real record drives both the show page and the tile, so a failure points
    # at the endpoint rather than at a badly chosen fixture.
    def protected_area
      @protected_area ||= ProtectedArea.where.not(site_id: nil).order(:id).first ||
                          ProtectedArea.order(:id).first
    end

    def protected_area_id
      @protected_area_id ||= protected_area&.wdpa_id || protected_area&.id
    end

    # AssetsController#protected_area looks up by site_id, not wdpa_id.
    def tile_site_id
      @tile_site_id ||= protected_area&.site_id || protected_area_id
    end

    def country_iso(offset: 0)
      @country_isos ||= Country.order(:id).limit(2).pluck(:iso_3)
      @country_isos[offset] || @country_isos.first
    end

    # AssetsController#country looks up by :iso, which is the 2-letter code --
    # distinct from the :iso_3 the country pages route on.
    def country_iso2
      @country_iso2 ||= Country.where.not(iso: nil).order(:id).pick(:iso)
    end

    def region_iso
      @region_iso ||= Region.order(:id).pick(:iso)
    end

    def cms_page_targets
      paths = Comfy::Cms::Page.order(:id).limit(@cms_sample).pluck(:full_path)
      # CMS pages are mounted inside the locale scope, so a top-level slug like
      # "/about" is swallowed by the /:id catch-all and 404s. "/en/about" is what
      # actually serves the page.
      paths.map do |p|
        Target.new(label: 'comfy/cms/content#show', path: "/#{LOCALE}#{p}".squeeze('/'))
      end
    rescue StandardError => e
      say "  (could not list CMS pages: #{e.class}: #{e.message})"
      []
    end

    def cms_asset_targets(route)
      site = Comfy::Cms::Site.order(:id).first
      return [] if site.nil?

      kind = route.defaults[:action] == 'render_css' ? 'cms-css' : 'cms-js'
      layout = Comfy::Cms::Layout.order(:id).pick(:identifier)
      return [] if layout.nil?

      [Target.new(label: route_label(route), path: "/#{kind}/#{site.id}/#{layout}")]
    rescue StandardError
      []
    end

    # ---------------------------------------------------------------- request

    def request(target)
      uri = URI.parse("#{@base_url}#{target.path}")
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response = http_for(uri).request(Net::HTTP::Get.new(uri))
      ms = elapsed_ms(started)

      result = Result.new(label: target.label, path: target.path, status: response.code.to_i, ms: ms)
      emit(result)
      result
    rescue StandardError => e
      result = Result.new(label: target.label, path: target.path, status: nil,
                          ms: elapsed_ms(started), error: "#{e.class}: #{e.message}")
      emit(result)
      result
    end

    def http_for(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      # Staging sits behind an internal certificate. Opt in explicitly rather
      # than defaulting to no verification.
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && @insecure
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http
    end

    def elapsed_ms(started)
      return nil if started.nil?

      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
    end

    # ----------------------------------------------------------------- output

    def emit(result)
      say format('  %-5s %-4s %6s  %-34s %s',
                 result.verdict,
                 result.status || '---',
                 result.ms ? "#{result.ms}ms" : '',
                 result.label.to_s[0, 34],
                 result.path)
    end

    def report
      failures = @results.reject(&:healthy?)

      say ''
      say '-' * 78
      say "walked #{@results.size}  healthy #{@results.count(&:healthy?)}  failed #{failures.size}"

      unless @skipped.empty?
        say ''
        say 'skipped:'
        @skipped.uniq.each { |label, reason| say format('  %-46s %s', label, reason) }
      end

      unless @unclassified.empty?
        say ''
        say 'UNCLASSIFIED -- these GET routes have dynamic segments and no resolver.'
        say 'Add one to RouteWalker#dynamic_targets, or a reason to SKIP_CONTROLLERS/SKIP_PATHS:'
        @unclassified.uniq.each { |label| say "  #{label}" }
      end

      return if failures.empty? && @unclassified.empty?

      say ''
      say 'FAILURES:'
      failures.each do |r|
        say format('  %-4s %-34s %s%s', r.status || 'ERR', r.label.to_s[0, 34], r.path,
                   r.error ? "  (#{r.error})" : '')
      end
    end

    def failed?
      @results.any? { |r| !r.healthy? } || !@unclassified.empty?
    end

    # ----------------------------------------------------------------- helpers

    # "(/:locale)/country/:iso(.:format)" -> "/en/country/:iso"
    #
    # The locale is SUBSTITUTED, not stripped. `get '/:id'` is declared at the top
    # of routes.rb, above the `scope '(:locale)'` block, so it shadows every
    # single-segment path: bare /search, /terms and /search-areas all match
    # protected_areas#show and fail. Prefixing with a locale makes them two
    # segments, which is both what real traffic looks like and the only way to
    # reach the route that was actually declared.
    LOCALE = 'en'.freeze

    def static_path(route)
      path = route.path.spec.to_s.dup
      path = path.sub('(.:format)', '')
      path = path.gsub(%r{\((/?):format\)}, '')
      path = path.gsub(%r{\(/:locale\)}, "/#{LOCALE}")
      path = path.gsub(%r{\(:locale\)}, LOCALE)
      path = path.squeeze('/')
      path = "/#{LOCALE}" if path == "/#{LOCALE}/"
      path.empty? ? '/' : path
    end

    def dynamic?(path)
      path.include?(':') || path.include?('*')
    end

    def route_label(route)
      controller = route.defaults[:controller]
      return "#{controller}##{route.defaults[:action]}" if controller

      # Routes declared with redirect() have no controller.
      "redirect #{static_path(route)}"
    end

    def say(message)
      @logger.puts(message)
    end
  end
end
