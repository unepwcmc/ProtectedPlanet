# Caching

**The rule: cache the figures, not the pages.**

Nothing stores rendered HTML. Every page is built fresh on every request, from data
that is already warm in Memcached. That is why a CMS edit is live the moment it is
saved, with no invalidation step, no cache-clearing button and no deploy needed.

## Why it works this way

Until Oct 2026 the opposite was true: `ApplicationController#enable_caching` served
eleven controllers' pages with `s-maxage`, and Rack::Cache stored the whole rendered
response in Memcached keyed by URL. It bought real speed, and cost four separate
problems:

- **CMS edits were invisible.** Nothing invalidated a stored page on save. Only
  `.kamal/hooks/post-deploy` and `PortalRelease::Cleanup` ever flushed, so an edit
  could sit unseen for the whole window — set to 30 days.
- **Visitors shared a CSRF token.** rack-cache strips `Set-Cookie` before storing, so
  a cache-served visitor got another visitor's `csrf_meta_tags` token and no session
  of their own.
- **Deploys could leave the site inert.** Stored HTML named digest-stamped asset
  paths, and every build deletes the files the previous digests point at. The
  post-deploy flush existed to stop `application-<old>.js` 404ing.
- **`Rack::ETag` never matched.** The per-session token made every body unique, so
  HTML revalidation could never return a 304.

Caching the derived data instead keeps the speed where the cost actually is — the
queries — and all four problems are properties of caching the page, so none survive.

## What is cached

`config.cache_store = :mem_cache_store` (dalli-backed) in staging and production,
pointed at `memcache_servers` from `config/app_secrets.yml`, with a 10MB value
ceiling. On the deployed hosts Memcached runs as a host service, not a container —
the app reaches it at `host.docker.internal:11211` (`MEMCACHE_SERVERS` in
`config/deploy.yml`). Locally it is the `memcached` container.

| What | Where | TTL |
| --- | --- | --- |
| Country stats, totals, national designation counts | `country_controller.rb` | 30 days |
| Region stats, totals | `region_controller.rb` | 30 days |
| Marine figures | `thematic/marine_controller.rb` | 12 days |
| Restricted-country messages | `country_restricted_message.rb` | 30 days |
| Blank-term search aggregations | `lib/modules/search.rb` | 1 hour |
| Mapbox tile PNGs | `assets_controller.rb` | 30 days |
| Global statistics CSV | `global_statistic.rb` | — (keyed by `updated_at`) |
| Sitemap chunk bounds | `lib/modules/sitemap.rb` | see that file |

Most keys carry `Download::Config.current_label`, so a WDPA release produces fresh
entries on its own rather than waiting out the TTL. The ones that do not are covered
by the post-deploy flush.

Clear it from the Rails console with `Rails.cache.clear`, or on a deployed host with
`kamal app exec -d staging --reuse "bin/rails runner 'Rails.cache.clear'"`. There is
no admin endpoint: `PUT /admin/clear_cache` was removed in Sep 2026 with
`AdminController`, and it called a bare `Rails.cache.clear` without the sitemap-bounds
preservation `PortalRelease::Cleanup` does.

## Why CMS pages are not cached either

Considered and rejected in Oct 2026, after the page cache came out. A short-lived cache
over the rendered CMS body (`/en/about`, `/en/news`, `/en/resources`) looks attractive
until you check what it would actually save:

- **The Elasticsearch query is already cached.** The listing pages call
  `SearchHelper#cms_pages_for_search`, which is `Search.search('', ...)` — a blank term,
  and `lib/modules/search.rb` caches exactly that case for an hour. Caching the rendered
  body puts a cache on top of a cache.
- **What is left is small.** `CmsHelper#load_categories` is two queries against
  `comfy_cms_layouts_categories` and `page_categories`, both tiny, plus the ERB compile
  of Comfy's `render inline:`.
- **These pages were never page-cached.** `Comfy::Cms::ContentController` never had
  `enable_caching`, so they have always rendered per request in production and have
  never shown up as slow. The measured table in `docs/known-issues.md` is country,
  region and search pages — not these.

Against that, a cache here costs a monkey-patch on the render path of every CMS page and
a key that has to track pages, layouts, snippets, files and categories — Comfy clears a
page's `content_cache` from Layout, Snippet and File callbacks using `update_all`, which
does **not** bump `updated_at`, so a snippet or upload edit is invisible to any
`cache_key_with_version` scheme. That is the staleness this whole document exists to
have removed.

If CMS pages ever do get slow, measure on staging first, then cache the specific helper
that is costing the time — not the page.

## The two responses that are still shared-cacheable

Both are safe for the same reason — what identifies them changes when their content
does, so neither can go stale the way HTML did.

- **Sitemaps.** `SitemapsController#cache_for_sitemap_ttl` sets its own TTL, sized to
  a release.
- **Mapbox tiles.** `/assets/tiles/:id` gets `Middleware::CacheHeaders.long_lived`,
  and its cache key carries the record's `updated_at`.

Static assets under `public/` are handled separately by `Middleware::CacheHeaders`,
which grants a long TTL only to paths carrying a build digest. See the table in
`lib/middleware/cache_headers.rb`.

## Adding a page

Do not reach for `expires_in ..., public: true` or copy an `after_action` from a
sibling controller. If a page is slow, find the query and put **that** behind
`Rails.cache.fetch` with a key that includes whatever makes the answer change —
usually `Download::Config.current_label` or a record's `updated_at`.

`test/integration/no_shared_html_cache_test.rb` asserts this and will fail if page
caching comes back.

## If the site is behind a CDN

Nothing the app sends asks a CDN to cache HTML any more. But a Cloudflare
**Cache Everything** rule overrides origin headers, and would reintroduce the
staleness this removed — from a layer the deploy hook does not purge. Production sits
behind Cloudflare (`config/deploy.production.yml`), so if pages ever appear stale
again, check `cf-cache-status` and `age` on `curl -sI` before looking at the app.
