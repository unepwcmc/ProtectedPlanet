# Backend upgrade — carryover / deferred items

Running log of things intentionally **not** done yet, with **when** to pick each up.
Keep this current as phases land. Last updated: 2026-08-10 (Rails 8.0 phase).

Status at this point: **Rails 8.0.5**, Ruby 3.3.7, Zeitwerk, `load_defaults 8.0`,
postgis-adapter 11.0. Suite **653 runs, 0 failures, 7 skips**. SimpleCov gate in CI.
**Rails ladder COMPLETE: 5.2 → 6.0 → 6.1 → 7.0 → 7.1 → 7.2 → 8.0.**

### Rails 8.0 phase — DONE
- rails ~> 8.0.0 (8.0.5.1), `load_defaults 8.0`, activerecord-postgis-adapter 10 → 11.0.0,
  **rails-i18n 7 → 8.1** (7.x caps railties < 8).
- comfortable_media_surfer 3.1 resolved against Rails 8 with no cap conflict.
- **Clean: 0 failures, 0 deprecations, no code changes** beyond the version + defaults —
  the Zeitwerk/load_defaults ladder + secrets migration did the de-risking.

### Rails 7.2 phase — DONE
- rails ~> 7.2.2 (7.2.3.2), `load_defaults 7.2`, activerecord-postgis-adapter 9 → 10.0.3.
- **`Rails.application.secrets` → `config_for(:app_secrets)`** (the 7.2 blocker) done first as
  its own commit: renamed `config/secrets.yml` → `config/app_secrets.yml`, added
  `config/initializers/00_app_secrets.rb` (`AppSecrets = config_for(:app_secrets)`), set
  `config.secret_key_base` explicitly. Boot-time spots (env files, `storage.yml`,
  `export_to_s3.rake` load-time constant) use `config_for` directly; app/lib/test use the
  `AppSecrets` constant (mutable, so tests that set config still work). Zero deprecations.
- Version bump itself was clean: **0 failures, 0 new deprecations** after the secrets prep.

### Rails 7.1 phase (B0) — DONE
- rails ~> 7.1.5 (7.1.6), `load_defaults 7.1`, activerecord-postgis-adapter 8 → 9.0.2.
- **Fixed:** `add_autoload_paths_to_load_path` defaults to **false** under `load_defaults 7.1`,
  so `lib/modules` subdirs left `$LOAD_PATH` and two bare requires broke (`LoadError`):
  `ogr/split.rb` (`require 'shapefile'`) and `wdpa/source_importer.rb`
  (`require 'wdpa/data_standard/source'`). Converted both to `require_relative`.
- **Fixed test:** `protected_area_show_test` slug case — Rails 7.1 drops the default
  "You are being redirected" HTML body, so the old `assert_match(/Killbear/, body)` (which
  matched the name inside that redirect body) broke. App is correct (slug → 302 to search);
  test now asserts the redirect + `search_term=` location.

### ✅ Rails 7.2 headline blocker — `Rails.application.secrets` — DONE
Was the main 7.2 task (deprecated in 7.1, removed in 7.2; ~48 uses / 23 files + test/).
Migrated to `config_for(:app_secrets)` — see the "Rails 7.2 phase — DONE" note above.

---

## 1. Rails 6.1 exit criteria still open (infra-gated — need Luca / DevOps)
Cannot be closed locally; they need a deploy target and a decision. Track against the
[03 exit criteria](./03-rails-6.md).

- [ ] **Import pipeline + download workers smoke-tested** on a real environment (real WDPA import subset + generate each download type).
- [ ] **Staging deploy on Rails 6.1 confirmed.** Blocked: staging is Ubuntu 18.04 / Ruby 2.6.3 (no 2.7) — see [11](./11-deploy-and-devops.md) and the server audit.
- [ ] **4 EM decisions** (from [00 "Facts still needed"](./00-scope-and-shared-milestones.md)): infra scope + budget; container registry (GHCR vs Docker Hub); WDPA release cadence (switchover window); data-team acceptance criteria for `.gdb` downloads.

## 2. Ruby 2.7 → 3.3 — DONE (Jul 2026, Ruby 3.3.7)
Suite green on 3.3.7 (648 runs, 0 failures), zeitwerk clean, image builds clean.
Toolchain: ruby-build compiles 3.3.7 on the buster base (no ruby:3.3 image would
keep the GDAL/FileGDB source build); `BUNDLE_FORCE_RUBY_PLATFORM=true` so native
gems compile from source (precompiled x86_64-linux gems target newer glibc than
buster 2.28). Done: `::Data`→`DataPages` rename; ~11 gem bumps; factory_girl→
factory_bot; `File.exists?`→`File.exist?`; frozen-I18n-hash fix in HomeController.

