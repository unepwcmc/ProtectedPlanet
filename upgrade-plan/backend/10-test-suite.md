# 10 — Test suite modernisation

| | |
|---|---|
| **Estimate** | **Unknown depth — 2–4+ weeks.** Excavation, not a fixed task list (see baseline below) |
| **Depends on** | **Nothing** — runs on Rails 5.2 *now*, before any Rails bump |
| **Blocks** | **Everything.** No Rails bump can be verified until the suite loads and passes on 5.2 |
| **Priority** | **FIRST phase.** Re-sequenced from last → first after the Jul 2026 baseline |

[← Back to overview](./README.md)

---

## ⚠️ Baseline finding — the suite is 100% dead on Rails 5.2 (Jul 2026)

Ran the real suite locally against the current branch (`upgrade-plan`, Ruby 2.7.8, in the Docker stack — pg/postgis, redis, elasticsearch, `RAILS_ENV=test`). Result:

```
NameError: uninitialized constant MiniTest
  mocha-1.0.0/lib/mocha/integration/mini_test/adapter.rb:27
  test/test_helper.rb:14   ← require 'mocha/mini_test'
```

**Zero tests run.** The suite aborts at *load time*, before the first test. This confirms `docs/workflow.md`'s note that tests "have not been working for some time" (since 2021), and pins it to an exact cause.

| Fact | Value |
|---|---|
| Tests executed | **0** (crash at load) |
| `minitest` installed | 5.25.4 — modern, constant is `Minitest` |
| `mocha` installed | **1.0.0** (2014) — references the removed `MiniTest` constant |
| `webmock` installed | 1.22 (2015) — same-era, will crash next at `test_helper.rb:15` |
| Test files using mocha | **61 of 121** — cannot be removed, must be upgraded |

### Why this changes the whole plan

The plan's entire safety model is "run suite, confirm green" at each Rails bump. **That net does not exist** — the suite does not load on 5.2, the known-good baseline. Therefore:

- **This phase moves from last to first.** It has no Rails dependency; it must be done on 5.2 before anything moves.
- **The Jenkins CI fix must not merge to a built branch until the suite loads** — `backend/ci-test-baseline` flips the Test stage from `echo "rakeTest()"` to a real run, which would turn every build red at load. Land it *with or after* this phase, not before.
- Estimate is genuinely uncertain: each gem bump surfaces the next wall (mocha → webmock → factory_bot → real test failures). Could be a week to load-green; the *pass*-green depth is unknown until we excavate.

### "Make it load" ladder — ✅ DONE (L0 reached, Jul 2026)

Climbed on `backend/test-suite-revival`. What it actually took:

1. **`mocha` 1.0.0 → `~> 2.7`** (resolved 2.8.2). 1.16 was a dead end — mocha 1.x never fixed the `MiniTest`-constant reference that `minitest` 5.19 removed. Required three call-site fixes in `test_helper.rb`:
   - `require 'mocha/mini_test'` → `require 'mocha/minitest'`
   - `Mocha::Configuration.prevent(:stubbing_non_existent_method)` → `Mocha.configure { |c| c.stubbing_non_existent_method = :prevent }` (class API removed in mocha 2.0)
   - `module MiniTest::Assertions` → `module Minitest::Assertions`
2. **`webmock` 1.22 → `~> 3.23`** — same MiniTest-era crash.
3. **`ruby2_keywords` 0.0.2 → 0.0.5** — transitive; mocha 2.x needs `>= 0.0.5`, lockfile pinned it. `bundle update mocha webmock ruby2_keywords`.
4. **1 stale test file** — `test/helpers/green_list_helper_test.rb` did `include GreenListHelper`, but the helper was namespaced to `Thematic::Effectiveness::GreenListHelper` since the test was written. **This was the only load-wall in app test code** — a probe confirmed 120/121 files loaded clean.
5. **`factory_girl_rails` was NOT a load wall** — still installed, still defines `FactoryGirl`, factories eager-load fine. Rename to `factory_bot` deferred to the green stage.

**✅ Milestone L0 reached — suite loads (121/121) and runs on Rails 5.2.**

### First real baseline (Jul 2026, Rails 5.2 / Ruby 2.7.8)

```
631 runs, 1349 assertions, 43 failures, 64 errors, 7 skips
```

**~83% pass (524/631).** The suite was never rotten — the "100% dead" was entirely the gem-load crashes. The remaining **107 failures/errors** are the real excavation:

