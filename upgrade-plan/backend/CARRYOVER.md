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

## 2. Ruby 2.7 → 3.3 (the NEXT phase — known blockers already surfaced)
- [ ] **`::Data` namespace collision** — app has `Data::` (`app/controllers/data/`, `test/controllers/data/`); Ruby 3.2 introduced a built-in `Data` class. Rename the app namespace. First task of the phase.
- [ ] **Keyword-argument hard break** — general 2.7→3 work; the deprecation warnings are the map.
- [ ] gem-internal kwarg warning from `activerecord-postgis-adapter` (`postgresql_adapter.rb:883`) — may clear when the adapter bumps at Rails 7/8; recheck then.

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