**Stopgaps from the Ruby-3 / Rails-6.1 window:**
- [ ] **`psych ~> 3.3` pin** (Gemfile) — Psych 4/5 (Ruby 3.1+) is safe-load
      (aliases off). Rails 7 loads its OWN configs alias-aware, but **webpacker 4
      and appsignal 3 call plain `YAML.load` on their aliased configs at boot** and
      break — so the pin **cannot be removed at Rails 7.0** (tried; boots red).
      Remove when webpacker is dropped at the Vite cutover (B5) and appsignal is
      bumped to a Psych-5-safe version.
- [x] ~~Comfy routing kwarg patch~~ — **removed at Rails 7.0** (Media Surfer's
      `comfy_route` is Ruby-3-native).
- [ ] **`activerecord-postgis-adapter` `PG::Coder.new(hash)` deprecation** — still
      noisy on adapter 8.x / Rails 7.0; recheck at the 9.x/11.x bumps.

## 3. Test coverage — deferred deliberately to the phase that touches the code
Writing these now, then not touching the code for months, risks staleness. Do each
**just before** its phase. (Coverage baseline captured via `COVERAGE=1 bin/rails test`.)

- [x] **DONE — WDPA geometry importer** (`lib/modules/wdpa/portal/importers/protected_area/geometry.rb`,
      was **0%**). Added `test/unit/wdpa/portal/importers/geometry_test.rb` (19 tests): mapping
      logic, `get_matching_condition` site_pid branches, `get_geometry_column`, `validate_target_table`
      (missing/empty-PA-hard-fail/empty-parcel-warn/populated), `import_geometry_from_view` (UPDATE SQL
      shape + cmd_tuples + coordinate follow-up), `import_coordinates` (ST_Centroid/ST_MakeValid guard),
      `import_geometry_for_table` (aggregation, checkpoint-skip, per-view error isolation), and
      `import_to_staging`. Mocks the connection layer (portal staging tables/views aren't in the test
      DB — matches the sibling importer tests) rather than real PostGIS fixtures. This is the
      characterization net **before GDAL + the Postgres migration** — highest spatial-upgrade risk. Suite 672/0.
- [x] **DONE — Table services** — `portal/services/core/{table_cleanup,table_swap,table_rollback}_service.rb`
      (was ~19–36%). Extended the existing tests (+10) covering the PG-migration-fragile logic:
      cleanup `group_backups_by_timestamp`, `sort_tables_by_dependency` /
      `sort_materialized_views_by_dependency` (junction→main→independent / config deletion order),
      `cleanup_old_backups` (retention: within-limit no-op + oldest-removed sum); swap
      `validate_staging_tables_existence` (pass + missing-lists-raise); rollback
      `validate_backup_tables_exist` (missing-raise) + `list_available_backups_impl` (unique,
      newest-first). Mocks the connection (raw-SQL DDL not run against the test DB). Suite 681/0.