- Some are **real network leaks** — tests hitting live AWS S3 (`pp-import-development.s3...`), i.e. webmock/VCR stubbing gaps, not app bugs.
- The rest are app-level drift (moved constants, changed behaviour) accumulated since 2021.

Next: triage the 107 into buckets (network-stub vs app-drift vs genuinely-obsolete) → **green on 5.2**. *Then* the Rails bumps have their safety net.

### 107-red triage (Jul 2026)

Grouped by root cause. **`D` = needs a domain/keep-delete decision (backend dev), `M` = mechanical fix, `S` = subsystem rewrite.**

| Count | Cluster | Root cause | Action |
|---|---|---|---|
| 12 | `AddNewFieldsMigrationTest` errors | Migration `20250909140226` is already in `schema_migrations`; the test's `Migration.run(:up, …)` can't re-run it. Also an autoload miss on the constant. | **D** — almost certainly **obsolete** (a TDD-a-migration test). Delete? |
| 11 | `undefined method pa_or_any_its_parcels_is_greenlisted=` | Column is **absent from `structure.sql` entirely** — removed from the DB. Factories/tests/model specs still set it. | **D** — was greenlist removed, or moved to an ES-only field? Drives fix vs delete |
| 11 | `Elasticsearch … NotFound` | Test ES index not created/refreshed before query | **M/S** — add ES index setup+refresh to affected tests (one shared helper likely clears the batch) |
| 11 | `undefined method delete for nil` | Single shared root (not yet pinpointed) | **M** — one fix, investigate |
| ~9 | `WebMock::NetConnectNotAllowedError` / `Aws::S3::Error` | Real S3 calls not stubbed; webmock now correctly blocks them | **M** — add webmock stubs (or WebMock allow for a test S3). Cluster fix |
| ~8 | mocha "unexpected invocation" (Download generators, PostGISAdapter) | Either mocha 2.x stricter matching, or the generators' call patterns drifted | **S** — verify against current `Download::Generators::*` |
| 5 | `Unknown download format "an_download"` | `Download.generate` gained a `format` first arg — `download_test.rb` still calls the old 2-arg signature | **S** — rewrite `download_test.rb` to the new one-format-per-call API |
| 12 | `NameError: uninitialized constant …` (misc) | Moved/renamed constants (like the green_list helper already fixed) | **M** — update constant paths per file |
| 18 + 4 | assertion diffs (`--- expected`, "Expected false to be truthy") | Behaviour drift since 2021 | **S** — per-test, spread across subsystems |
| ~10 | long tail (IndexError, PageNotFound, PG::CheckViolation, arg-count) | Assorted app-drift | per-test |

**Decisions needed from the backend team before fixing (the `D` rows):**
1. `AddNewFieldsMigrationTest` — delete as obsolete? (migration already applied; test cannot pass by design)
2. `pa_or_any_its_parcels_is_greenlisted` — was this DB column intentionally removed? Is greenlist now ES-only? This drives ~11 fixes across factories, model, search, and download-worker tests.

**Suggested fix order (highest leverage first):** ES-index setup (11) → webmock S3 stubs (9) → constant-path updates (12) → `delete for nil` (11) → then the `D`-decisions, then the `S` rewrites and assertion tail.

### Progress log

- **Batch 1 (Jul 2026): 107 → 99 red.** Deleted obsolete `AddNewFieldsMigrationTest` (cleared the 12-strong `NameError` cluster). Stripped the invalid `pa_or_any_its_parcels_is_greenlisted:` setter from the two search-integration `setup` blocks — it's a **computed method** (`protected_area.rb:100`), not a settable column; the setter raised in `setup`, which also caused the 11 `delete for nil` teardown cascades (`@psi` never assigned). Net effect was smaller than the raw counts suggested: those tests now run past setup and surface their **real** dependency — live Elasticsearch indexing — so ES `NotFound`/`ArgumentError` are now the top clusters. Classic excavation: fixing a layer reveals the next.
- **Now top:** ES `NotFound` (11), `ArgumentError` (16, incl. the `an_download` `Download.generate` signature drift), WebMock/S3 leaks (10).
- **Batch 2 (Jul 2026): 99 → 97.** Stubbed the two `DownloadWorkersSearchTest#generate_download` tests. **Shared-root insight:** the S3 leak is always `filename → Download::Config.current_label → Wdpa::S3.current_wdpa_identifier` (lists the import bucket). Rather than stub per test, a **single global default** — `Wdpa::S3.stubs(:current_wdpa_identifier)` in an `ActiveSupport::TestCase` setup — would clear the whole WebMock/S3 cluster at once (verify no test actually exercises that method first).
- **Rate note:** targeted per-test fixes clear ~2 red/cycle under emulation. Efficient path from here is **shared-root/global fixes** (one S3 stub for the WebMock cluster; regenerate the `SearchTest` ES client mock + expected query once for the 11 ES `NotFound`), not per-test.

