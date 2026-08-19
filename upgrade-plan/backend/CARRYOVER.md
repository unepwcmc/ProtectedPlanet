# Backend upgrade — carryover / deferred items

Running log of things intentionally **not** done yet, with **when** to pick each up.
Keep this current as phases land. Last updated: 2026-08-18 (staging deploys, phases 1 + 2).

Status at this point: **Rails 8.0.5**, Ruby 3.3.7, Zeitwerk, `load_defaults 8.0`,
postgis-adapter 11.0. Suite **714 runs, 0 failures, 7 skips**; coverage ~65.4%, SimpleCov floor 62.
**Live on staging** (`pp-web-staging-01`, Kamal v2) with the Vite/Vue-3 frontend — see §5b.
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
- [x] **DONE (superseded) — staging deploy.** The Ubuntu 18.04 / Ruby 2.6.3 blocker is gone: staging
      moved to the Proxmox Kamal host (`pp-web-staging-01`, Ubuntu 24.04) and now runs
      **Rails 8.0.5 / Ruby 3.3.7**, well past the 6.1 milestone this line was waiting on. See §5b.
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
      **UPDATE (Aug 2026): webpacker is GONE** (Vite cutover shipped in phase 2), so only
      `appsignal ~> 3.3.11` still blocks the pin. Bump appsignal, then try removing it.
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
- [ ] **Raise the SimpleCov floor** (`test/test_helper.rb`, **now 62**; actual ~65.4%) as coverage improves. Never lower it.

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
- [x] **DONE — deploy runs `comfy:compile_assets` before `assets:precompile`.** Added to
  `Dockerfile.deploy` (Aug 2026). This bit us for real: the Kamal image never ran it, and
  the CMS admin CSS/JS only appeared because the app carried its own
  `app/assets/{javascripts,stylesheets}/comfy/` overrides. The Vite cutover deleted those,
  the admin assets vanished, and the phase-2 image build failed on the asset assertion.
  Verified after the fix: the gem's `app/assets/builds/comfy/admin/cms/` is populated in the
  deployed image (it never was before, phase 1 included). `bin/preflight-deploy` mirrors
  the same order **and wipes the gem builds dir first**, because a stale populated dir in
  the shared bundler volume made the check pass locally while the real build failed.
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

### 5b. Staging deploys — SHIPPED (Aug 2026)
Both phases are live on `pp-web-staging-01`. Prerequisites that were open in §5a resolved
themselves: SSH access granted, `staging_proxmox` secrets populated, self-hosted runner working,
DB reachable with **all 204 migrations already applied**.

**Phase 1 (backend only)** — `staging_kamal` @ `a0a1f3b9`. Rails 7.1.6 → **8.0.5.1**, Ruby 3.3.7,
redis 5 / Sidekiq 7, secrets→`config_for`. Verified live: containers healthy (web + job_default +
job_import), and a `.gdb` export **through the app's own `Ogr::Postgres.export`** against the real
staging DB produced `Geometry Column = SHAPE` — the end-to-end GDAL validation that could not be
done locally. Before the deploy, staging was emitting `the_geom`.

**Phase 2 (frontend + backend)** — `staging_kamal` @ `a88a1d99`. Adds the Vite/Vue 3/Turbo frontend,
**webpacker fully removed** (gem, `config/webpack/*`, `babel.config.js`, and its build step), so the
image now builds **two** asset pipelines instead of three. `.gdb` re-verified: still `SHAPE`.

**Four failed attempts before phase 1 landed — each a real bug, and staging was never broken
(every failure hit before the container swap):**
1. `config.secret_key_base = config_for(...)` assigned nil during `assets:precompile`, which runs
   with `SECRET_KEY_BASE` unset and `SECRET_KEY_BASE_DUMMY=1`. Rails 8's setter raises on blank
   outside dev/test, bypassing that escape hatch. Fixed: only assign when present.
2. + 3. The pre-deploy hook's `kamal app exec` fans out to **every role**, so web + job_default +
   job_import each ran `db:migrate` concurrently and raced the advisory lock
   (`ActiveRecord::ConcurrentMigrationError`). `--primary` was NOT enough — it narrows *hosts*, and
   all three roles share one host. `--roles web` is what reduces it to a single container.
4. (phase 2) `comfy:compile_assets` missing from the image — see §4b.

**`bin/preflight-deploy`** was added after #1–3 and encodes all of it: hooks executable + mode 100755
+ no `app exec` without `--roles`; workflow submodule checkout; the suite; `assets:precompile` in the
build environment; staging boot. It has since caught two phase-2 breakages before they cost a deploy
cycle (the stale `application-*.css` assertion, and the comfy step). Run it before every push:
`./bin/preflight-deploy` — it prints `✅ ready: git push origin staging_kamal` or refuses.

**Follow-ups from these deploys:**
- [ ] **Runner locale — for devops.** Kamal reported
      `ERROR (Encoding::CompatibilityError): invalid byte sequence in US-ASCII` (sshkit
      `String#strip`) *instead of* the real error, twice. The self-hosted runner's locale is
      US-ASCII, so any non-ASCII build output masks the genuine failure. Set `LANG=C.UTF-8` /
      `LC_ALL=C.UTF-8` on the runner. Turned a 30-second diagnosis into a 4,600-line log dig.