- [x] **DONE — Relation `create_models` path** — `portal/relation/*` (was 0%). Added 15 tests:
      `protected_area_test.rb` (create_models dispatch + for_create:false field removal, countries
      resolve/skip, first_or_create converters, `designation` **with + without jurisdiction** — the
      nil-jurisdiction case behind the `belongs_to` opt-out §6 — sources/no_take_status mocked as
      staging_* aren't in the test schema), `protected_area_parcel_test.rb` (compact — near-copy),
      `pame_evaluation_test.rb` (site_id/site_pid resolution, parcel-over-PA preference, method/source
      linking; staging + PameMethod mocked). Suite 696/0.
- [x] **DONE — shared importers** (+12 tests, CSV stubbed / records real). `country_overseas_territories`
      (parent-child wiring, parent/child-not-found, skip-existing), `story_map_link_list` (link create,
      site-not-found, invalid site_id), `protected_areas_related_source` (invalid env, missing file,
      empty CSV soft-warn, live/staging update_table dispatch). Suite 708/0. **Coverage 65.43%**
      (SimpleCov floor raised 54 → 62 this session).
- [x] **DONE (code) — GDAL `.gdb` driver swap: `FileGDB` (Esri SDK) → `OpenFileGDB`.** Changed
      `lib/modules/ogr/postgres.rb` `DRIVERS[:gdb]` → `'OpenFileGDB'` and made
      `postgres_gdb_export.erb` read `-f "<%= DRIVERS[:gdb] %>"` (single source of truth, was a
      hardcoded `-f "FileGDB"`). **Added `-lco "GEOMETRY_NAME=SHAPE"`** — this was NOT optional:
      without it OpenFileGDB names the geometry column after the source (`the_geom`), whereas the Esri
      SDK named it `SHAPE`; the LCO restores exact parity. Added `test/unit/ogr/postgres_gdb_export_test.rb`
      (3 tests, `system` mocked — the gdb path had NO test before) asserting driver + SHAPE lco + `-update`.
      **Before/after verified byte-schema-identical** by generating both on the same data: OLD via
      FileGDB on PP's image (GDAL 2.2.3, Esri SDK) vs NEW via OpenFileGDB on Debian bookworm (GDAL 3.6.2,
      apt, no SDK). All three layer types match — **poly** (Multi Polygon, 20 feat), **point** (Multi
      Point, 5 feat), **source** (non-spatial) — same geometry type, feature count, `FID=OBJECTID`,
      `Geometry Column=SHAPE`, fields, and CRS (WGS84/EPSG:4326; the only textual diff is GDAL 3.6 WKT2
      `GEOGCRS` vs 2.2.3 WKT1 `GEOGCS` — same CRS, cosmetic). Multi-layer `-update` append confirmed.
      **Other download formats unaffected** — the swap only touches `DRIVERS[:gdb]` + the gdb template;
      CSV (`'CSV'`) and Shapefile (`'ESRI Shapefile'`) use unchanged drivers + `postgres_export.erb`,
      PDF is a separate generator. Suite 711/0.
      Reference: `wdpa-data-management-portal` already ships the same WDPA `.gdb` via OpenFileGDB on bookworm.
      **STILL TO DO (gated):** (1) can't run on PP's *current* dev image (GDAL 2.2.3 = OpenFileGDB
      read-only) — needs the **GDAL 3.8 app image** (Dockerfile modernization, infra track) for in-app
      end-to-end; (2) **data-team ArcGIS sign-off** on a real `.gdb` (largely pre-answered — portal output
      already consumed); (3) diffs above used samples (20 poly / 5 point) not a full release volume.
- [ ] **ES-backed serializers** — `Search::{Areas,Full,Cms}Serializer` need a real `Search` object (ES). Only `FiltersSerializer` (structural) + `CountrySerializer`/`MapOverlaysSerializer` are covered so far.
- [ ] **Un-skip the 7 FDW integration tests — SANDBOX-GATED (scoped Aug 2026).** They skip on
      `to_regclass('portal_fdw.wdpa_iso3')` being nil (`release_orchestration_integration_test.rb`,
      `release_workflow_integration_test.rb`). Requirements: a **`portal_fdw` schema (~48 source
      tables** — categories/lookups + `wdpas`, `spatial_data` w/ PostGIS geometry, `source`, `pame`,
      `greenlists`, `wdpa_iso3` + junctions) + sample rows, on top of which `FDW_VIEWS.sql` (659
      lines, in repo) builds ~9 staging materialized views; the tests then run import→swap→cleanup.
      **`portal_fdw` is NOT in the repo** (`structure.sql` has 0 refs) — in prod it's a live
      postgres_fdw foreign schema on the portal DB, so the exact 48-table schema exists only there.
      **Do NOT hand-fabricate** (48 tables, high drift risk). **Path: `pg_dump --schema-only -n
      portal_fdw` from the temp staging sandbox** (the devops ask — it has the portal FDW), convert
      `FOREIGN TABLE`→local `TABLE`, load into the test DB, seed a handful of rows. Gate on the
      sandbox existing. The fragile *logic* is already covered by the geometry-importer +
      table-service unit tests, so this is end-to-end confidence, not a correctness gap.
- [ ] **No system/browser tests at all** (rack-test only). Full request→render→JS path is never exercised. Frontend plan phase 9 adds Playwright; coordinate.
- [ ] **Raise the SimpleCov floor** (`test/test_helper.rb`, currently 54) as coverage improves. Never lower it.

## 4. Deferred gem / asset bumps (own phases — reasoned deferrals)
- [ ] **sass-rails 5.0.8 → 6 + Sprockets 4** — needs a `manifest.js` this app lacks; Ruby-Sass → LibSass migration across 129 SCSS files with **no visual tests**. Pair with the Vite/asset work, not the Rails bump. sass-rails 5.0.8 works fine on Rails 6.1.
- [ ] **capybara 2.3 → 3 + selenium 4** — currently rack-test only, no drivers in use; Capybara 3 text-matching changes need per-assertion review. Do in the test phase, no rush.
- [ ] **`rails app:update` never run** — its main artifact (`new_framework_defaults_6_x.rb`) is redundant since we adopted `load_defaults` directly. If run later, don't let it clobber hand-tuned `config/`.

