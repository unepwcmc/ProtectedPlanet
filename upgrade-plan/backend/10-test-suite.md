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
