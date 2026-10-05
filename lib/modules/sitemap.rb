# frozen_string_literal: true

require 'builder'

# XML sitemaps for the whole public site. robots.txt blocks the search endpoints,
# so this is a crawler's only route to the ~500k protected area pages.
#
# Rendered on demand from a controller rather than pre-generated into files. A chunk
# is a ~40ms index-only scan plus Builder, behind the controller's 12h Cache-Control,
# so a full crawl of every chunk costs seconds of CPU in total. The only cost that
# scales with the table is #chunk_bounds, cached and warmed after a release.
#
# Files would also need somewhere both roles can see. Today they do share
# /app/tmp/imports (deploy.yml mounts it for every role, all on one host), but that
# stops holding once web scales out, and it fails silently: stale or missing XML.
module Sitemap
  URLS_PER_CHUNK = 5_000

  CACHE_TTL = 12.hours

  # Ceiling on the chunk-bounds scan, the only query here whose cost scales with the
  # table: ~0.8s at 1M areas while index-only, a multi-GB heap read on a table an
  # import just swapped in and has not vacuumed (index-only scans need the
  # visibility map).
  BOUNDS_QUERY_TIMEOUT_MS = 20_000

  # Short, so a recovered database is picked up within minutes.
  BOUNDS_FALLBACK_TTL = 5.minutes

  # No release label in the key, so a release cannot invalidate it. Serving the
  # previous release's bounds just means the newest areas are missing for a few
  # minutes.
  LAST_GOOD_BOUNDS_KEY = 'chunk_bounds:last_good'
  LAST_GOOD_BOUNDS_TTL = 7.days

  # The locale segment is optional in the routes, so /about and /en/about both
  # render. /en is what the app's own link helpers generate; advertise only that.
  LOCALE_PREFIX = '/en'

  # How long a process trusts its own bounds/label copy. See #memoized.
  MEMO_TTL = 5.minutes

  PROTECTED_AREA_CHUNK_PREFIX = 'protected-areas'

  STATIC_CHUNK_NAMES = %w[pages countries regions].freeze

  XMLNS = 'http://www.sitemaps.org/schemas/sitemap/0.9'

  class << self
    # The names appearing in /sitemap.xml, in the order they are listed there.
    def chunk_names
      STATIC_CHUNK_NAMES +
        Array.new(protected_area_chunk_count) { |index| "#{PROTECTED_AREA_CHUNK_PREFIX}-#{index + 1}" }
    end

    # Range-checked against the chunk count rather than by building the chunk list,
    # which meant /sitemaps/<junk>.xml reached the database.
    def valid_chunk_name?(name)
      return true if STATIC_CHUNK_NAMES.include?(name)

      match = /\A#{PROTECTED_AREA_CHUNK_PREFIX}-(\d{1,6})\z/.match(name)
      return false unless match

      index = match[1].to_i - 1
      index >= 0 && index < protected_area_chunk_count
    end

    # Rails.cache.clear does not reach these. Tests need it; production waits out
    # MEMO_TTL.
    def reset_memos!
      @memos = nil
      @data_label_memo = nil
    end

    # Called from PortalRelease::Cleanup.post_swap!, where the release has both
    # invalidated every key here and left protected_areas unvacuumed.
    #
    # base_url is optional: the bounds key does not include it, so the expensive work
    # is warmed either way. Passing one also warms the per-host index and static
    # chunks.
    def warm!(base_url = nil)
      reset_memos!
      bounds = chunk_bounds

      if base_url
        index_xml(base_url)
        STATIC_CHUNK_NAMES.each { |name| chunk_xml(name, base_url) }
      end

      bounds.size
    end

    # Carries the fallback across a wholesale Rails.cache.clear. Without this the
    # release wipes it moments before the window it exists for, and a slow bounds
    # query 500s every sitemap URL instead of serving a slightly stale one.
    def preserving_last_good_bounds
      key = cache_key(LAST_GOOD_BOUNDS_KEY)
      last_good = Rails.cache.read(key)

      yield

      Rails.cache.write(key, last_good, expires_in: LAST_GOOD_BOUNDS_TTL) if last_good
    end

    # No lastmod: it would be the max over each chunk's contents, i.e. running every
    # query this document exists to avoid.
    def index_xml(base_url)
      cached("index:#{base_url}:#{data_label}") do
        build do |xml|
          xml.sitemapindex(xmlns: XMLNS) do
            chunk_names.each do |name|
              xml.sitemap { xml.loc("#{base_url}/sitemaps/#{name}.xml") }
            end
          end
        end
      end
    end

    def chunk_xml(name, base_url)
      # Rendered on demand: caching ~200 chunks would put ~57MB into a memcached
      # shared with hot caches, to save a cheap index-only scan. The controller's 12h
      # Cache-Control is the cache that matters here.
      return render_chunk(name, base_url) if protected_area_chunk?(name)

      cached("chunk:#{name}:#{base_url}:#{data_label}") { render_chunk(name, base_url) }
    end

    private

    def protected_area_chunk?(name)
      name.start_with?("#{PROTECTED_AREA_CHUNK_PREFIX}-")
    end

    def render_chunk(name, base_url)
      build do |xml|
        xml.urlset(xmlns: XMLNS) do
          entries_for(name).each do |path, updated_at|
            xml.url do
              xml.loc("#{base_url}#{path}")
              xml.lastmod(updated_at.strftime('%Y-%m-%d')) if updated_at
            end
          end
        end
      end
    end

    # [path, updated_at] pairs. Plucked, not instantiated: these tables carry
    # multi-MB geometry columns.
    def entries_for(name)
      case name
      when 'pages'     then page_entries
      when 'countries' then country_entries
      when 'regions'   then region_entries
      else                  protected_area_entries(chunk_index(name))
      end
    end

    # The data and thematic pages are Comfy pages too, so the CMS query covers them.
    def page_entries
      static = [
        [LOCALE_PREFIX, nil],
        ["#{LOCALE_PREFIX}/search-areas", nil]
      ]

      cms = Comfy::Cms::Page.published.pluck(:full_path, :updated_at).map do |full_path, updated_at|
        # The root CMS page is the home page, already listed above as /en.
        next if full_path == '/'

        ["#{LOCALE_PREFIX}#{full_path}", updated_at]
      end.compact

      static + cms
    end

    def country_entries
      Country.pluck(:iso_3, :updated_at).filter_map do |iso_3, updated_at|
        next if iso_3.blank?

        ["#{LOCALE_PREFIX}/country/#{iso_3}", updated_at]
      end
    end

    def region_entries
      Region.pluck(:iso, :updated_at).filter_map do |iso, updated_at|
        next if iso.blank?

        ["#{LOCALE_PREFIX}/region/#{iso}", updated_at]
      end
    end

    # /<site_id>, no locale prefix -- that route sits outside the `scope '(:locale)'`
    # block.
    #
    # site_id alone, no lastmod, to keep this an index-only scan: updated_at is
    # unindexed, so selecting it makes every row a ~6.6KB heap fetch. lastmod would
    # carry no signal anyway -- a release rewrites nearly every row onto one date.
    #
    # The btree over site_id is named index_protected_areas_on_wdpa_id in a migrated
    # database; StagingTableManager's index rename decoupled the names from columns.
    def protected_area_entries(index)
      first_site_id = chunk_bounds[index]
      return [] if first_site_id.nil?

      scope = protected_areas.where(site_id: first_site_id..)

      # Range-bounded, not OFFSET: OFFSET still produces the rows it skips, so the
      # last chunk would walk every preceding one.
      next_site_id = chunk_bounds[index + 1]
      scope = scope.where(site_id: ...next_site_id) if next_site_id

      scope.order(:site_id).limit(URLS_PER_CHUNK).pluck(:site_id).map { |site_id| ["/#{site_id}", nil] }
    end

    # One site_id per chunk. Doubles as the chunk count, so no separate COUNT.
    def chunk_bounds
      memoized(:chunk_bounds) { fetch_chunk_bounds }
    end

    # Hand-rolled rather than #cached: the two outcomes need different TTLs and only
    # one may be remembered as last-known-good.
    #
    # URLS_PER_CHUNK is in the key because the bounds are one per chunk -- changing
    # it otherwise leaves the index advertising one chunk count while the bounds
    # describe another.
    def fetch_chunk_bounds
      key = cache_key("chunk_bounds:#{URLS_PER_CHUNK}:#{data_label}")
      cached_bounds = Rails.cache.read(key)
      return cached_bounds if cached_bounds

      bounds = query_chunk_bounds_within_timeout
      Rails.cache.write(key, bounds, expires_in: CACHE_TTL)
      Rails.cache.write(cache_key(LAST_GOOD_BOUNDS_KEY), bounds, expires_in: LAST_GOOD_BOUNDS_TTL)
      bounds
    rescue ActiveRecord::QueryCanceled
      fallback = Rails.cache.read(cache_key(LAST_GOOD_BOUNDS_KEY))

      # Raising 500s this one request; returning [] would cache an empty index for
      # 12h and 404 every chunk URL a crawler already knows.
      raise if fallback.nil?

      Rails.logger.warn(
        "Sitemap: chunk bounds query exceeded #{BOUNDS_QUERY_TIMEOUT_MS}ms; serving " \
        "#{fallback.size} bounds from the last successful run. Check that " \
        'protected_areas has been vacuumed since the last import -- without its ' \
        'visibility map this query reads the whole heap.'
      )

      Rails.cache.write(key, fallback, expires_in: BOUNDS_FALLBACK_TTL)
      fallback
    end

    # SET LOCAL so the ceiling reverts on commit instead of leaking onto the pooled
    # connection.
    def query_chunk_bounds_within_timeout
      ProtectedArea.transaction do
        ProtectedArea.lease_connection.execute("SET LOCAL statement_timeout = #{BOUNDS_QUERY_TIMEOUT_MS}")
        query_chunk_bounds
      end
    end

    # Sliced in Postgres, not Ruby: same index-only scan, but ~200 rows back instead
    # of one per area, which at 1M cost ~0.6s and ~59MB the GC never returned.
    def query_chunk_bounds
      sql = <<~SQL.squish
        SELECT site_id FROM (
          SELECT site_id, row_number() OVER (ORDER BY site_id) AS rn
          FROM #{ProtectedArea.table_name}
          WHERE site_id IS NOT NULL
        ) numbered
        WHERE (rn - 1) % #{URLS_PER_CHUNK} = 0
        ORDER BY site_id
      SQL

      ProtectedArea.lease_connection.select_values(sql)
    end

    def protected_area_chunk_count
      chunk_bounds.size
    end

    # site_id is nullable, and a NULL one has no page -- /:id would 404.
    def protected_areas
      ProtectedArea.where.not(site_id: nil)
    end

    def chunk_index(name)
      name.delete_prefix("#{PROTECTED_AREA_CHUNK_PREFIX}-").to_i - 1
    end

    # Busts every chunk when a release lands. Memoized because it is a ~46ms Release
    # lookup running twice per request on otherwise pure cache hits; its own memo
    # rather than #memoized, which calls this to build its key.
    def data_label
      entry = @data_label_memo
      return entry[:value] if entry && entry[:expires_at] > monotonic_now

      value = begin
        Download::Config.current_label
      rescue StandardError
        'unknown'
      end

      @data_label_memo = { value: value, expires_at: monotonic_now + MEMO_TTL.to_i }
      value
    end

    # mem_cache_store answers an unreachable memcached by running the block and not
    # storing it, so without this an outage makes every request recompute.
    #
    # No lock: hash assignment is atomic under the GVL. Several threads may compute
    # at once on a cold process, which beats a mutex held across a database call
    # blocking every Puma thread.
    def memoized(key)
      label = data_label
      entry = @memos&.dig(key)
      return entry[:value] if entry && entry[:label] == label && entry[:expires_at] > monotonic_now

      value = yield
      @memos = (@memos || {}).merge(
        key => { value: value, label: label, expires_at: monotonic_now + MEMO_TTL.to_i }
      )
      value
    end

    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def cached(key, &block)
      Rails.cache.fetch(cache_key(key), expires_in: CACHE_TTL, &block)
    end

    def cache_key(key)
      "sitemap:#{key}"
    end

    def build
      xml = Builder::XmlMarkup.new(indent: 0)
      xml.instruct!(:xml, version: '1.0', encoding: 'UTF-8')
      yield xml
      xml.target!
    end
  end
end