## 4b. Media Surfer admin assets (Rails 7.0 CMS swap)
Media Surfer 3.1 ships **no prebuilt admin assets** — `app/assets/builds/` is empty.
Its admin JS is esbuild/ES-modules and its CSS is dart-sass (`@import "codemirror/lib/codemirror"` from npm). Sprockets cannot compile the source, so the build must run first.
- **Fix (Option 1):** `rails comfy:compile_assets` (esbuild + dart-sass → the gem's
  `app/assets/builds/comfy/admin/cms/application.{js,css}`); Sprockets/Propshaft
  then serve the built files. Wired into the `install` service (docker-compose) and
  CI `prepare()` (Jenkinsfile).
- [ ] **Production/deploy must run `comfy:compile_assets` before `assets:precompile`**
  (Capistrano now; Docker/Kamal later). The build lands in the gem dir, which is
  not version-controlled, so every fresh environment must run it.
- [ ] **Optional refinement:** build into our own `app/assets/builds/` from the gem
  source instead of the gem dir, to fully decouple from the read-only bundle. Not
  required — the current approach works in dev/CI.
- Rails 8 / Propshaft serves the same `builds/` files — no rework expected.
- [x] **B3 admin smoke (Rails 7.0) — mostly PASS (Jul 2026):** login (HTTP Basic
  401→200), `/admin/sites`, pages index, and page **edit** all 200; custom CMS
  tags render (form_fragments + fragment fields); compiled admin CSS+JS serve 200
  with the full editor stack bundled (CodeMirror, Redactor, Flatpickr, plupload,
  Sortable). Option 1 asset build validated end-to-end.
- [x] **B3 gap — /admin files & uploads (ActiveStorage schema) — FIXED (Jul 2026).**
  The app only ran the Rails-5.2-era `create_active_storage_tables` migration; the
  6.0 `service_name` column and 6.1 `active_storage_variant_records` table were
  missing, so Media Surfer's files UI 500'd. Added the three update migrations to
  the `db` submodule (service_name, variant_records, nullable checksum), migrated
  dev + test, added `test/unit/active_storage_schema_test.rb`. Files UI now 200.
  **db submodule workflow (set up Jul 2026):** all upgrade-related db commits go
  on the long-lived branch **`backend/rails-upgrade`** in `unepwcmc/protectedplanet-db`
  (NOT develop — the db changes must land in develop together with the app's Rails
  upgrade, not before). The app upgrade branches point their submodule at commits
  on `backend/rails-upgrade`; `.gitmodules` tracks it (`submodule update --remote`).
  - App `backend/rails-7.0` points at db `1df2706` (AS migrations). Pushed.
  - [ ] **When the Rails upgrade merges to develop/staging:** merge db
        `backend/rails-upgrade` → db `develop` at the same time, then repoint.
  - `db/structure.sql` is gitignored in the submodule (schema comes from
    `db:migrate`, per Jenkinsfile) — nothing to commit there.

## 4c. Rails 7.0 broader smoke (Jul 2026) — PASS, 2 bugs fixed
Drove a running server on Rails 7.0: home, `/search`, `/search-areas`,
`/search-results`, country pages, PA show, and `/admin` all render 200; ES search,
`ogr2ogr` (2.2.3), and the WDPA importer load fine; 651 tests green. Rails 7 code
is sound. Two real (pre-existing, not upgrade) bugs found + fixed:
- `StatisticPresenter#geometry_ratio` 500'd on a nil statistic (country/search/PA
  pages for any geo entity without a stat) — now returns zeros (+ regression test).
- `ApplicationController#record_invalid_error` (rescue for ALL `StatementInvalid`)
  assumed `params[:page]` present and crashed on any other error, masking it — now
  guards nil and logs the underlying exception.

**DB-setup findings (environment, not code):**
- [ ] **`pg_cron` in `db/structure.sql` breaks structure-based test setup.**
  `db:test:prepare` / `db:schema:load` into `pp_test` fail: "can only create
  extension pg_cron in database pp_development". CI is unaffected (it uses
  `db:create db:migrate`, per Jenkinsfile). For local test DB use
  `db:drop db:create db:migrate`, not `db:test:prepare`. Consider excluding
  pg_cron from the schema dump, or scheduling pg_cron per-DB.
