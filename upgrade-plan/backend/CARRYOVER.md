# Backend upgrade — carryover / deferred items

Running log of things intentionally **not** done yet, with **when** to pick each up.
Keep this current as phases land. Last updated: 2026-07-27 (end of Rails 6.1 phase,
before Ruby 2.7 → 3.3).

Status at this point: Rails 6.1.7.10, Zeitwerk, `load_defaults 6.1`,
`legacy_connection_handling = false`. Suite **648 runs, 0 failures, 7 skips**.
SimpleCov gate in CI (floor 54%, baseline ~55.6%).

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

- [ ] **WDPA geometry importer** — `lib/modules/wdpa/portal/importers/protected_area/geometry.rb` is **0% / 138 LOC**. Needs real PostGIS fixtures. Do **before GDAL ([13](./13-gdal-and-spatial-tooling.md)) + Postgres migration ([15](./12-infrastructure-migration.md))** — highest spatial-upgrade risk.
- [ ] **Table services** — `portal/services/core/{table_cleanup,table_swap,table_rollback}_service.rb` (~19–36%). Raw SQL DDL, PG-version fragile. Do **before the Postgres migration**.
- [ ] **Relation `create_models` path** — `portal/relation/*` incl. the nil-jurisdiction logic (`ProtectedArea#designation`). Ties to the `belongs_to` decision in §6.
- [ ] **shared importers** — `country_overseas_territories.rb` (9%), `story_map_link_list.rb` (10%), `protected_areas_related_source.rb` (15%).
- [ ] **ES-backed serializers** — `Search::{Areas,Full,Cms}Serializer` need a real `Search` object (ES). Only `FiltersSerializer` (structural) + `CountrySerializer`/`MapOverlaysSerializer` are covered so far.
- [ ] **Un-skip the 7 FDW integration tests** — they skip because the WDPA portal FDW schema isn't in the test DB (`release_orchestration_integration_test.rb`, `release_workflow_integration_test.rb`). Getting the portal FDW fixtures into test un-skips the core pipeline's integration layer.
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

## 5. Deploy / CI notes
- CI now runs **`bin/rails test`** (not `rake test`) so SimpleCov starts before app load (`Jenkinsfile` `rakeTest()`). Both run the same set (no `test/acceptance`). Don't revert to `rake test` without moving SimpleCov's start.
- Coverage is gated: `COVERAGE=1` fails the build below the floor.

## 6. Minor code items (low priority, clear opportunistically)
- [ ] **`belongs_to_required_by_default` opted out** (`config/application.rb`) — revisit as a data-integrity pass measured against a **production** dump. 4 associations have real NULLs: `Country#parent` (199/248), `Designation#jurisdiction` (57/1831), `pame_statistics.country`, `country_statistics.country`.
- [ ] **`_info.svg` orphan partial** — `app/views/partials/svgs/_info.svg` is not rendered via `render` (only an unrelated SCSS `info.svg` asset ref exists). Confirm unused, then remove. (`_pin.svg` was renamed to `_pin.html.erb` to clear the dotted-template deprecation — do the same or delete `_info.svg`.)
- [ ] **Mocha strict-keyword-argument warnings** (test-only) — surface during Ruby 3 prep; fix with the kwarg work.
- [ ] **`Searchable` constants inside `included do`** (`app/controllers/concerns/searchable.rb:22`) — re-initialized per including controller; cosmetic, no behaviour change.

## 7. Dead code found during the upgrade (already removed — for reference)
- `Search::ParallelIndexer` (dead + `require 'thwait'` unloadable on 2.7) — removed.
- `best_in_place` gem (unused; its railtie caused the ActionText/ActionView boot deprecations) — removed.
