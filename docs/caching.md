# Caching

**The rule: cache the figures, not the pages.**

Nothing stores rendered HTML. Every page is built fresh on every request, from
data already warm in Memcached. That is why a CMS edit is live the moment it is
saved — no invalidation step, no cache-clearing button, no deploy.

## Why

Until Oct 2026 `ApplicationController#enable_caching` served eleven controllers'
pages with `s-maxage` and Rack::Cache stored the whole response keyed by URL. It
was fast, and it cost four things:

- **CMS edits were invisible.** Nothing invalidated a stored page on save. Only
  `.kamal/hooks/post-deploy` and `PortalRelease::Cleanup` ever flushed, so an edit
  could sit unseen for the whole 30-day window.
- **Visitors shared a CSRF token.** rack-cache strips `Set-Cookie` before storing,
  so a cache-served visitor got another visitor's `csrf_meta_tags` token and no
  session of their own.
- **Deploys could leave the site inert.** Stored HTML named digest-stamped asset
  paths, and each build deletes the files the previous digests point at.
- **`Rack::ETag` never matched.** The per-session token made every body unique, so
  HTML revalidation could never return a 304.

All four are properties of caching the *page*, so caching the derived data
instead keeps the speed where the cost actually is — the queries — and none of
them survive.

## What is cached

`config.cache_store = :mem_cache_store` (dalli-backed) in staging and production,
pointed at `memcache_servers` from `config/app_secrets.yml`, with a 10MB value
ceiling. On the deployed hosts Memcached is a host service reached at
`host.docker.internal:11211` (`MEMCACHE_SERVERS` in `config/deploy.yml`); locally
it is the `memcached` container.

| What | Where | TTL |
| --- | --- | --- |
| Country stats, totals, national designation counts | `country_controller.rb` | 30 days |
| Region stats, totals | `region_controller.rb` | 30 days |
| Marine figures | `thematic/marine_controller.rb` | 12 days |
| Restricted-country messages | `services/country_restricted_message.rb` | 30 days |
| Blank-term search aggregations | `lib/modules/search.rb` | 1 hour |
| Mapbox tile PNGs | `assets_controller.rb` | 30 days |
| Global statistics CSV | `global_statistic.rb` | — (keyed by `updated_at`) |
| Sitemap chunk bounds | `lib/modules/sitemap.rb` | see that file |

Most keys carry `Download::Config.current_label`, so a WDPA release produces fresh
entries without waiting out the TTL. The rest are covered by the post-deploy flush.

Clear it with `Rails.cache.clear` in the console, or on a host with
`kamal app exec -d staging --reuse "bin/rails runner 'Rails.cache.clear'"`. There
is no admin endpoint — `PUT /admin/clear_cache` went with `AdminController` in Sep
2026, and it skipped the sitemap-bounds preservation `PortalRelease::Cleanup` does.

## Adding a page

Don't reach for `expires_in ..., public: true` or copy an `after_action` from a
sibling controller. If a page is slow, find the query and put **that** behind
`Rails.cache.fetch`, with a key including whatever makes the answer change —
usually `Download::Config.current_label` or a record's `updated_at`.

`test/integration/no_shared_html_cache_test.rb` will fail if page caching returns.

## CMS pages are not cached either

Considered and rejected Oct 2026. A short-lived cache over the rendered CMS body
(`/en/about`, `/en/news`, `/en/resources`) saves very little:

- **The Elasticsearch query is already cached.** The listing pages call
  `SearchHelper#cms_pages_for_search` → `Search.search('', ...)`, and
  `lib/modules/search.rb` caches exactly that blank-term case for an hour.
- **What's left is small** — `CmsHelper#load_categories` is two tiny queries, plus
  Comfy's `render inline:` ERB compile.
- **These pages were never page-cached.** `Comfy::Cms::ContentController` never had
  `enable_caching`, and they have never shown up as slow. The measured table in
  [known-issues.md](known-issues.md) is country, region and search pages.

Against that, it would cost a monkey-patch on every CMS page render plus a key
tracking pages, layouts, snippets, files and categories — and Comfy clears a
page's `content_cache` from those callbacks with `update_all`, which does **not**
bump `updated_at`, so a snippet or upload edit is invisible to any
`cache_key_with_version` scheme.

If CMS pages ever do get slow, measure on staging, then cache the specific helper
that costs the time — not the page.

## Still shared-cacheable

Two responses, both safe because their identity changes when their content does:

- **Sitemaps** — `SitemapsController#cache_for_sitemap_ttl` sets its own TTL,
  sized to a release.
- **Mapbox tiles** — `/assets/tiles/:id` gets `Middleware::CacheHeaders.long_lived`
  and keys on the record's `updated_at`.

Static assets under `public/` are handled by `Middleware::CacheHeaders`, which
grants a long TTL only to paths carrying a build digest. See the table in
`lib/middleware/cache_headers.rb`.

## Behind a CDN

Nothing the app sends asks a CDN to cache HTML. But a Cloudflare **Cache
Everything** rule overrides origin headers and would reintroduce the staleness
this removed, from a layer the deploy hook does not purge. Production sits behind
Cloudflare, so if pages look stale, check `cf-cache-status` and `age` on
`curl -sI` before looking at the app.