- **Good news:** a fresh `db:migrate` creates PostGIS via the existing
  `create_extension_postgis` migration — so **adapter 8.x needs no manual
  `CREATE EXTENSION postgis`** for a migrate-based setup (the plan feared it would).
  Still confirm for a structure.sql/schema-load-based deploy.
- The local dev/test DBs (from the `db` submodule seed) start half-migrated;
  rebuild the test DB with `db:drop db:create db:migrate` for full-app local testing.

## 4d. Download pipeline — local end-to-end verified via MinIO (Jul 2026)
Added **MinIO** (S3-compatible) to docker-compose and an ENV-guarded S3 endpoint in
`lib/modules/s3.rb` (`AWS_S3_ENDPOINT`; also skips the public-read ACL against a
custom endpoint since MinIO doesn't implement per-object ACLs — real AWS unchanged).
**Result:** `Download.generate(:csv, general)` runs fully on Rails 7.0 / Ruby 3.3 —
downloads view query → `ogr2ogr` export → source CSV → zip → **aws-sdk 3.0.1 upload
to S3** (an 11.4 MB zip landed in MinIO). Confirms GDAL download-gen, the download
generators, and **aws-sdk 3.0.1 works on Ruby 3.3** (the pinned-2017 gem was a risk).

How to run locally:
1. `docker compose up -d minio db redis`
2. Create buckets once (via `Aws::S3::Client#create_bucket` with the MinIO creds):
   `pp-downloads-development`, `pp-import-development`.
3. `docker compose run --rm -e AWS_S3_ENDPOINT=http://minio:9000 -e AWS_ACCESS_KEY_ID=minioadmin -e AWS_SECRET_ACCESS_KEY=minioadmin -e AWS_S3_REGION=us-east-1 web bash -lc "bundle exec rails runner '...Download.generate...'"`
   NOTE: dotenv **overloads** `.env`, so `-e` AWS creds don't reach `Rails.application.secrets`. Either set them in `.env`/`.env.<env>`, or override `Rails.application.secrets.aws_*` at the top of the runner.
- [ ] **Tier 2 (import half)** still not run locally — needs a small WDPA-format `.gdb`
      in the MinIO `import/` bucket to exercise `Wdpa::Importer.import` (FileGDB read).
- [ ] **Tier 3 (full real end-to-end)** — real WDPA release + real S3 on staging (deploy-gated).

## 4e. Cache / search / redis clients (surfaced in the devops research, Jul 2026)
Infra reality: **Rails cache = Memcached** (dalli, local on web box) · **Redis** = Sidekiq +
visit analytics (`$redis.zincrby`, local, db /2) · **Elasticsearch 7.17.24** self-hosted on
the **DB host** `192.168.176.65:9200`.
- [x] **FIXED — `:dalli_store` → `:mem_cache_store`.** prod.rb + staging.rb had
      `config.cache_store = :dalli_store`; **dalli 3.x removed that symbol** (needed for
      Ruby 3 / Rails 7). Switched to `config.cache_store = :mem_cache_store,
      Rails.application.secrets.memcache_servers, { value_max_bytes: 10_485_760 }` (Rails
      built-in, dalli-backed) and bumped `dalli` 2.7 → ~> 3.2 (locked 3.2.8). The direct
      `Dalli::Client.new(servers, {value_max_bytes:})` rack_cache line is API-compatible
      with 3.x — left as-is. **Not caught by tests** (dalli is a `production,staging`-group
      gem; dev = `:memory_store`, test = `:null_store`) so verified out-of-band: added a
      `memcached` service to docker-compose and confirmed on dalli 3.2.8 that `:dalli_store`
      now raises, `:mem_cache_store` + servers + `value_max_bytes` round-trips (incl. a 2MB
      value), and `Dalli::Client.new` works. **Still validate on staging.**
      ⚠️ `load_defaults 7.0` bumps cache_format_version, so **flush Memcached on that deploy**.
- [x] **FIXED — `elasticsearch` gem 7.2.1 → ~7.17 (locked 7.17.11) + faraday 1.0 → ~1.10
      (locked 1.10.6).** Stayed on the ES 7.x client (matches server 7.17.24) — 8.x is a
      client rewrite (elastic-transport, namespace changes) and the code uses
      `Elasticsearch::Transport::Transport::Errors::NotFound`, which 7.17 keeps. **No code
      changes needed**: `Elasticsearch::Client.new(url:)`, `.indices.create/delete`, `.index`,
      `.bulk`, `.search`, and the `NotFound` rescue all unchanged across 7.x. Verified out-of-
      band with a live round-trip (ping/create/index/search=1 hit/delete + NotFound rescue).
      faraday pinned to the 1.x line (2.x split adapters into separate gems). Suite 653/0.
      (ES server 7→8 is a separate, deferred project.)
      ⚠️ **Dev/prod ES parity gap:** `docker-compose.yml` runs `elasticsearch:8.6.0` while
      prod is 7.17.24. The 7.17 client talks to the 8.6 dev box fine (8.x returns the product
      header), so local dev is unblocked, but dev ≠ prod. Not downgraded here because the
      `protectedplanet_es_data` volume holds 8.6-format indices 7.17 can't read (would force a
      wipe + reindex). Align dev to 7.17.x (with a volume reset) as its own task when convenient.