- [ ] **`public/packs` is committed** — 15 stale webpack outputs, dead since the Vite cutover and
      still shipped in the image. `git rm -r --cached public/packs` + gitignore it. Nothing
      references them (0 `*_pack_tag` calls anywhere).
- [ ] **Narrow the `assets:precompile ||` tolerance in `Dockerfile.deploy`.** It exists for
      vite_ruby's nested `vite:build_all`, which always exits non-zero with a bare
      "Compilation failed:" while sprockets succeeds — but it also swallowed the genuine
      `secret_key_base` crash in failure #1. The output assertions catch it eventually; a tighter
      guard would surface it immediately.
- [x] **DONE — `.gitignore` missed rotated logs.** `/log/*.log` matches `test.log` but not
      `test.log.0`, so a **246 MB** `log/test.log.0` became tracked and GitHub rejected the push
      (100 MB limit). Purged from the 4 local-only commits with `filter-branch` (nothing already on
      origin was rewritten; verified the only tree difference was that file) and the pattern is now
      `/log/*.log*`.

**Still unverified — needs a human at a browser.** The suite is rack-test only, so Vue 3 + Turbo
runtime behaviour is genuinely untested (see the "no system/browser tests" item in §3). Worth
exercising on staging: search (autocomplete, filters, infinite scroll), maps, the download modal
(CSV/SHP/GDB), and **`/en/admin`** in particular — its assets are newly built as of phase 2.

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

---

## 8. Staging runtime audit (Aug 2026) — shared Redis, dead PDF paths, gem bloat

Triggered by a download on staging that span "Generating..." forever. The audit
that followed looked for the general class of problem: code no test covers and no
build step validates, which therefore only fails on a server.

### 8a. Shared Redis across co-located Kamal apps — FIXED (code), needs deploy

Three of our apps on `pp-web-staging-01` were handed the same Redis URL, all on
logical database **0**:

| app | var | db | queues | sidekiq |
|---|---|---|---|---|
| protectedplanet | `REDIS_URL` | 0 | `default`, `import` (+ `$redis` downloads) | 7.3.9 |
| wdpa-pp-data-management-portal | `SIDEKIQ_REDIS_URL` | 0 | `upload`, `default` | 7.2.2 |
| api-pp-authentication | `SIDEKIQ_REDIS_URL` | 0 | `default` | 7.3.2 |

`pp-digital-report`, `pp-data-management-portal` and `protectedplanet-api` use no
Redis. All three affected apps are ours (`unepwcmc/*`), so this is fixable without
devops beyond env values.

Sidekiq 7 removed namespace support, so `queue:default` was ONE physical Redis
list shared by three different Rails apps. Whichever process popped a job first
won it. The two that could not resolve the job's constant raised `NameError`, and
`DownloadWorkers::Base` sets `retry: false`, so the job was discarded with no
trace — observed as `processed=8 failed=7` with `retry=0 dead=0`.

Because nothing wrote the result key, it stayed `generating` with **no TTL**
(`ttl=-1`), and `Download::Requesters::Base#enqueue_generation_once` then refused
every later request for that download. Permanently wedged.

Fix, in `config/initializers/redis.rb` + `sidekiq.rb`: `PPRedis.url` pins this app
to its own logical DB (default **3**, override with `REDIS_DB`). Both
`configure_server` AND `configure_client` now use it — previously only the server
was configured and the client fell back to Sidekiq's raw `REDIS_URL` default,
which would have split enqueue and run across two databases.

- Production runs its own Redis, so set `REDIS_DB=0` there to keep using the
  database its existing keys live in, or accept a one-time reset of download
  status keys (they regenerate).
- The other two apps still collide with each other on db 0. Separate ticket in
  their repos: move them to db 1 and 2.

### 8b. Download keys never expired — FIXED (code)

The staging Redis runs `--maxmemory 2gb --maxmemory-policy noeviction`. PP wrote
`downloads:*` keys with no TTL at all, so the keyspace only grew; at the ceiling
Redis starts refusing writes **for all three apps**, not just PP.

- `Download::Utils.write` is now the single write path and always sets an expiry
  (`READY_TTL` 30d / `GENERATING_TTL` 24h / `FAILED_TTL` 1h).
- `#stale_generation?` lets a wedged key recover: past a 15-minute grace it asks
  Sidekiq whether the jid is still alive, and only then re-enqueues. Age alone is
  never the test — a full-WDPA `.gdb` export legitimately runs for hours.
- `job_alive?` assumes **alive** if Sidekiq is unreachable, so a blip cannot cause
  an enqueue stampede; `GENERATING_TTL` is the backstop.
- `while_generating` now rescues `Exception`, not `StandardError`.
  `NotImplementedError` is a `ScriptError` and sailed straight past the old
  rescue, stranding the key. Signals are re-raised after the key is marked.