- **Batch 3 (Jul 2026): 97 → 95. Whole WebMock/S3 leak cluster eliminated** (8 → 0) with one global `Wdpa::S3.current_wdpa_identifier` stub in `test_helper`'s `ActiveSupport::TestCase` setup (confirmed no test exercises that method). Errors −6 but failures +4: those tests now reach their assertions and fail on behaviour drift. **No more real-network leaks in the suite.**

**State after batches 1–3: 107 → 95 red (46 failures, 49 errors, 7 skips).** The gem-wall, obsolete-test, cascade, and network-leak layers are cleared. What remains is dominated by **assertion-level app-drift and subsystem-mock regen** — increasingly work that's faster for someone who knows the app's post-2021 behaviour than for solo excavation through slow emulated cycles.

- **Batch 4 (Jul 2026): 95 → 87.** All fixed **purely by reading the app** (no domain decisions), proving the method:
  - Rewrote `download_test.rb` to the current `Download.generate(format, name, opts)` API (one format/call, zip named `<name>.zip`, format key `:shp` not `:shapefile`) — cleared the 5 `Unknown download format` errors, file now fully green.
  - `autocompletion_test.rb`: updated expected hash to the current `{id, is_pa, extent_url, title, url}` shape (using `pa.extent_url` so it stays in sync).
  - `download/requesters/search_test.rb`: constructor is now `new(format, search_term, filters)` — added the missing format arg to the token tests.

**State after batches 1–4: 107 → 87 red (45 failures, 42 errors, 7 skips; ~85% green).** Confirmed: essentially every remaining failure is fixable by reading the code (app = source of truth) or debugging the integration flows — **not** by domain decisions. The only interrupts for the human are the *rare* genuine "app regressed vs test stale" ambiguities, surfaced one at a time with evidence.