- [x] **DONE — redis-rb 4.8 → 5.4 + Sidekiq 6.5 → 7.3.9.** redis was transitive via
      Sidekiq 6.5; Sidekiq 7 drops redis-rb (uses redis-client) so added `gem 'redis', '~> 5.0'`
      explicitly (app uses `$redis`/`Redis.new` directly). redis-rb 5 code fixes:
      `active_token.rb` `$redis.exists` → `.exists?` (v5 #exists returns Integer; `unless 0`
      is truthy — was a latent bug), and `redis_handler.rb` `multi do … end` → `multi do
      |pipeline| pipeline.… end` (v5 requires the yielded pipeline). Two test mocks updated to
      match (`:exists` → `:exists?`, `multi` yields a pipeline mock). Suite 653/0.
      NOTE: the **2-Redis cache swap** (drop Memcached, `redis_cache_store` + `cache.rake` fix,
      see the devops-decision item above) was NOT bundled in — do it as its own change when
      provisioning is ready, to keep this commit to the gem/API bump.
- [ ] **DECISION (devops, Jul 2026) — drop Memcached; move Rails cache to Redis. Two Redis
      instances, NOT one.** Devops wants everything standardized on Redis (Kamal accessories),
      Memcached gone. Doable, but PP's Redis is **not** a throwaway store — `$redis` (same
      `REDIS_URL` as Sidekiq) holds **non-rebuildable** data that must never be evicted:
        - **visit/popularity analytics** — per-`MM-YYYY` sorted sets, write `zincrby`
          [protected_areas_controller.rb:88], read `zrevrangebyscore` [protected_area.rb:91].
          Not in Postgres.
        - **active auth tokens** [lib/modules/active_token.rb] (+ properties).
        - (also transient: download job state/locks [lib/modules/download/*], import
          locks/counters [lib/modules/import_tools/redis_handler.rb], Sidekiq queues.)
      A cache needs `maxmemory-policy allkeys-lru` (evict under pressure); the above must be
      `noeviction`. **maxmemory-policy is server-wide**, so cache + durable data CANNOT safely
      share one instance. → Provision **two** Redis accessories:
        - **redis-cache** — `:redis_cache_store`, `allkeys-lru`, no persistence, no volume.
        - **redis-data** — Sidekiq + analytics + tokens + downloads, `noeviction`, AOF +
          persistent volume + backups (this is today's Redis, unchanged).
      **Dev work when we do it (bundle with redis-rb 5 / Sidekiq 7):**
        1. prod.rb + staging.rb: `config.cache_store = :redis_cache_store, { url: <cache url>,
           namespace: "cache", expires_in: … }` (replaces the `:mem_cache_store` line).
        2. Remove `dalli` gem + the `Dalli::Client.new` rack_cache lines + Memcached (compose +
           the memcached service added for the dalli fix). Decide rack_cache's fate (drop or
           point at redis-cache).
        3. **Fix [lib/tasks/cache.rake:19]** — currently `$redis.keys.each { |k| $redis.del(k) }`
           flushes the WHOLE data Redis (would wipe analytics/tokens). Change to
           `Rails.cache.clear` (namespaced redis_cache_store → only cache keys). Latent bug today.
        4. Two `REDIS_URL`s now (cache vs data) — update secrets/env + the `$redis` initializer
           stays pointed at redis-data.
      Not caught by tests (cache is prod/staging-group only) → validate on staging.
      ⚠️ Still flush the cache Redis on the `load_defaults` cache-format cutover.

## 4f. CMS (Media Surfer) port verification (Jul 2026)
Audited the ~280-line `comfy_patching.rb` + custom tags against Media Surfer 3.1.7.
All 7 overridden methods exist with matching signatures and our bodies are rebased
onto Media Surfer's current versions (incl. their `target_page` + `import_translations`).
Verified working: admin loads, page-edit renders custom tags, files/upload (B3);
public CMS pages render; **page save + `assign_layout_categories` run clean (#3)**.
- [x] Fixed: `import_page` page lookup now `where(slug:, parent_id:)` (matched Media Surfer).
- [x] **FIXED — CMS seed import on Ruby 3 (Psych safe_load).** Media Surfer's importers
      call bare `YAML.safe_load` in 5 places (page attrs, page-translations, layout, file,
      snippet), which rejected datetime/symbol attrs (`Psych::DisallowedClass`) and broke
      `sync_seeds`. Fixed with a `CmsSeedYaml` shim in `comfy_patching.rb`: a thread-local
      flag set for the duration of any importer's `import!`, and a guarded `YAML.safe_load`/
      `safe_load_file` prepend that permits `[Symbol, Date, Time, TimeWithZone, TimeZone,
      BigDecimal]` **only while importing** (normal app YAML unchanged). Covers all 5 sites
      + future ones without re-copying gem method bodies. Also fixed two nil crashes on
      **empty file/category fragments** (guards in our `construct_fragments_attributes` /
      category code). Verified: 140-page real round-trip green + new regression test
      `test/integration/cms_seed_roundtrip_test.rb` (datetime + empty file/category frags).
- [ ] **Seed export aborts on a missing blob** — `fragments_data` calls `attachment.download`,
      which raises `ActiveStorage::FileNotFoundError` if the blob file is absent (dev only;
      prod S3 has them). Low priority — consider rescuing per-attachment so one missing file
      doesn't kill the whole export.

## 5. Deploy / CI notes
- CI now runs **`bin/rails test`** (not `rake test`) so SimpleCov starts before app load (`Jenkinsfile` `rakeTest()`). Both run the same set (no `test/acceptance`). Don't revert to `rake test` without moving SimpleCov's start.
- Coverage is gated: `COVERAGE=1` fails the build below the floor.

### 5a. `staging_kamal` convergence — Kamal v2 on Proxmox staging (scoped Aug 2026)
DevOps stood up Proxmox/Kamal-v2 staging; **`pp-web-staging-01.internal.unep-wcmc.org` (172.20.0.160)
is ProtectedPlanet**, `api-pp-web-staging-01` is protectedplanet-api, DB is
`pp-db-staging-01.internal.unep-wcmc.org` (172.20.0.159). The other four FQDNs are the
already-dockerised fleet (digital-report, api-pp-authentication, wdpa-api, pp-data-management-portal).

PP's Kamal config lives on the **`staging_kamal` branch** (not master, not upgrade-plan):
`config/deploy.yml` + `deploy.staging.yml`, `Dockerfile.deploy`, `.kamal/secrets-common`,
`.github/workflows/deploy-staging-kamal.yml`, web + **two Sidekiq roles**, **ES 7.17 accessory**,
host-bound Redis/Memcached via `host.docker.internal`.
**Its `Dockerfile.deploy` already does the GDAL modernisation** — Ubuntu 24.04, distro **GDAL 3.8.4,
OpenFileGDB, no ESRI SDK**, Ruby 3.3.7 via ruby-build, Node 24 + yarn 4.
It branched from our **Rails 7.1 (B0)** commit, so it lacks the 7.2→8.0 / redis-5 / Sidekiq-7 /
secrets→config_for / test-net / GDAL work.

⚠️ **The two halves are incompatible apart:** staging_kamal ships GDAL 3.8 *without* the ESRI SDK while
its app code still asks for the `FileGDB` driver → **`.gdb` downloads would fail on staging**. Our
OpenFileGDB swap is the missing app-side half.

**Merge scope (dry-run verified, `git merge-tree`): mechanically CLEAN, no conflicts.** Only two files
touched by both sides since the merge base (`b6d3fcbc1`): `config/environments/staging.rb` (ours: L1 +
21–27 secrets→config_for/dalli; theirs: L36–39 Uglifier→`:terser` — different regions) and `Gemfile`
(both kept: rails 8 + sidekiq 7 + redis 5 from us, `terser` from them).
`config/secrets.yml` resolves correctly: ours was a **pure rename** (100% similarity) to
`app_secrets.yml`, theirs edited the content (`MEMCACHE_SERVERS` env-overridable) — the merged
`app_secrets.yml` keeps **their** edit. Verified.

**Sequence (steps 1–5 are ours; keep LOCAL until we're ready to push):**
1. ~~Commit + push the GDAL OpenFileGDB swap to `upgrade-plan`~~ — **DONE locally (merged, not pushed).**
   Was the blocker: `origin/upgrade-plan` still had `gdb: 'FileGDB'`.
2. Merge `upgrade-plan` → `staging_kamal`.
3. **`bundle install` + commit the regenerated `Gemfile.lock`.** ⚠️ The lock merges "cleanly" but is
   **inconsistent** — the merged Gemfile has `terser` while the merged lock does not (git keeps our
   lock). `bundle check` fails until regenerated. Classic trap; don't skip.
4. Run the full suite on the merged branch.
5. Fix stale comments referencing the old `config/secrets.yml` path: `Dockerfile.deploy:110`,
   `config/deploy.staging.yml:57`. (Also: `Dockerfile.deploy` cites `docs/GDAL-openfilegdb-migration.md`,
   which does not exist in that tree.)
6. Push `staging_kamal` → the GH Action deploys to `pp-web-staging-01`. **Needs devops**: the
   `staging_proxmox` GitHub environment + secrets (registry creds, SSH key) populated.
7. **Verify `.gdb` download end-to-end on staging** — the in-app GDAL 3.8 / OpenFileGDB validation we
   cannot do locally (PP's dev image is GDAL 2.2.3, OpenFileGDB read-only there). This also serves the
   data-team ArcGIS sign-off.

**Not blocked on the frontend.** `staging_kamal`'s Dockerfile builds *both* webpacker and Vite, matching
`upgrade-plan`'s current asset setup. `feat/upgrade-frontend` (which removes webpacker) is a separate,
later change needing its own Dockerfile update + the psych unpin. Frontend was **97 ahead / 64 behind**
upgrade-plan and still committing daily — waiting only grows that merge.

**Open questions for devops:** PG version/PostGIS on `pp-db-staging-01` (drives postgis-adapter 11 and
the PG 10→17 story); whether the `staging_proxmox` env/secrets are populated. Also note the deploy
config still assumes **host Memcached + a single Redis** — our two-Redis / drop-Memcached decision
(§4e) is not reflected there yet; that's the follow-up once devops provisions them.

## 6. Minor code items (low priority, clear opportunistically)
- [ ] **`belongs_to_required_by_default` opted out** (`config/application.rb`) — revisit as a data-integrity pass measured against a **production** dump. 4 associations have real NULLs: `Country#parent` (199/248), `Designation#jurisdiction` (57/1831), `pame_statistics.country`, `country_statistics.country`.
- [ ] **`_info.svg` orphan partial** — `app/views/partials/svgs/_info.svg` is not rendered via `render` (only an unrelated SCSS `info.svg` asset ref exists). Confirm unused, then remove. (`_pin.svg` was renamed to `_pin.html.erb` to clear the dotted-template deprecation — do the same or delete `_info.svg`.)
- [x] **DONE — Mocha strict-keyword-argument warnings** (Tier-1 modernization). 10 sites where a
      `#with` expectation used a positional hash but the code passes kwargs (`system(cmd, chdir:)` in
      `download/generators` csv/shapefile tests), or vice-versa (downloads_controller tests expected
      kwargs but `Download.request/poll` take a single positional `params.permit!`). Fixed:
      generator tests → `chdir:`/`**opts` kwargs; controller tests → block matchers on
      `p.to_unsafe_h`. Then enabled `c.strict_keyword_argument_matching = true` in `test_helper.rb`
      so mismatches are enforced, not warned. Suite 681/0, 0 Mocha warnings.
- [x] **DONE — Tier-2 idiom cleanups.** (1) `FactoryGirl` → `FactoryBot` across all 38 test files
      (~384 call sites) and removed the `FactoryGirl = FactoryBot` compat alias from `test_helper.rb`.
      (2) Safe AR dynamic finders → `find_by(col:)`: `find_by_slug/site_id/name/id/iso_3/css_class`
      in app + lib. **Left intentionally:** `Release.find_by_backup_timestamp_string` (custom method,
      not an AR finder), `Comfy::Cms::Page.find_by_full_path` (Comfy internal), `find_by_older_version_id`
      (dead versioning feature, pending removal decision). Suite 681/0.
- [ ] **`Searchable` constants inside `included do`** (`app/controllers/concerns/searchable.rb:22`) — re-initialized per including controller; cosmetic, no behaviour change.

## 7. Dead code found during the upgrade (already removed — for reference)
- `Search::ParallelIndexer` (dead + `require 'thwait'` unloadable on 2.7) — removed.
- `best_in_place` gem (unused; its railtie caused the ActionText/ActionView boot deprecations) — removed.