Covered by `test/unit/download/requesters/stale_generation_test.rb` (8 tests) and
3 new TTL tests in `utils_test.rb`. Before this there was **no** test of
`enqueue_generation_once` at all.

### 8c. Both PDF paths were broken on staging — FIXED (code), needs deploy

`Dockerfile.deploy` ended the asset build with `rm -rf node_modules`, on the
assumption Vite had bundled everything into `public/vite`. True for the frontend,
but **puppeteer is a runtime dependency**: both PDF paths shell out to
`node app/frontend/backend-scripts/rasterize.js`, which does
`require('puppeteer')`. Confirmed in the running container:

```
ls: cannot access 'node_modules': No such file or directory
require("puppeteer") -> MODULE_NOT_FOUND
```

- `rm -rf node_modules` → `yarn workspaces focus --production` (keeps the 11
  runtime deps, drops the 24 dev ones), followed by a hard
  `node -e "require('puppeteer')"` assertion so a bad prune fails the build.
- `app/controllers/country_controller.rb` still shelled out to **`phantomjs`** —
  a binary that is not in the image at all (`command -v phantomjs` → not found).
  `rasterize.js` was ported from PhantomJS to Puppeteer and this call site was
  missed while `Download::Generators::Pdf` was updated. Now uses `node`, and
  raises instead of `send_file`-ing a file that was never written.

### 8d. Deprecated-API sweep — CLEAN

Scanned `app lib config db` for Ruby 3.0–3.3 and Rails 5.2–8.0 removals:
`URI.escape/encode`, `taint/untaint`, `Fixnum/Bignum`, `Random::DEFAULT`,
`BigDecimal.new`, `File/Dir.exists?`, `YAML.load`, `update_attributes`,
`*_filter`, `render text:`, `alias_method_chain`, `errors.keys`, `serialize`
without coder, positional `enum`, `legacy_connection_handling`,
`ActiveSupport::Deprecation` singleton, `Rails.application.secrets`.

Live hits: **none**. `URI.encode` was the only one and is fixed.

- `lib/modules/search.rb:18` uses `YAML.load`, safe only because `psych` is
  pinned `~> 3.3`. Under Psych 4 that becomes `safe_load`. `config/search.yml`
  has no aliases, symbols or `!ruby` tags, so it is safe to unpin — but change
  this line at the same time.
- `ActiveRecord::Base.connection` — 21 sites. Soft-deprecated in 7.2, works in
  8.0, will break later. Migrate to `lease_connection`/`with_connection`.
- One `update_attributes` in a 2017 migration. `schema_format = :sql` means
  migrations never replay, so it is inert; all 204 are version-bracketed.

**Conclusion: grep is exhausted as a technique here.** The remaining risk is
runtime-only, so the next net must be empirical — see 8f.

### 8e. Gem bloat / dead deploy system — NOT STARTED

- **`gem 'aws-sdk', '3.0.1'` is the v3 meta-gem: 664 `aws-sdk-*` gems in
  `Gemfile.lock`.** Code uses `Aws::S3` only → `aws-sdk-s3`. Big win on bundle
  install time, image size and boot.
- **Capistrano is still fully wired post-Kamal**: `Capfile`, `config/deploy.rb`,
  `config/deploy/{production,staging}.rb`, `config/deploy/ansible/`, 8
  `capistrano-*` gems plus `net-scp`, `net-sftp`, `bcrypt_pbkdf`. Two deploy
  systems in one repo is a live footgun — delete.
- Confirm individually then drop: `phantompdf` (PhantomJS is gone),
  `jquery-rails` (no sprockets refs post-Vite), `sinatra` (Sidekiq 7 web is pure
  Rack), `httmultiparty`, `slack-notifier`, `levenshtein`, `awesome_print`,
  `timecop`, `selenium-webdriver`.
- Then unpin `psych` (webpacker is gone; appsignal was the other blocker).

Needs `bundle install` via docker-compose — ruby 3.3.7 is not installed locally
(rbenv has 3.3.2), so all verification runs in the container.

### 8f. Route smoke test — BUILT (Aug 2026)

`lib/smoke/route_walker.rb` + `lib/tasks/smoke.rake`. Run it inside the container
it is testing, because it reads real fixtures (a protected area, a country iso,
CMS page paths) out of the database and then drives the app over HTTP:

```
kamal app exec --destination staging --primary --roles web \
  "bundle exec rake smoke:routes"
```