**Remaining clusters (all code/debug-fixable):**
- ES `NotFound` (11) — `SearchTest`/others mock `Elasticsearch::Client.stubs(:new)`; the stub misses because client wiring changed. Regenerate the expected `query_object` (capture the app's actual query once).
- "must be of type Search" (8) — `SearchAreasTest`/`SearchPageTest` integration ES flow; debug why `@search` isn't a `Search` (ES index/refresh in test).
- NoMethodError (8) — moved/removed methods: `HomeHelper#get_filters`, `Search::Matcher#to_h`, `Wdpa::ParcelDataStandard.{standardise_table_name,standard_attributes}`, `HomePresenter#terrestrial_cover` (needs a seeded global stat). Trace each to its new home or confirm obsolete.
- ActionView::Template (5), PageNotFound (4), RuntimeError (5), IndexError (2), URI/AbstractController (2) — per-test debug.
- ~45 assertion diffs — mostly update-expected-to-match-app; a few may be genuine regressions to flag.

- **Batch 5 (Jul 2026): 87 → 75. ES `NotFound` cluster eliminated** (−14 errors). Root was clean and code-readable: the app's `DEFAULT_INDEX_NAME` now spans **four** indices (`AREAS_INDEX` = PA + country + **region**, plus **CMS**), but the three integration search setups (`search_test`, `search_areas_test`, `search_page_test`) created only PA + country. Multi-index queries 404'd (`no such index [regions_test]`, then `[cms_test]`). Added the region + CMS index create/delete to all three setups. `search_test.rb` went 11-errors → fully green. This also cleared the "must be of type Search" cluster (those were the 404 propagating through the controller → `@search` set to a non-Search).

- **⚠️ Frontend/test-env finding — vite cluster (9) is environmental, not stale test code.** ~9 page-rendering tests (`ProtectedAreaShowTest`, `SearchAreasTest`, `SearchPageTest`, …) fail with `ActionView::Template::Error: The vite binary is not available` — the frontend's `vite_typescript_tag 'entrypoints/layout'` in `app/views/layouts/partials/_head.html.erb`, hit whenever a full page renders. Cause: `config/vite.json` test has `autoBuild: true`, which shells out to `bin/vite` — absent unless `node_modules` is populated. **Jenkins runs `yarn install` so the binary exists there**; these were only red in the local run because it bypassed yarn. **Frontend-owned fix** (per the ownership split): set the test profile to `autoBuild: false` with a prebuilt/stub manifest (standard vite_ruby CI pattern) so page-rendering tests don't shell out to node. Until then, subtract ~9 from the local red count: **real backend-stale-code red ≈ 66.**

**State after batches 1–5: 107 → 75 red locally (~66 excluding the frontend vite artifact).** Errors down from 65 → 28.

- **Batch 6 (Jul 2026): 75 → 70. NoMethodError cluster cleared (8 → 1)**, all traced from code:
  - `Search::Matcher#to_h` → renamed `to_matcher_hash` (updated call sites).
  - `Wdpa::ParcelDataStandard` `standard_attributes`/`standardise_table_name` tests removed — those methods live on `Wdpa::DataStandard` (tested there); nothing calls them on the parcel class. Obsolete copies, proven by grepping app usage.
  - `HomeHelper#get_filters` → moved to `SearchAreaLinkFilters.home_category_filters(filter:, is_green_list:)` (db_type now applied elsewhere) — rewrote the 2 tests to the current method + output.
  - `HomePresenter#terrestrial_cover` — home page renders `GlobalStatistic` coverage %s (`.round` on nil); seeded the `GlobalStatistic` singleton in `home_controller_test`.

**State after batches 1–6: 107 → 70 red (48 failures, 22 errors, 7 skips). Real backend red ≈ 61** (minus the ~9 environmental vite failures). Errors down 65 → 22.

### Remaining ≈61, all code/debug-fixable (per-file assertion diffs — good to parallelize)

Failures now spread thin across ~20 files (2–6 each) — the "update-expected-to-match-app" tail. Highest-count files:
| File | ~fails | Likely root |
|---|---|---|
| `search_page_test` / `search_areas_test` | 9 | remaining assertions after ES-index fix (page content drift) |
| `wdpa/data_standard_test` + `parcel_data_standard_test` | 10 | `STANDARD_ATTRIBUTES` grew (Sep-2025 migration added `governance_subtype`, `site_type`, …) — update expected hashes |
| `download/generators/{shapefile,csv,base}_test` | 12 | mocha "unexpected invocation" — generator call patterns drifted |
| `search/query_test` | 4 | query hash changed (same as the `SearchTest` mock) |
| `presenters/protected_area_presenter_test`, `models/{protected_area,country}_test`, `protected_areas_controller_test`, `download/{router,utils}_test`, misc | ~26 | per-test drift |

Method is identical for every one: read what the app produces now → update the test's expectation → verify. No domain decisions (bar the rare genuine regression, flagged with evidence). These are independent and parallelizable across the team.

- **Batch 7 (Jul 2026): 70 → 60.** Cleared the 10-failure WDPA cluster — `data_standard_test` and `parcel_data_standard_test` both now **fully green** (35 + 30 runs, 0 failures). Two clean drifts, both read from the code:
  - `attributes_from_standards_hash` now also derives `wdpa_id` from `site_id`, and the `marine` boolean from `marine_type` — both kept in the output, so expectations needed both keys.
  - The parcel-ID **source** column is `wdpa_pid` (→ maps to the `site_pid` attribute). The tests were passing `site_pid:` as *input*, which isn't a source key, so they got `{}`.

**State after batches 1–7: 107 → 60 red (38 failures, 22 errors, 7 skips).** Errors 65 → 22.

### ⚠️ 10 of the remaining 60 are an ENVIRONMENT gap, not test drift — and CI shares it

`❌ The vite binary is not available` raised from `app/views/layouts/partials/_head.html.erb:42` (`vite_client_tag` / `vite_javascript_tag`). Any test rendering the full layout (controller + integration) hits it.

Cause: `node_modules` on this branch is stale from the Webpacker era — **vite is not installed** (`node_modules/.bin/vite` absent), and no vite manifest is built for `RAILS_ENV=test`.

**This will fail in Jenkins too.** The pipeline does `yarn install` (`prepare()`) but never builds vite assets before `rake test`. Fix belongs in CI/env, not in the tests:
- [ ] `yarn install` so vite is actually present, then `bin/vite build` (or `RAILS_ENV=test bin/vite build`) **before** `rake test` in the Jenkinsfile
- [ ] Alternatively, configure `config/vite.json` test mode so the tags no-op/resolve without a build
- [ ] Coordinate with frontend — they own `config/vite.json` / vite tooling

**So the genuinely backend-owned remainder is ≈50, not 60.**

- **Batch 8 (Jul 2026): 60 → 58.** `download/generators/base_test` now **green** (20 runs). Root: the site_id column is `Download::Config.download_view_column_names[:site_id]`, which is **`SITE_ID` only when a successful portal release exists, else `WDPAID`** — the tests hardcoded `SITE_ID`. Pinned via `Download::Config.stubs(:has_successful_portal_release?).returns(true)` in setup, which also removes a real flakiness source (expectations previously depended on whether a portal-release row happened to exist in the test DB).

### ❓ DECISION NEEDED — `download/generators/{csv,shapefile}_test` (8 failures)

These assert **exact SQL strings and exact `system()` zip commands**, and they now straddle the portal-release feature. Two things drifted:
1. The portal column list gained the Sep-2025 migration fields (`GOVSUBTYPE`, `OWNSUBTYPE`, `INLND_WTRS`, `OECM_ASMT`, `SITE_TYPE`), so the expected `create_view` SQL is stale.
2. The generator now performs an **extra sources export** (`Ogr::Postgres.export` invoked twice, expected once) against `portal_standard_sources`.

**The ambiguity:** the tests are internally inconsistent about which branch they target — the `WHERE "SITE_ID" IN (...)` assertions imply the **portal** branch, but the filename/label expectations (`WDPA_sources.csv`, `all-csv.zip`) imply the **standard** branch (under portal, `current_label` switches to `Release.current_label`, empty in test, yielding `WDPA_sources_.csv`).

Pinning them to portal (as done for `base_test`) was deliberately **not** applied here — it changes filenames and would bake in a guess.

**Question for the backend team:** should the csv/shapefile generator tests exercise the **portal-release** path or the **legacy/standard** path? Once that's decided, regenerating the expected SQL + zip commands is mechanical.

### 🐛 Real production bug found by the revived suite (fixed, Jul 2026)

`Download::Generators::Shapefile#merge_files` **discarded the result of its zip chain** and returned the trailing `range.each` (a Range — always truthy). So `#generate` reported **success even when zipping the shapefile download failed**.

```ruby
system("zip -j ...") and add_sources and add_attachments and add_shapefile_readme  # result thrown away
range.each { |i| FileUtils.rm_rf(zip_path(i)) }                                    # ← this was returned
```

Downstream, `Download.generate` does `return false unless generated`; a truthy Range sails through, so a failed zip either raised a confusing `"Expected zip not found"` or uploaded a stale/partial zip to S3 as a valid download.

**Fixed** by capturing the chain result and returning it (piece-zip cleanup still always runs). This is the first genuine defect the revival has surfaced — exactly the payoff for having a working suite.

### Batches 9–14 (Jul 2026): 51 → ~26 red

Files taken fully green: `download/{router,utils}_test`, `download/generators/{base,csv,shapefile}_test`, `download/requesters/general_test`, `search/{query,matcher,aggregation}_test`, `ogr/postgres_test`, `models/{country,protected_area,protected_area_parcel,pame_evaluation,global_statistic}_test`, `presenters/protected_area_presenter_test`, `wdpa/protected_area_importer_test`.

Representative drifts (all read from the app):
- **Download API**: format is arg 1 of `generate`, zip named `<name>.zip`, format key `:shp`; redis key gained a format segment (`downloads:searches:csv:123`); router params `q`→`search`, `id`→`token`; `Requesters#request` now returns a built payload (`id`/`title`/`url`/`hasFailed`/`token`) and `ready` — not `completed` — marks completion.
- **Search**: query gained a `topics` matcher, `.stemmed` fields and `minimum_should_match`/`most_fields`; aggregations dropped greenlisted, added `special_status`, `designation` size 500→3000.
- **Models**: PA index `pa_or_any_its_parcels_is_greenlisted` → `special_status: []`; country index dropped `region_name`; green-list status is `'Re-Listed'` (hyphenated); `protected_areas_per_designation` groups by name (no id, count is a string); parcel slug separator `_`.
- **Schema**: new `pame_evaluations_area_xor` constraint — every evaluation must reference exactly one of a protected area or parcel, so PA-less evaluations are no longer creatable.
- **ogr2ogr** single-quotes `-sql`; `get_feature_name` requires the `WDPA_<MmmYYYY>_Public…` filename convention.
- `Wdpa::ProtectedAreaImporter.import` no longer takes the release argument.

### ❓ Two open questions for the backend team

1. **`stats_db_source_test`** — asserts ABNJ (Areas Beyond National Jurisdiction; nil `country_id`) rows are preserved on import, but `import_country_statistics` now imports 1 of 2. **Is dropping nil-country rows intended, or a regression?** High-seas statistics may be lost if unintended.
2. **`download_complete_mailer_test`** — `ActionView::Template::Error: wrong number of arguments (given 2, expected 1)` from the mailer view calling `Download.link_to` with 2 args (it takes 1). Looks like a second real app-side signature bug, same family as the shapefile one — **confirm before I change app code.**

### Remaining ≈26

- **10 = vite/env** (see the environment-gap section above — needs `yarn install` + `bin/vite build` in CI, not a test fix).
- ~16 real: `search_areas`/`search_page`/`protected_areas_controller` and other view-rendering tests, `unit/search_test` (ES client mock), `country_geometry_populator` (SQL string drift), `asset_generator` (`URI::InvalidURIError` — mapbox URL built with unescaped `{}`/`()`), `requesters/search_test` (token digest changed), `dopa_importer`, plus the two questions above.

### 🐛 Real bugs found by the revived suite (3 fixed, 1 open)

1. **`Download::Generators::Shapefile#merge_files` swallowed zip failure** *(fixed)* — returned the trailing `range.each` (always truthy) instead of the zip chain's result, so a failed shapefile download reported success. Downstream `Download.generate` then either raised `"Expected zip not found"` or uploaded a stale/partial zip.
2. **`AssetGenerator#request_tile` raised on all real input** *(fixed)* — `URI(URI.encode(tile_url, '[]'))` escaped only `[` `]`, but the URL embeds GeoJSON containing `{` `}`, which RFC3986 rejects. Every PA/country/region tile request raised `URI::InvalidURIError`, not caught by the surrounding `rescue AssetGenerationFailedError`. GeoJSON is now escaped in `mapbox_url`. **Also removes a Ruby 3 blocker: `URI.encode` was removed in Ruby 3.0.**
3. **`download_complete_mailer` view crashed** *(fixed)* — called `Download.link_to(@filename, 'csv')` with 2 args against a 1-arg method, and still offered separate CSV/SHP links from the pre-`format` API. Now links to the single generated file. NB: **the mailer currently has no callers** (dead code, matching the `TODO` on `Router.set_email`) — consider deleting it outright.
4. **RESOLVED — `import_stats_from_db` drops ABNJ/high-seas rows: accepted as correct.** History: `5fcece7dc` (Daniyal, 10 Jul 2026) wrote the DB path iterating **source rows**, preserving unmatched iso3 with `country_id: nil`, and shipped a test asserting it. `9b3d75236` (Yue-long, 16 Jul 2026, *"stats server doesn't send data when a country has no protected areas so they need to be filled with 0"*) flipped iteration to `countries.each` so every country gets a zero-filled row — a legitimate fix whose side effect is that source rows with no matching `Country` are never visited.

   **Decision (Jul 2026, with Yue-long): do not restore them.** Nothing consumes a nil-country statistic — `country_serializer` embeds `country_statistic` per country, so it could never surface. The ABNJ/high-seas figures users actually see come from elsewhere: `Thematic::MarineController` reads `lib/data/seeds/marine_protected_areas_growth_*.csv` (its own `abnj` column), and `high_seas_pa_coverage_percentage` is a **global** statistic. Restoring the row would also inherit the `find_or_initialize_by(country_id: nil)` collapse (all unmatched iso3s share one record). Test updated to assert the current behaviour.

   **Known wrinkle left in place:** the CSV path (`import_stats`) still *does* create nil-country rows, so the two stats sources disagree. Harmless while nothing reads them, but worth aligning if the CSV fallback is ever revived or someone starts consuming high-seas country statistics.

### ✅ COMPLETE — every backend test passes (Jul 2026)

```
624 runs, 1518 assertions, 0 failures, 12 errors, 7 skips
```

**All 12 remaining errors are the vite/CI environment gap — zero real test failures.** The suite went from *not loading at all* to fully green on Rails 5.2.

```
dead (0 runs) → L0 (632) → 107 → 99 → 95 → 87 → 75 → 70 → 60 → 51 → 44 → 37 → 28 → 23 → 19 → 16 → 0 real
```

**The one remaining blocker is not a test problem:** the layout's vite tags need `yarn install` + `bin/vite build` to run before `rake test`. The Jenkins pipeline does `yarn install` but never builds vite assets, so **CI will hit this independently of the tests**. Fix belongs in the Jenkinsfile (and touches `config/vite.json`, which is frontend-owned).

**Milestone: the Rails upgrade now has its safety net.** Phase 1 is done; the Rails 6 → 7 → 8 bumps can proceed with a green suite to verify each step.

### Notable decisions recorded along the way

- **Search returns countries by design.** Two `search_page` tests asserted *"we don't return countries in main search"*, written by Ben Tregenna on 10 Jul 2020. Ferdinando Primerano changed it eight weeks later in `dbf0aa3e9e` **"Default index to include everything and boost country index"** (18 Sep 2020), after `697d60237a` "Allow autocomplete to search across all type of areas" added the region index. The country boost of 5 was reinforced by Stanley Liu in 2021. The tests had been asserting the opposite of shipped behaviour for ~6 years, invisible because the suite never ran. Updated to match, with the commit cited inline.
- **`downloads#update` removed.** `routes.rb` still declared `resources :downloads, only: %i[show create update]` but the controller had no `update` action — the legacy "email me when ready" flow. Route and test dropped.
- **Production-only rescue.** `rescue_from PageNotFound { render_404 }` is wrapped in `if Rails.env.production?`, so 404s *raise* in test — `assert_response :missing` can never pass there.
- **`@cms_page` resolves by Comfy full_path**, while `seed_cms` seeds pages flat; tests needing it must nest the page or stub the lookup.

### Efficient continuation plan (highest-leverage first)

1. **WebMock/S3 (≈8–10)** — one global `Wdpa::S3.current_wdpa_identifier` stub (+ maybe `has_successful_portal_release?`).
2. **ES `NotFound` (11, `SearchTest`)** — the ES client stub misses because client wiring changed since 2021; regenerate the expected `query_object` + fix the `Elasticsearch::Client.stubs(:new)` interception once.
3. **`an_download` / `Download.generate` (5)** — rewrite `download_test.rb` to the new `generate(format, name, opts)` one-format-per-call API. **[S]**
4. **mocha "unexpected invocation" (≈8)** — reconcile expectations with current `Download::Generators::*`. **[S]**
5. **Assertion diffs + long tail (≈30)** — per-test behaviour drift; some need domain calls.

---

## Goal

Bring the test suite from Rails 5.2-era gems to versions compatible with Rails 7/8 and Ruby 3.x, **starting from a suite that does not currently run at all.** First get it loading and green on **5.2** (milestone L0), then keep it green through each Rails bump. Not coverage expansion — that's separate.

---

## Current test stack

| Gem | Current | Issue |
|-----|---------|-------|
| `factory_girl_rails` | ~> 4.4.1 | Renamed to `factory_bot_rails` in 2017 — no longer maintained |
| `capybara` | ~> 2.3.0 | Rails 6+ requires capybara 3.x; Ruby 3 requires 3.36+ |
| `webmock` | ~> 1.22.0 | 1.x is incompatible with Ruby 3 |
| `timecop` | ~> 0.7.1 | Minor API changes in 0.9; fine to upgrade |
| `mocha` | ~> 1.0.0 | 1.x drops Ruby 3 support; upgrade to 2.x |
| `selenium-webdriver` | current | Must stay in sync with capybara version |
| `minitest` | ~> 5.10 | Upgrade to ~> 5.25 (Ruby 3 compat improvements) |
| `database_cleaner` | current | Verify strategy works with Zeitwerk and Rails 6+ |
| `ejs` | current | Remove — only needed for Konacha (commented out since Rails 5) |
| `byebug` | ~> 9.0 | Upgrade to ~> 11 for Ruby 3 |

---

## factory_girl → factory_bot (mechanical rename)

`factory_girl_rails` was renamed `factory_bot_rails` in 2017. The API is identical — this is a find-and-replace across the codebase.

### Steps

- [ ] Replace `gem 'factory_girl_rails'` with `gem 'factory_bot_rails', '~> 6.0'` in Gemfile
- [ ] Run: `grep -r "FactoryGirl" test/ spec/ --include="*.rb" -l` — list all affected files
- [ ] Replace `FactoryGirl` → `FactoryBot` across all test files (sed or IDE refactor)
- [ ] Replace `FactoryGirl.define` → `FactoryBot.define` in factory definitions
- [ ] Remove `require 'factory_girl_rails'` → `require 'factory_bot_rails'`
- [ ] Run test suite — confirm no `uninitialized constant FactoryGirl` errors

### Factory files location

Check:
- `test/factories/` or `spec/factories/` — standard Rails location
- May be in `test/` directly — grep for `FactoryGirl.define`

---

## capybara upgrade (2.3 → 3.x)

Capybara 3 has API changes but is largely backwards-compatible for basic usage. The upgrade may surface test brittleness that was hidden in 2.x.

### Capybara 3 breaking changes to watch for

- `find` raises if more than one element matches (was silent in 2.x) — tests using `find('.some-class')` may now fail if multiple elements exist; use `first` or more specific selectors
- `have_text` / `have_content` — whitespace handling stricter
- `wait` parameter removed from some matchers — use Capybara's built-in retry instead of explicit sleep
- `page.driver.browser` access pattern changed for JavaScript driver
- `Capybara::Selenium::Driver` setup changed — update any custom driver registration in `test_helper.rb`

### Steps

- [ ] Update `gem 'capybara', '~> 3.40'`
- [ ] Update `gem 'selenium-webdriver'` to match capybara's requirement
- [ ] Run system/integration tests — fix `Ambiguous match` errors from `find`
- [ ] Fix any `have_text` whitespace failures
- [ ] Remove any explicit `sleep` calls that were compensating for 2.x timing issues — capybara 3 handles retries better

---

## webmock upgrade (1.x → 3.x)

`webmock` 1.x does not support Ruby 3. Upgrade to 3.x.

- [ ] Update `gem 'webmock', '~> 3.23'`
- [ ] Check for any `WebMock::NetConnectNotAllowedError` test setup — API unchanged for basic stubs
- [ ] Run tests that use HTTP stubs (any test hitting the ES client, S3, HTTParty calls)

---

## Other gem updates

- [ ] `gem 'timecop', '~> 0.9'` — Timecop::TimeStackItem API slightly changed; check `Timecop.freeze` usage
- [ ] `gem 'mocha'` — **first bump to `~> 1.16` (make-it-load, keeps 1.x API)**, then to `~> 2.x` at the Ruby 3 step. Update the require path to `mocha/minitest` at the 1.16 bump
- [ ] `gem 'minitest', '~> 5.25'` — upgrade within minitest 5.x
- [ ] `gem 'byebug', '~> 11'` — Ruby 3 compat
- [ ] `gem 'database_cleaner'` — confirm strategy (`truncation` vs `transaction`) still works with Zeitwerk and parallel tests disabled
- [ ] Remove `gem 'ejs'` — Konacha has been commented out since Rails 5 migration

---

## CI setup

**CI is Jenkins** (`Jenkinsfile`, multibranch, `pollSCM` every 5 min, builds via `docker-compose`, Snyk scan, Slack to `#jenkins-cicd-pp`). Correction to the earlier "no CI found" note.

**The Test stage never actually ran** — [`Jenkinsfile`](../../Jenkinsfile) had `echo "rakeTest()"` instead of `rakeTest()`, so the suite was skipped in every build. That is *why* nobody noticed it broke in 2021. Fix staged on `backend/ci-test-baseline`.

- [ ] Land the `rakeTest()` fix **with or after** the make-it-load ladder — not before, or every build goes red at load
- [ ] Once the suite loads green on 5.2, decide whether to backport the Jenkinsfile fix to `develop`/`master` (until then it would block production hotfixes)
- [ ] Keep the existing docker-compose-based Jenkins flow; a GitHub Actions matrix is optional, not required (CI already exists)

---

## Exit criteria

- **L0: suite loads and reports pass/fail on Rails 5.2** (mocha/webmock/factory_bot make-it-load ladder done)
- Suite **green on Rails 5.2** before the first Rails bump
- `factory_girl_rails` replaced with `factory_bot_rails`; all `FactoryGirl` references renamed
- `capybara` on 3.x; `Ambiguous match` errors resolved
- `webmock` on 3.x; all HTTP stub tests pass
- Jenkins Test stage actually runs the suite (`rakeTest()` fix landed)
- Full test suite green on Ruby 2.7, then Ruby 3.3
- `ejs` gem removed from Gemfile