Env: `BASE_URL` (default http://localhost:3000), `CMS_SAMPLE`, `TIMEOUT`,
`INSECURE`. Exits non-zero on any failure, so it can gate a deploy.

**The design property that matters is coverage enforcement.** Every GET route
must either be walked or appear in `SKIP_CONTROLLERS`/`SKIP_PATHS` with a stated
reason; anything else is reported UNCLASSIFIED and fails the run. Adding a route
to the app therefore forces a decision about smoking it, instead of the net
silently shrinking. `test/unit/smoke/route_walker_test.rb` (12 tests) asserts
that property directly.

Two things had to be got right, both found by running it and disbelieving the
output:

- **Locale prefix.** `get '/:id'` is declared at the top of routes.rb, ABOVE the
  `scope '(:locale)'` block, so it shadows every single-segment path: bare
  `/search`, `/terms`, `/search-areas` and every CMS slug resolve to
  protected_areas#show and 404. Only the `/en/...` form reaches the route that
  was declared. Confirmed against production, which behaves identically (it 500s
  rather than 404s). The walker substitutes a locale rather than stripping it.
- **204 is a failure.** Rails answers `204 No Content` when an action runs with
  no template. The first version scored that "ok" and walked straight past a
  broken page — see country#pdf below.

Current staging result: **34 walked, 27 healthy, 7 failed.**

| endpoint | status | verdict |
|---|---|---|
| `/assets/tiles/:id?type=protected_area\|country\|region` | 500 | the `URI.encode` bug — fix committed (27778c9e9), not yet deployed. The smoke test found it unprompted, which is the validation that it works. |
| `/country/:iso/pdf` | 204 | **FIXED.** `country#pdf` was just `@for_pdf = true`; `app/views/country/pdf.*` does not exist and Rails answers 204 when an action renders nothing, so the page the rasterizer captured was empty. It also sat outside the `only: :show` before_actions, so `@tabs`/`@stats_data` were never built. Now shares `load_show_data` with `#show` and does `render :show`, so the two cannot drift. Was broken twice over: this AND the §8c missing binary. |
| `/country/:iso/compare/:iso_to_compare` | 404 | **FIXED (removed).** Route was declared at routes.rb:31 but CountryController never had a `compare` action, and nothing in app/, lib/, test/ or the frontend referenced `compare_countries_path`. Deleted, with a note left at the declaration site. |
| `/en/search-cms` | 500 | **NEW**, pre-existing (production 500s identically). `TypeError (String does not have #dig method)` at `app/serializers/search/cms_serializer.rb:101` — `@search.options` is a String, so `.dig(:filters, :ancestor)` raises. Works in practice only because the frontend always sends filters. |

None of the three new ones are upgrade regressions; all four had zero test
coverage and would not have surfaced without this.

Two of the four are now fixed (country#pdf, the dead compare route). Remaining
red: the tiles 500 (clears on the next deploy, fix already committed) and
`/en/search-cms` (pre-existing, 500s on production too). Once those are clear,
wire the walk into `bin/preflight-deploy` or a post-deploy hook so a red run
means something new.

### 8g. Bundler binstubs — NOT STARTED

`bin/rails` / `bin/bundle` are Bundler-generated, not Rails-generated, so any
`bin/rails` invocation prints the `rails new` help text instead of running.
It made `rails runner` on staging look like it had failed when it had not, and
`bin/rails test` unusable in docker-compose (`bundle exec` is the workaround).
Fix: `bundle binstubs bundler --force` + `rails app:update:bin`.

### 8h. Sidekiq scheduler thread is dead on every boot — FIXED (code), needs deploy

Both job containers log at startup:

```
connection_pool-3.0.2/lib/connection_pool/timed_stack.rb:62:in `pop':
  wrong number of arguments (given 1, expected 0) (ArgumentError)
  from sidekiq-7.3.9/lib/sidekiq/scheduled.rb:226:in `initial_wait'
```

Verified against the gem sources on staging rather than inferred from the trace:

```ruby
# connection_pool 3.0.2 -- keyword-only
def pop(timeout: 0.5, exception: ConnectionPool::TimeoutError, **)
# sidekiq 7.3.9 scheduled.rb:226 -- positional
@sleeper.pop(total)
```

connection_pool is only ever transitive here (activesupport `>= 2.2.5`, sidekiq
`>= 2.3.0`, both open-ended), so bundler resolved 3.0.2 unchallenged. The
**scheduler thread died at boot**, so the scheduled and retry sets were never
polled: `perform_in`/`perform_at` silently did nothing and no failed job was ever
retried. Nothing surfaced in the UI — only a stack trace on stdout at container
start. Did not cause the download bug (those jobs go straight to a queue).

Fixed by pinning `connection_pool ~> 2.5` in the Gemfile (resolves 2.5.5;
`pop params: [[:opt, :timeout], [:opt, :options]]`, verified under bundler). The
lock diff is two lines. `test/unit/sidekiq_connection_pool_test.rb` is the
tripwire so a future `bundle update` cannot reintroduce it silently.

Lift the pin when we move to Sidekiq 8, which supports connection_pool 3.x — the
third test in that file asserts the Sidekiq major so it fails as a reminder.

### 8i. Deploy of the §8 fixes FAILED first time — my bug (Aug 2026)

`config/initializers/redis.rb` raised on a blank `REDIS_URL`. The image build boots
the whole Rails app during `assets:precompile` / `vite:build_all` with **no runtime
secrets** — the same reason `SECRET_KEY_BASE_DUMMY` exists — so the build died ~13
minutes in:

```
rake aborted!
REDIS_URL is not set -- cannot configure Redis
/app/config/initializers/redis.rb:32:in `url'
Tasks: TOP => vite:build_all => vite:verify_install => environment
```

Same class as the deploy-#1 `secret_key_base` crash recorded in §5b: a hard failure
added to an initializer that also runs at build time. Fixed by falling back to
redis-rb's own default host/port instead of raising — `Redis.new` never connects on
instantiation, so a genuinely missing URL still surfaces at first use, which is the
behaviour that existed before this file pinned a database.

`test/unit/pp_redis_test.rb` (5 tests) locks both directions: blank URL must not
raise, configured URL must still land on our database. Verified the test fails with
the `raise` reinstated, not just that it passes without it.

**Why preflight did not catch it — two independent gaps, both now closed:**

1. It cleared only `SECRET_KEY_BASE`. It now blanks **every** secret declared under
   `env.secret` in `config/deploy.yml` except the four `Dockerfile.deploy` provides
   itself, derived from the YAML so a newly added secret is covered automatically.
2. Clearing the shell environment was not enough on its own. The `dotenv` gem
   re-reads `.env` during Rails boot and docker-compose bind-mounts the repo, so
   `ENV` was repopulated from the file regardless of `-e`. `.dockerignore` excludes
   `.env*`, so the real image has no such file. Preflight now bind-mounts an empty
   file over `.env` for the build-environment steps.

Gap 2 is the important one: `-e REDIS_URL=` *looked* like it worked and silently did
nothing, so the build-env checks had been running against a runtime environment all
along. With both fixes, the failure reproduces locally in ~20s instead of 13min.

### 8j. Post-deploy verification of the §8 fixes (Aug 2026) — a5c4bc774

Deploy succeeded. Verified against a baseline captured on the previous image:

| check | before | after |
|---|---|---|
| Redis logical DB | shared `/0` with 2 other apps | **`/3`, PP only** |
| `Sidekiq::ProcessSet` | 4 processes (7.2.2, 7.3.2, 7.3.9 ×2) | **2 processes, both ours** |
| sidekiq `initial_wait` crash | present every boot | **0 occurrences** |
| `node_modules` / puppeteer | absent, MODULE_NOT_FOUND | **present (161 pkgs), requires OK** |
| `/country/:iso/pdf` | 204 empty | no longer empty (see 8k) |
| `/country/:iso/compare/:iso` | 404 dead route | route removed |
| download `14426` csv | stuck "generating" forever | **ready in 4s, ttl 2591997** |
| pre-deploy hook | — | migrations ran, `--roles web`, no lock race |
| post-deploy hook | — | `==> Cache flushed` |

`yarn workspaces focus --production` worked; the `require('puppeteer')` assertion
in the build passed, so both PDF paths now have their runtime dependency.

Smoke test: **33 walked, 28 healthy, 5 failed** (was 7). Remaining failures are
`/en/search-cms` (§8f, pre-existing, 500s on production too) and 3× `assets#tiles`
— which turned out NOT to be the URI.encode bug. See 8k.

### 8k. Two findings the post-deploy smoke run exposed

**1. `MAPBOX_STATIC_IMAGE_URL` was missing from the deploy config — FIXED, needs a GitHub secret**

The `URI.encode` fix worked; that exception is gone. Behind it sat a second,
pre-existing failure:

```
NoMethodError (undefined method `+' for nil)
lib/modules/asset_generator.rb:47:in `mapbox_url'
```

`base_url` comes from `ENV["MAPBOX_STATIC_IMAGE_URL"]` (config/app_secrets.yml
default block). That variable is in `.env` and `.env.example` but was never added
to `config/deploy.yml`, so it is UNSET on staging and `nil + String` raises. The
static-image tiles (map overlay thumbnails, search-result cards) have therefore
never worked on staging.

Value is `https://api.mapbox.com/styles/v1/unepwcmc/<style_id>/static/` — a style
URL used server-side, not a credential, but org-specific, so it is wired as a
secret rather than committed. THREE places had to change; missing any one of them
means Kamal never receives it:

1. `.kamal/secrets-common` — `MAPBOX_STATIC_IMAGE_URL=$MAPBOX_STATIC_IMAGE_URL`
2. `config/deploy.yml` — under `env.secret`
3. `.github/workflows/deploy-staging-kamal.yml` — `${{ secrets.MAPBOX_STATIC_IMAGE_URL }}`

Still required: add `MAPBOX_STATIC_IMAGE_URL` to the **`staging_proxmox`
environment** secrets on GitHub, not the repository secrets — environment secrets
override repository ones, and getting that backwards cost a full deploy cycle with
MAPBOX_ACCESS_TOKEN (see §8/5b). Production needs it too, or its tiles break the
same way when it moves.

Note: distinct from MAPBOX_ACCESS_TOKEN, which is BOTH a builder secret (Vite
inlines it into the client bundle at build time) and a runtime secret. This one is
runtime-only — it is read server-side by AssetGenerator — so it does NOT belong
under `builder.secrets`.

**2. EVERY country page 302'd to the homepage — FIXED**

`app/models/country.rb#coverage_growth` relied on PostgreSQL's implicit output
name for an unaliased `EXTRACT(...)`, which was `date_part`. **PostgreSQL 14
renamed it to `extract`**, so on staging:

```
PG::UndefinedColumn: ERROR:  column "date_part" does not exist
LINE 1: SELECT TO_TIMESTAMP(date_part::text, 'YYYY') AS year...
```

ApplicationController rescues it into a redirect, so every country page silently
302'd to `/en` with no visible error and a 200-looking smoke result.

Three PostgreSQL majors are in play and they disagree:

| environment | PostgreSQL | implicit EXTRACT column |
|---|---|---|
| production | 10 | `date_part` |
| local docker-compose | 11.7 | `date_part` |
| **staging (Kamal/Proxmox)** | **17.5** | **`extract`** |

So this could not reproduce locally, and production is unaffected — it only
appears on the new infrastructure. Fixed by aliasing the grouped expression
explicitly (`AS year_part`); `protected_areas_inner_join` takes an optional
`alias_as:` and the GROUP BY keeps the raw expression, since
`GROUP BY <expr> AS <name>` is invalid SQL.

Verified both shapes against the real PG 17 staging database: the old one fails
with the exact error, the new one returns 6 rows. Also confirmed still working on
local PG 11, so no regression for production's PG 10.

Guarded by SQL-shape assertions in `test/models/country_test.rb`, not a functional
test — on PG 11 the old SQL passes, so a functional test would have stayed green
while staging was broken.

**Worth noting separately:** ApplicationController's blanket rescue turned a 500
into a 302 and hid this completely. Consider letting it re-raise in staging, or at
least reporting to AppSignal before redirecting.

### 8l. Pre-deploy shadow verification (Aug 2026) — smoke went fully green

Deploy cycles cost ~15 min, so instead of pushing and discovering failures, the
not-yet-deployed code was verified against the real staging database first.

**Technique — worth reusing.** Create a container from the CURRENTLY DEPLOYED image
on the staging host, `docker cp` the changed files in *before* `docker start` (so
eager-load picks them up), give it the Kamal role env file plus any new secret, and
run `rake smoke:routes` against its own Puma. The live containers are untouched.

```
docker create --name pp-shadow --network kamal \
  --env-file .kamal/apps/protectedplanet-staging/env/roles/web.env \
  --env-file /tmp/extra.env -e MEMCACHE_SERVERS=host.docker.internal:11211 \
  --add-host host.docker.internal:host-gateway \
  --volume /data/pp-imports:/app/tmp/imports \
  <image> bundle exec puma -C config/puma.rb
docker cp <changed files> pp-shadow:/app/...
docker start pp-shadow
docker exec pp-shadow bash -lc 'cd /app && bundle exec rake smoke:routes'
```

This gives real PG 17, real data, real Elasticsearch and real S3 without a deploy.
It found two further bugs that would otherwise have cost two more cycles.

**Confirmed working pre-deploy:** country pages 200 (were 302), country PDF 200
(was 204), all three tile types 200 with real PNG bytes, and every download format
generated — csv 11.2 MB, shp 11.2 MB, gdb 11.2 MB (OpenFileGDB), **pdf 11.4 MB via
Puppeteer in 12.1s**, which is the path that had no runtime dependency in the image
until this round.

**POST endpoints, which smoke:routes does not cover**, tested with a real CSRF token
and session: `search#autocomplete` 200 (7.4 KB JSON), `pame#list` 200 (16.8 KB),
`pame#download` 200 (13.9 KB CSV), `downloads#create` 200.

Final: **37 walked, 37 healthy, 0 failed — smoke:routes passed.**

### 8m. Three more bugs the shadow run exposed — ALL FIXED

**1. `AssetGenerator` — square brackets broke the tile URL (Ruby 3)**

Fixing `URI.encode` and adding `MAPBOX_STATIC_IMAGE_URL` still left tiles at 500:

```
URI::InvalidURIError (bad URI (is not URI?): ".../geojson(%7B..."coordinates":
  [[[-61.825,17.185],...]]]%7D%7D)/auto/304x138@2x?access_token=...")
lib/modules/asset_generator.rb:53:in `request_tile'
```

`URI::DEFAULT_PARSER.escape` leaves `[` and `]` alone — RFC 2396 reserves them for
IPv6 literals in the HOST component — and every GeoJSON geometry is full of them.
Fixed with `UNSAFE_IN_PATH`, the RFC 2396 default set minus `\[\]`. Four escape
strategies were tested against the live Mapbox API: the old one fails to parse, the
new one returns HTTP 200 with 8483 bytes of PNG. This is the THIRD distinct bug
behind /assets/tiles/:id, each hidden by the one before it.

**2. `ActiveStorage::Blob#service_url` — removed in Rails 7.0**

```
NoMethodError (undefined method `service_url' for an instance of ActiveStorage::Blob)
app/models/comfy/cms/searchable_page.rb:52:in `image'
```

Three call sites (`searchable_page.rb`, `cms_serializer.rb`, `cms_helper.rb`), all
on the non-development branch, so they only ever raised on staging/production.
`/search-cms?search_term=...` 500'd as soon as any result carried an image.
Renamed to `#url`.

**This one is a genuine miss in the §8d static sweep** — `service_url` was not on
the list of removed APIs scanned for. Guarded now by a test that greps app/ and
lib/ for it, which is cheap and version-proof.

**3. `Search::CmsSerializer` — `''` is not a Hash**

`Searchable#filters` returns `''` (not `{}`) when no filters are supplied, so
`options` is `{filters: ''}` and `Hash#dig(:filters, :ancestor)` called
`''.dig(:ancestor)`:

```
TypeError (String does not have #dig method)
app/serializers/search/cms_serializer.rb:101
```

An unfiltered `/search-cms` 500'd on production too — it only ever worked because
the frontend always sends filters. Guarded in the serializer rather than changing
what `#filters` returns, since that value also feeds the query builder and `''` vs
`{}` is not a change worth making blind.

### 8n. Latent fragilities noted, not fixed

- `Ogr::Postgres.get_feature_name` raises `IndexError` on any filename that does
  not follow `WDPA_MmmYYYY_Public[_id][_geom]`. Unreachable in normal flow (callers
  go through `Download::Utils.filename`), but it fails loudly and unhelpfully.
- `PameEvaluation.paginate_evaluations` reads `requested_page`; anything else gives
  `nil.to_i == 0` and `RangeError (invalid page: 0)`. `page_number || 1` does not
  help because `0` is truthy in Ruby.
- **ApplicationController's blanket rescue turns 500s into redirects.** It hid a
  completely broken country section (§8k) — every country page was down and nothing
  reported it. Consider re-raising in staging, or reporting to AppSignal before
  redirecting.

### 8o. Deploy 8430f49d0 — smoke fully green on staging (Aug 2026)

`rake smoke:routes` on the deployed image: **37 walked, 37 healthy, 0 failed.**
First green run against real staging. Hooks both ran (migrations, `Cache flushed`),
and `MAPBOX_STATIC_IMAGE_URL` was delivered.

| endpoint | before | now |
|---|---|---|
| `/assets/tiles/:id` ×3 types | 500 | **200, real PNGs** (8.4 KB / 54 KB / 47 KB) |
| `/en/country/:iso` | 302 to homepage | **200** |
| `/en/country/:iso/pdf` | 204 empty | **200** |
| `/en/search-cms` (+query) | 500 | **200** |

`/assets/tiles/667` returns 302 to `search-placeholder-country.png`. That is the
designed fallback in `AssetsController#tiles` for a record with no usable geometry,
not a failure.

### 8p. PDF exports render without the map — NOT FIXED

Found while trying to get extension-free browser evidence for the map, by running a
headless browser inside the container. **First, a correction worth recording:** that
probe reported `SyntaxError: Unexpected token '{'` loading the Map chunk, which
looked like a real bug. It was not:

```
puppeteer 5.5.0  ->  HeadlessChrome/88.0.4298.0   (Jan 2021)
class A { static { } }  ->  "Unexpected token '{'"
```

Chromium 88 cannot parse ES2022, which the Vite 7 output uses. Always check the
browser version before trusting a headless probe.

**But `rasterize.js` uses that same `require('puppeteer')`**, so Chromium 88 is what
renders every PDF. Measured on the live page:

```
{"islandHosts":13,"islandsWithContent":11,"mapCanvas":false}
```

11 of 13 Vue islands mount (the entrypoint parses fine); only the lazily-imported
Map chunk fails, because it bundles maplibre-gl's modern syntax. So **every PDF
export is missing its map**, while generating successfully — 11.4 MB, no error, 200
from the endpoint. Invisible to `smoke:routes` and to byte-count checks.

Note this also qualifies the §8l verification: "pdf 11.4 MB via Puppeteer in 12.1s"
proved the path *generated*, not that the output was correct.

Fix: bump `puppeteer` from `^5.5.0` (2020). Needs code changes — `page.waitFor()`
was renamed to `waitForTimeout` in v10 and removed in v22 — plus re-verifying the
bundled Chromium download in the image build, and an assertion on PDF *content*
rather than size.

### 8q. Still unexplained: the base map does not render in a real browser

Every server-side link verified healthy on the deployed image: HTML asset digests,
all assets 200, `VITE_MAPBOX_TOKEN` inlined, Mapbox styles 200, `composite` vector
source 200, glyphs 200, no Referer/URL restriction, `data-gis` overlays 200, map
component mounts with well-formed props, all 44 built JS files parse, and the Map
chunk is served byte-identical to disk over both plain and brotli.

The headless probe cannot settle it (Chromium 88, see 8p) and the in-app browser
pane blocks the bundle with `ERR_BLOCKED_BY_CLIENT`. Needs a real modern browser
with extensions disabled: incognito, Network tab filtered to `mapbox` —
- no `api.mapbox.com` requests at all -> map never initialises, look for a JS
  exception above it
- 401 or `access_token=undefined` -> the token is not reaching `transformRequest`
- 200s and still blank -> Vue sizing/render bug in `Map/Base.vue`

Both browsers seen so far carry heavy extension interference (MetaMask
`ObjectMultiplex`, rokt.com, "Host is not in insights whitelist"), so an extension
remains a live possibility.

### 8r. puppeteer 5.5.0 -> 25.8.0 — FIXED (§8p)

`package.json` pinned `"puppeteer": "^5.5.0"` (2020), which bundles **Chromium 88**.
That predates ES2022, so it could not parse the Map chunk Vite 7 emits, and every
PDF export rendered without its map while still returning 200 and a plausible file
size.

Changes:

- `package.json`: `^5.5.0` -> `^25.8.0` (Chrome 152). Lockfile shrinks by ~450
  lines; puppeteer 5's dependency tree was largely obsolete.
- `rasterize.js` + `rasterize_dev_mode.js`: `page.waitFor()` was renamed to
  `waitForTimeout` in puppeteer 10 and removed in 22 — replaced with a plain timer
  promise, which is version-proof.
- `rasterize_dev_mode.js` also hardcoded
  `node_modules/puppeteer/.local-chromium/linux-809590/chrome-linux/chrome`. That
  path stopped existing in puppeteer 19; removed so the resolver finds the browser.
- Both scripts now wait for `.maplibregl-canvas` when the page has a map host, and
  log `[rasterize] map canvas rendered` / a WARNING otherwise. A fixed 10s delay
  cannot tell "map drawn" from "map never loaded", which is precisely how this hid.
- `Dockerfile.deploy`: `PUPPETEER_CACHE_DIR=/app/.cache/puppeteer` in **both** the
  build and runtime stages. Puppeteer 19 moved the browser out of node_modules and
  into `$HOME/.cache/puppeteer`; the runtime stage only does
  `COPY --from=build /app /app`, so a browser under `/root/.cache` would be left
  behind and every PDF would fail with "Could not find Chrome". Verified the
  browser does land in that directory.
- The build assertion now **launches** the browser rather than just requiring the
  module, so a missing shared library fails the build instead of shipping.
- `bin/preflight-deploy` step 8 does the same check locally (~10s), so this is
  caught before a 15-minute deploy.

**Verified end to end on the staging host**, not just locally: a throwaway
container sharing the app's network namespace, with puppeteer 25 installed, ran the
real `rasterize.js` against the live PA page:

```
[rasterize] map canvas rendered
exit=0   pdf bytes: 372094
```

Under Chromium 88 the same page gave `mapCanvas: false`.

### 8s. Note on headless-browser evidence

Two separate false leads came from headless probes in this session, both worth
remembering:

1. **Chromium 88** (puppeteer 5) reported `SyntaxError: Unexpected token '{'`
   loading the Map chunk. That was the browser being nine years old, not a bug in
   the bundle. Always print `browser.version()` before trusting a probe.
2. **Chrome 152 headless on the staging host falls back to software WebGL**
   ("Automatic fallback to software WebGL has been deprecated") and shows an
   unrelated `ERR_SSL_PROTOCOL_ERROR`. It loads the style, sprites and TileJSON
   (all 200) but requests **zero vector tiles**. That is not sound evidence about a
   real GPU browser, so it must NOT be used to diagnose §8q.

The user's own browser remains the only reliable source for the map question.

### 8t. Deploy eb8b6abd6 FAILED — "Could not find Chrome" — defensive fix applied

The puppeteer-25 deploy failed at the build's own assertion:

```
ERROR: puppeteer cannot launch -- every PDF export would fail.
Could not find Chrome (ver. 152.0.7977.42). ... your cache path is
incorrectly configured (which is: /app/.cache/puppeteer).
```

**The assertion did its job** — it caught this instead of shipping an image whose
PDFs silently lose their map, which is exactly the failure it was written for.

**Root cause NOT reproduced.** The exact layer sequence was replayed on
`linux/amd64` (the CI platform) in a cut-down image — ubuntu 24.04 + node 24 +
corepack yarn 4.17.1 + the same ENV, `yarn install --immutable`, then
`yarn workspaces focus --production`:

```
AFTER-INSTALL:  /app/.cache/puppeteer/chrome/linux-152.0.7977.42
AFTER-PRUNE:    /app/.cache/puppeteer/chrome/linux-152.0.7977.42
```

So the browser DOES land in PUPPETEER_CACHE_DIR and DOES survive the prune. CI's
own log shows `puppeteer@npm:25.8.0 must be built` and no build failure. The most
plausible remaining explanation is that yarn's build step swallowed a failed
download on the self-hosted builder — but that is inference, not evidence.

**Fix: stop depending on the download having worked earlier in the build.** An
explicit `./node_modules/.bin/puppeteer browsers install chrome` now runs
immediately before the launch assertion. Verified on amd64: idempotent when the
browser is present, and it restores a deliberately wiped cache.

Its exit code is tolerated on purpose — the CLI returns **1 even on success**
(verified: it recovered a wiped cache and still exited 1). The launch assertion
stays the real gate, matching how the asset outputs are handled in the same RUN.

Also added `/.cache/` to `.gitignore` and `.cache/` to `.dockerignore`. The
puppeteer browser cache lives in the repo root by design (so the bind mount keeps
it between local runs) and is ~650MB; it was untracked but NOT ignored, i.e. one
`git add .` from being committed, and without the dockerignore rule a local
`docker build` would ship the host's browser over the image's own.
