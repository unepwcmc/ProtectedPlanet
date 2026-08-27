# Dead code audit

Audit of unused / no-longer-reached code in the ProtectedPlanet Rails app.

- **Produced** 2026-08-21 on branch `staging_kamal`.
- **Wave 1 actioned 2026-08-27** — see the Suggested order section at the end for what was deleted and what remains.
- **Re-scanned and updated 2026-08-27**, same branch. Every finding below was re-verified against the working tree; entries that have since been actioned are marked **✅ DONE**, and three findings were **corrected** — see *What changed* below.

Findings are grouped by confidence:

- **[CONFIRMED]** — verified unreachable, or the code itself/an adjacent comment says so. Safe to delete after a normal review.
- **[SUSPECTED]** — strong evidence of being dead, but there is a live-looking reference or an environment-dependent trigger. Needs the one decisive check named in the entry before deleting.
- **[NOT DEAD]** — things that look dead to a naive scan but are not. Recorded so nobody deletes them.

Method: import-graph reachability for the frontend, a fixed-point call-graph pass for Ruby helper methods (so dead *clusters* are caught, not just leaves), and per-item manual verification. This codebase uses `send("...#{}...")` dispatch heavily, so every Ruby finding was checked against those patterns individually.

> **Note on `db/`** — `db/` is a **git submodule** (`unepwcmc/protectedplanet-db`, branch `backend/rails-upgrade`). Deletions under `db/` are commits to a separate repository and need to be coordinated with anything else consuming it. Note also that `db/schema.rb` and `db/structure.sql` are **listed in the submodule's `.gitignore`** — they are local artefacts, not committed files (see section 6).

---

## What changed between 2026-08-21 and 2026-08-27

**Actioned (deleted or fixed):**

| Item | Section | Commit |
|---|---|---|
| `app/assets/images/icons/` — all 40 files | 10 | `0bcf87a61` |
| 26 dead SVGs in `app/frontend/assets/icons/` (45 → 14 files) | 10 | `ff43f467a` |
| 38 of 39 unused `@utility` definitions; `shared/forms.css` deleted entirely | 10 | `da778205d`, `32461ad8a` |
| All 6 orphaned images, plus 17 more green-list/logo images found alongside them | 10 | `0bcf87a61`, `d1fc77c53` |
| The 2 dead `turbo_mount` registrations (`Tooltip`, `TooltipSecond`) | 10 | `24f9f4732` |
| `autocomplete_link`, `country_autocomplete_link`, `pa_autocomplete_link` | 10 | — |
| The stale `only: %i[show pdf]` in `country_controller.rb` | 10 | — |
| **`.github/workflows/test.yml` added** — the "no test CI at all" gap is closed | 8 | — |

Also removed in the same window, beyond this audit's scope: Pinia and its store, `app/helpers/frontend_helper.rb`, the Turbo Drive shims, `bin/docker-sidekiq-with-pdf-chrome`, the `aws-sdk` meta-gem (−220 gems), `levenshtein`, `httmultiparty`, `selenium-webdriver`, and the `es`/`fr` locales.

**Corrected on re-scan:**

1. **Section 6 was wrong about `structure.sql` and `schema.rb`.** Both are gitignored inside the `db` submodule. They are not "carried in every checkout"; they are whatever the reading developer's local database happens to contain. The July backup tables the original audit found are gone, and a *fresh* set from 2026-08-26 has taken their place — which reframes the finding entirely.
2. **Section 10's "28 unused TypeScript exports" does not hold up.** All 25 currently-unreferenced `backend.ts` types are used *inside* `backend.ts` as building blocks of live types; `BlobDownload`, `TurboMountLoader` and `trimText` are likewise used within their own modules. Nothing is dead — only the `export` keyword is redundant.
3. **Section 11's flag-SVG entry named the wrong call sites.** The lookup is now a single ISO3-based helper, and the directory is 247 files, not 274.

**Unchanged:** sections 1, 2, 3, 4, 5, 7, 9 and the Jenkins/Travis/Rakefile parts of 8 are all exactly as first recorded. Nothing in them has been deleted, and nothing has come back to life.

---

## 1. WDPA S3 release (legacy import path)

The pre-portal WDPA import: poll an S3 bucket for a new monthly WDPA GDB, download it, load it with OGR, build views, import.

**Chain:** `config/schedule.rb` (hourly cron) → `ImportWorkers::S3PollingWorker` → `ImportWorkers::MainWorker` → `Wdpa::Importer.import` → `Wdpa::Release.download` → `Wdpa::S3.download_latest_wdpa_to`

*Status 2026-08-27: unchanged, all files still present.*

### [CONFIRMED] It has been superseded

[lib/modules/wdpa/s3.rb](../lib/modules/wdpa/s3.rb) says so in its own code, inside `current_wdpa` (lines 51–52):

```ruby
# Here and this file is redundant because as we are now using protal release
object.key.include?("Oct2025")
```

The replacement is the portal release flow (`rake pp:portal:release[...]` in [lib/tasks/portal_release.rake](../lib/tasks/portal_release.rake), backed by `lib/modules/wdpa/portal/`). [lib/modules/download/config.rb](../lib/modules/download/config.rb) gates on `has_successful_portal_release?` in 10 places, and the legacy branch is the fallback arm every time — including line 122, the only remaining production call to `Wdpa::S3`:

```ruby
has_successful_portal_release? ? Release.current_label : Wdpa::S3.current_wdpa_identifier
```

Note the hardcoded `"Oct2025"` in `current_wdpa`: this method cannot select a release newer than October 2025. It is frozen, not maintained.

### [SUSPECTED] Whether the chain can still fire depends on how you deploy

The only trigger is [config/schedule.rb](../config/schedule.rb), which is still two lines long and still contains only this one job:

```ruby
every :hour, :roles => [:util] do
  runner 'S3PollingWorker.perform_async'
end
```

That is the `whenever` gem, installed via Capistrano. This repo currently has **both** deploy systems present:

| Deploy path | Installs `schedule.rb` cron? | Effect on the legacy chain |
|---|---|---|
| Capistrano (`Capfile`, `config/deploy/{staging,production}.rb`, Linode hosts) | Yes | Chain can still fire hourly |
| Kamal (`config/deploy.yml`, `config/deploy.staging.yml`, `.kamal/`, Proxmox host) | **No** — neither deploy file contains any cron/whenever/schedule wiring | Chain has no trigger |

**Decisive check before deleting:** confirm production no longer deploys via Capistrano. Once production is on Kamal, this entire chain is unreachable and can go. While production is still Capistrano-deployed, `S3PollingWorker` is live code on a live cron.

There is a second, independent reason it may already be inert: the known-broken sidekiq scheduler (`connection_pool 3`) means scheduled/retried jobs do not fire. That is a bug, though, not a decision — don't rely on it as the justification.

### Files in scope, once the above is resolved

| File | Notes |
|---|---|
| [lib/modules/wdpa/s3.rb](../lib/modules/wdpa/s3.rb) | Self-declared redundant; hardcoded to `Oct2025` |
| [lib/modules/wdpa/release.rb](../lib/modules/wdpa/release.rb) | `Wdpa::Release::DOWNLOADS_VIEW_NAME` (line 3) is still read by `download/config.rb:87` — extract that constant before deleting |
| [app/workers/import_workers/s3_polling_worker.rb](../app/workers/import_workers/s3_polling_worker.rb) | Cron entry point |
| [app/workers/import_workers/main_worker.rb](../app/workers/import_workers/main_worker.rb) | Only caller is `S3PollingWorker` |
| [config/schedule.rb](../config/schedule.rb) | Whole file is just this one job |

`Wdpa::S3.current_wdpa_identifier` is stubbed globally in [test/test_helper.rb:72](../test/test_helper.rb#L72), so removing it means updating that stub, `test/unit/workers/download_workers/search_test.rb`, and deleting `test/unit/workers/import_workers/s3_polling_worker_test.rb`.

---

## 2. `db/cms_seeds/*` — [CONFIRMED] dead cluster, 592 files / **334 MB**

*Status 2026-08-27: unchanged — still 592 tracked files, still 334 MB.*

The CMS seed dump and everything that reads it form one closed, dead loop. Nothing in the running app touches it.

Consumers, all three legacy:

1. **[lib/tasks/staging_seeds.rake](../lib/tasks/staging_seeds.rake)** — rsyncs seeds off staging over SSH. Hardcodes a host that is no longer the staging server (line 6):
   ```ruby
   PP_STAGING = 'new-web.pp-staging.linode.protectedplanet.net'.freeze
   ```
   Staging is now `pp-web-staging-01.internal.unep-wcmc.org` (see `config/deploy.staging.yml`). This task points at the retired Linode box.
2. **[lib/modules/sync_seeds.rb](../lib/modules/sync_seeds.rb)** — the SSH/rsync implementation. `staging_seeds.rake:49` is its **only** caller. (`config/initializers/comfy_patching.rb:14` mentions `sync_seeds` in a comment only.)
3. **[lib/tasks/export_to_s3.rake](../lib/tasks/export_to_s3.rake)** — reads `cms_seeds/protected-planet/files` to reconcile filenames during a one-time local-ActiveStorage → S3 migration.

`db/README.md` also states seed changes never affect the apps unless someone manually runs `comfy:cms_seeds:import`, and that this "should not be done on production".

Deleting the 334 MB is the single largest win in this audit. It lives in the `db` submodule — and unlike `structure.sql`, it genuinely *is* tracked there.

---

## 3. Rake tasks

*Status 2026-08-27: unchanged — every file below still present, every broken dependency still missing.*

### [CONFIRMED] Broken — depend on paths that no longer exist

| Task | Missing dependency |
|---|---|
| `db:lazy_seed` — [lib/tasks/db.rake](../lib/tasks/db.rake) | Reads `lib/data/seeds/pre_seeded_database.sql`, **which does not exist** (re-verified: the directory holds only CSVs). The task cannot succeed. |
| `cms_update_2:reattach_files` — [lib/tasks/reattach_files.rake](../lib/tasks/reattach_files.rake) | Reads `public/system/comfy/cms/files/files/000/000`, **which does not exist**. Paperclip is also no longer in the `Gemfile` — this was the one-time Paperclip → ActiveStorage migration. |

> `lib/tasks/db.rake` is not *only* dead weight — its `db:test:prepare` enhancement is what currently reddens CI. See the note in section 8.

### [CONFIRMED] Spent one-off data migrations

Each is a single-purpose data fix, run once, never touched since. Dates are last commit to the file, re-confirmed on 2026-08-27.

| File | Last touched |
|---|---|
| [lib/tasks/reattach_files.rake](../lib/tasks/reattach_files.rake) | 2020-01-07 |
| [lib/tasks/update_cms_tags.rake](../lib/tasks/update_cms_tags.rake) | 2020-01-09 — Comfy v1→v2 tag rewrite, namespace `cms_update_2` |
| [lib/tasks/fix_french_guiana_typo.rake](../lib/tasks/fix_french_guiana_typo.rake) | 2022-06-08 |
| [lib/tasks/rename_and_assign_chinese_territories.rake](../lib/tasks/rename_and_assign_chinese_territories.rake) | 2022-06-08 |
| [lib/tasks/rename_turkey_turkiye.rake](../lib/tasks/rename_turkey_turkiye.rake) | 2022-12-15 |
| [lib/tasks/country_changes_326_327.rake](../lib/tasks/country_changes_326_327.rake) | 2023-07-24 — `remove_gbr_iot_link`, `rename_countries`; named after a ticket/release pair |

### [CONFIRMED] Empty stub

`comfy:sync_staging_production` in [lib/tasks/export_to_s3.rake:73](../lib/tasks/export_to_s3.rake#L73) has no body — just a `TODO` comment. It does nothing when run.

### [SUSPECTED] `comfy:export_to_s3`

Same file, line 24. A one-time migration of local ActiveStorage blobs into the staging S3 bucket. Dead by intent, but unlike the tasks above it is not *broken* — it would still run. Delete alongside `db/cms_seeds` (section 2), since it is one of that directory's three consumers.

### [SUSPECTED] `comfy:staging_import`

[lib/tasks/staging_seeds.rake](../lib/tasks/staging_seeds.rake). Dead because its hardcoded Linode host is retired (section 2). Worth one check that nobody on the team still uses it to refresh a local CMS from a *current* host before removing.

### [NOT DEAD] `lib/tasks/portal_dev_tools.rake`

**Live developer tooling for the current importer**, not legacy. Its four tasks (`dev:import_only`, `dev:import_skip`, `dev:import_resume`, `dev:release_resume`) wrap the *portal* importer — the system that replaced the WDPA S3 path in section 1. Removing it would delete the resume/partial-import escape hatches for the import path you actually depend on.

Its tasks show 0 static references only because rake tasks are invoked from a shell, which is expected for every legitimate task. Recommend keeping.

---

## 4. `db/views/*` — [CONFIRMED] inert

*Status 2026-08-27: unchanged — all 8 files still tracked in the submodule.*

Eight `.sql` files under [db/views/](../db/views/). These are *not* managed by `scenic` — re-confirmed that the gem is not in the `Gemfile`. They are read by a local helper, `view_sql(timestamp, view)` in [config/initializers/migration_helpers.rb:2](../config/initializers/migration_helpers.rb#L2), and referenced only from 2019–2020 migrations.

Two reasons they can never execute in normal operation:

1. **`config.active_record.schema_format = :sql`** ([config/application.rb:61](../config/application.rb#L61) — the line moved from 55) — databases are built from `db/structure.sql`, so those 2019–2020 migrations are never replayed. The only way to reach these files is to manually roll back a six-year-old migration.
2. **Neither view exists in a current `structure.sql`.** Re-verified: zero occurrences of `regional_statistics_view` or `aichi11` anywhere in the generated file.

Per view:

| View | Files | Status |
|---|---|---|
| `aichi11_target_dashboard_view` | 3 | **Feature deleted.** [db/migrate/20260701120000_drop_aichi11_targets.rb](../db/migrate/20260701120000_drop_aichi11_targets.rb) drops the view and the `aichi11_targets` table, and there are zero `aichi11`/`Aichi` references left anywhere in `app/`, `lib/` or `config/`. |
| `regional_statistics_view` | 5 | View does not exist. See section 5 — its model is broken. |

Caveat: deleting these files makes those old migrations un-rollable. Given `schema_format = :sql` that is already effectively true, but if you want migration history to stay self-consistent, leave the files and just record them as inert.

---

## 5. [CONFIRMED] `Geospatial::Calculator` + `RegionalStatistic` — dead cluster

*Status 2026-08-27: unchanged — still exactly one commented-out reference.*

**`Geospatial::Calculator`** ([lib/modules/geospatial/calculator.rb](../lib/modules/geospatial/calculator.rb)) has exactly one non-test reference, and it is **commented out** — [app/workers/import_workers/finaliser_worker.rb:41](../app/workers/import_workers/finaliser_worker.rb#L41):

```ruby
# Here for historical reasons. Country stats are no more generated
# dynamically, but received by the PA programme every month.
# Geospatial::Calculator.calculate_statistics
```

The comment states the decision explicitly: stats now arrive as monthly CSVs from the PA programme.

**`RegionalStatistic`** ([app/models/regional_statistic.rb](../app/models/regional_statistic.rb)) sets `self.table_name = 'regional_statistics_view'` — a view that **does not exist**. Any query through this model raises. Its only non-test caller is `Geospatial::Calculator.clear_cache` (`calculator.rb:50`), which is itself dead. (The `regional_statistics` *table* does still exist; the model does not point at it.)

Dies with them:

- `lib/modules/geospatial/templates/{country,regional,global}_statistics_query.erb` — reached only via `"#{@level}_statistics_query.erb"` in `calculator.rb`, zero other references
- `lib/modules/geospatial/templates/base_calculation.erb` — referenced only from `calculator.rb:3`
- `test/unit/geospatial/calculator_test.rb`
- `test/models/regional_statistic_test.rb` *(missed by the first pass)*
- the 5 `db/views/regional_statistics_view/*.sql` files from section 4

**Keep the other four templates** in that directory — `repair_geometries.erb`, `marine_geometry.erb` and `dissolve_geometries.erb` belong to `geometry.rb` and `country_geometry_populator/`, which are separate (see section 7 for `CountryGeometryPopulator`'s own status).

Also note the already-commented-out stubs in [test/unit/workers/import_workers/finaliser_worker_test.rb](../test/unit/workers/import_workers/finaliser_worker_test.rb) lines 14 and 34, left behind by the same change.

---

## 6. [CORRECTED 2026-08-27] Leftover database objects — a *local database* problem, not a repo one

**The original entry got this wrong and the correction matters.** It described these as "committed schema … carried in every checkout". They are not committed at all:

```
$ cat db/.gitignore
schema.rb
structure.sql
```

Both files are **gitignored inside the `db` submodule**. Neither is tracked by the submodule or by the parent repo. What you read in `db/structure.sql` is a dump of whatever database the developer who last ran `db:migrate` happened to have — it is not shared state, and deleting objects from it is not a repo change.

That also explains an oddity the re-scan turned up. The 17 `bk2607161214_*` objects from the July release are **gone**, and in their place is a *newer* set:

| Leftover | Count (2026-08-27) | Origin |
|---|---|---|
| `bk2608261424_*` tables, views and matviews | 26 (17 tables, 9 materialized views, 1 view) + 40 associated indexes/sequences/constraints, 66 named objects in total | A release backup taken 2026-08-26 at 14:24 |
| `tmp_downloads_*` views | 3 (`1fc2ea74…`, `468f4336…`, `ca228602…`) | Download-generator temp views that outlived their requests |

So this is not release residue nobody cleaned up in July — it is the backup mechanism working as designed, plus temp views that leak on every download generation. The July set disappeared because that developer's database was rebuilt, not because anyone cleaned up.

**Revised finding:**

- `rake pp:portal:cleanup_backups[N]` still exists and is still the right tool, but it is a **per-environment housekeeping task** (run it on staging and production), not a repo cleanup.
- The leaking `tmp_downloads_*` views are the more interesting signal: the download generator creates them and something is not dropping them. Three of them accumulated in one developer's database. That is a **real, un-filed bug**, and it is the only item in this document that is arguably not about dead code at all.
- **[db/schema.rb](../db/schema.rb)** is stale and misleading to read — with `schema_format = :sql` it is never read or regenerated — but since it is gitignored, "deleting" it means deleting your own local copy. There is nothing to commit. Worth knowing so nobody reads it as authoritative.

Nothing in this section blocks or is blocked by anything else. It has been moved to the bottom of the suggested order accordingly.

---

## 7. The `import` Sidekiq queue — [CONFIRMED] no live producer

*Status 2026-08-27: unchanged in every particular.*

`config/sidekiq-import.yml` itself is **wired and live**: [config/deploy.staging.yml:57](../config/deploy.staging.yml#L57) runs a dedicated `job_import` Kamal role whose whole job is `bundle exec sidekiq -C config/sidekiq-import.yml`, serving the `import` queue at concurrency 25.

The problem is that **nothing can put a job on that queue any more.** Every producer is dead:

| Worker on `:import` | Enqueued by | Status |
|---|---|---|
| `ImportWorkers::MainWorker` | `S3PollingWorker` only | Dead with the cron chain (section 1) |
| `ImportWorkers::S3PollingWorker` | `config/schedule.rb` cron only | No cron under Kamal (section 1) |
| `ImportWorkers::GeometryPopulatorWorker` | `Wdpa::CountryGeometryPopulator.populate` | That class has **no non-test callers**, and [config/initializers/bystander.rb:26](../config/initializers/bystander.rb#L26) says: `# As of 19Aug2025 CountryGeometryPopulator is not used as stats are now from NC team` |
| `ImportWorkers::FinaliserWorker` | Its only enqueue site is **commented out** — [app/workers/import_workers/base.rb:18](../app/workers/import_workers/base.rb#L18) `# ImportWorkers::FinaliserWorker.perform_async`. (`Wdpa::Importer:11` sets `can_be_started = true`, but nothing ever acts on it beyond a `Bystander.log` line.) |
| `ImportWorkers::ProtectedAreasImporter` | **Nothing, anywhere** — zero references outside its own class definition, including tests |

The replacement portal release path enqueues nothing at all: `rake pp:portal:release` runs synchronously, and there is not a single `perform_async` in `lib/modules/wdpa/portal/` or `lib/tasks/portal_release.rake`.

So the `job_import` container starts, health-checks, and idles on a queue with no producers. Net effect: a permanently empty Sidekiq process on every deploy.

**Consequence:** `config/sidekiq-import.yml` is dead *by extension*, not on its own. It should be removed together with the `job_import` role in `config/deploy.staging.yml` and the `import_workers` tree — and only once section 1 is resolved, since `S3PollingWorker` is the piece whose liveness is still deploy-dependent.

Also dead, found here:

- **`ImportWorkers::ProtectedAreasImporter`** — ✅ **DONE (wave 1)**, deleted. It was the cleanest kill of the group; nothing referenced it and it had no test file.
- **`ImportWorkers::FinaliserWorker`** — never enqueued. (`test/unit/workers/import_workers/finaliser_worker_test.rb` goes with it.)
- [app/workers/import_workers/protected_areas_importer.rb:18](../app/workers/import_workers/protected_areas_importer.rb#L18) references `ImportWorkers::WikipediaSummaryWorker` in a comment — **a class that does not exist anywhere in the repo** (re-verified: that comment is its only occurrence).

---

## 8. CI and build files

### ✅ RESOLVED — the "no test CI" gap is closed

The original audit ended this section with a warning that `.github/workflows/` contained only the deploy workflow, so retiring Jenkins would leave the project with no test enforcement at all.

**That has been fixed.** [.github/workflows/test.yml](../.github/workflows/test.yml) now exists and runs on every PR and on pushes to `staging_kamal`/`master`/`develop`:

| Job | Steps | Gate status |
|---|---|---|
| **Ruby test suite** | Postgres 17 + PostGIS 3.5, Elasticsearch 8.6, Redis 7; builds the schema from all 204 migrations; `bundle exec rails test` | **Not a required check yet, deliberately** — the suite is red (18 failures / 10 errors at the time it landed) |
| **JavaScript test suite** | `yarn test` (vitest), `yarn lint --max-warnings 0`, `yarn lint:css`, `yarn typecheck` | All green; safe to make required |

Two things worth carrying forward:

- The workflow deliberately avoids `continue-on-error`, so the red suite reports honestly instead of showing a green tick over failures.
- The Ruby suite's redness has a **named cause**: `lib/tasks/db.rake` enhances `db:test:prepare` to run `db:seed`, so every test database is built with 248 seeded countries and fixtures then collide with them (`duplicate key value violates unique constraint countries_pkey`). That hook dates from 2019. Building from migrations instead removes ~59 errors. Fix the suite, then add the Ruby job to branch protection.

**What this does *not* cover:** the Jenkinsfile's **Snyk vulnerability scan** and the **SimpleCov coverage floor** (`COVERAGE=1`) have no replacement. If either mattered, port them before deleting the Jenkinsfile.

### ✅ DONE (wave 1) — The `Rakefile` acceptance-test block is dead

[Rakefile:9-13](../Rakefile#L9-L13), still present verbatim:

```ruby
Rake::TestTask.new("test:acceptance" => "test:prepare") do |t|
  t.pattern = "test/acceptance/**/*_test.rb"
end

Rake::Task["test:run"].enhance ["test:acceptance"]
```

Three independent reasons it does nothing:

1. **`test/acceptance/` does not exist.** Re-verified: the `test/` tree is `contracts, controllers, factories, fixtures, helpers, integration, mailers, models, presenters, services, unit`.
2. **The retired Jenkinsfile said so.** Its `rakeTest()` comment read: *"Both run the same set here (no test/acceptance)."*
3. **Nothing invokes `test:run`.** The `enhance` hook only fires on `rake test`. Jenkins used `bundle exec rails test`, and so does the new `test.yml` — neither reaches it.

The Rakefile has not been touched since 2019-03-15. Only these two statements are dead; keep the `require`s and `Rails.application.load_tasks`.

### ✅ DONE (wave 1) — `.travis.yml` — abandoned 2020

Still present. Last commit 2020-01-07. It provisions an environment that no longer resembles this app in any respect:

| `.travis.yml` | Actual |
|---|---|
| `rvm: 2.6.3` | Ruby 3.3.7 |
| `dist: trusty` (Ubuntu 14.04, EOL) | Debian/Ubuntu Docker images |
| `postgresql: 9.3`, `libgdal1` | PostGIS 17-3.5 / current GDAL |
| Elasticsearch 7.0.1 `.deb` | Containerised, 8.6 in CI |

Travis has not been in the loop for years, and the surviving CI is now the GitHub Actions deploy + test workflows.

> **Security note, not just cleanup:** this file still contains encrypted-but-live-looking credentials — a `notifications.slack.secure` token (line 50) and a `code_climate.repo_token` (line 59). Deleting the file does not invalidate them. Have them **revoked**, don't just remove the file. *(Re-checked 2026-08-27: both still present, so this has not been done.)*

### ✅ DONE (wave 1) — `Jenkinsfile` — Jenkins is no longer used

**Confirmed by the team (2026-08-21): Jenkins is retired.** The whole file goes, not just parts of it. Still present as of 2026-08-27.

The file's recency is misleading — last commit 2026-07-28, with comments referencing the Media Surfer asset work — so a scan reads it as live. It isn't; the pipeline it describes is no longer run.

Dies with it:

- **[Jenkinsfile](../Jenkinsfile)** — the entire pipeline: build, prepare, test, Snyk scan, Slack notifications to `#jenkins-cicd-pp`, docker cleanup.
- **`.env-jenkins-docker`** — read from exactly one place, `Jenkinsfile:136` (`cp .env-jenkins-docker .env`). Re-verified: nothing else in the repo touches it.

Two functions in it were already dead even while Jenkins ran, worth noting only because they show how long the Capistrano path had been unused: `deploy()` (`bundle exec cap staging deploy`, hardcoding `git checkout develop`) and `deleteDeployDir()` were defined but never called from any stage.

**Keep `docker-compose.yml`.** Jenkins used it (`COMPOSE_FILE`), but it is also the documented local development environment — see [docs/docker.md](docker.md), which is built around `docker compose up`, plus the `api` profile and the portal release runbook. It is not Jenkins-specific.

Two follow-ups this created, neither of which is dead code — ✅ **both actioned in wave 1**:

- [docs/docker.md:94](docker.md) referred to *"this project's Jenkins setup"* — clause removed.
- `upgrade-plan/backend/10-test-suite.md` and `00-scope-and-shared-milestones.md` describe Jenkins as the CI system and record fixing its Test stage as a milestone. They are historical planning records, so leaving them is defensible, but they no longer describe reality.

### [SUSPECTED] Stale comment in the deploy workflow

[.github/workflows/deploy-staging-kamal.yml:5-6](../.github/workflows/deploy-staging-kamal.yml#L5) still says *"The existing deploy.yml targets the old Linode staging via Kamal 1 and is left alone, so both run side by side until Linode is decommissioned"*, with a matching note at line 26. `.github/workflows/` contains only this workflow and `test.yml`; the Kamal 1 / Linode workflow it defers to is gone. Worth correcting while the Linode decommission is fresh.

---

## 9. `config/deploy` — [SUSPECTED] Capistrano is superseded

*Status 2026-08-27: unchanged.* Same open question as section 1: this is dead the moment production stops deploying via Capistrano, and not before.

| Path | Last commit | Notes |
|---|---|---|
| [config/deploy/staging.rb](../config/deploy/staging.rb) | 2021-01-29 | Targets `new-web.pp-staging.linode.protectedplanet.net` — the retired Linode box |
| [config/deploy/production.rb](../config/deploy/production.rb) | 2021-01-29 | Targets `new-web.pp-production.linode.protectedplanet.net` |
| [config/deploy/ansible/](../config/deploy/ansible/) | **2019-05-17** | A whole provisioning tree — `site.yml`, `user.yml`, `ansible.cfg`, `group_vars`, `host_vars`, inventories, and vendored roles. Untouched for seven years and superseded twice over, by Docker and then Kamal. |
| [config/deploy.rb](../config/deploy.rb) | 2025-11-21 | The only recently-touched piece |
| [Capfile](../Capfile) | 2025-03-06 | |

`config/deploy/ansible/` is the strongest candidate in this group — it provisions bare-metal Linode hosts that no longer exist, and predates the Docker migration entirely. It can reasonably go ahead of the rest.

Note the staging host here is the same retired Linode box hardcoded in `staging_seeds.rake` (section 2) — the same decommission covers both.

**Still-live references to Capistrano**, which must be updated in the same change:

- [docs/deployment.md](deployment.md) lines 8–9 — documents `cap staging deploy` / `cap production deploy` as *the* deploy procedure, under a heading that reads simply "## Capistrano". It also points at `config/deploy/ansible` as the way to provision new servers.
- [docs/docker.md](docker.md) lines 112, 117

(The `Jenkinsfile`'s `deploy()` function was the fourth, and goes with the file — section 8.)

`docs/deployment.md` documenting Capistrano while the repo deploys via Kamal is itself a live-documentation bug, independent of whether the code is deleted.

Retiring Capistrano would also let you drop 9 `capistrano-*` gems (Gemfile lines 82–90) plus `whenever` (line 157) — but see the note in section 11 about gem pruning needing its own pass.

---

## 10. Other confirmed dead code

### ✅ DONE since the original audit

| Item | Result |
|---|---|
| `app/assets/images/icons/` | **Deleted** — the whole directory is gone |
| 25 SVGs referenced only by dead CSS | **Deleted** — `app/frontend/assets/icons/` is down from 45 files to 14 |
| 39 unused `@utility` definitions | **38 of 39 deleted.** `shared/forms.css` was removed entirely; `icons.css` went from 45 utilities to 15. A fresh scan of all 196 remaining utilities found exactly **one** unused: `tw-shared-font-hind-siliguri__normal-base-grey-black` |
| 6 orphaned images | **Deleted**, along with 17 more found in the same sweep |
| 2 dead `turbo_mount` registrations | **Deleted.** The entrypoint now carries a comment explaining why `Tooltip`/`TooltipSecond` were never mountable islands |
| `autocomplete_link`, `country_autocomplete_link`, `pa_autocomplete_link` | **Deleted** from `search_helper` |
| `country_controller` `only: %i[show pdf]` | **Fixed** — now `only: %i[show]` |

### [CORRECTED] The "28 unused TypeScript exports" finding does not hold

Re-scanned properly. 25 of the 102 `export type`/`export interface` declarations in [app/frontend/types/backend.ts](../app/frontend/types/backend.ts) are never referenced from another file — but **every one of them is referenced inside `backend.ts` itself**, as a component of a type that *is* consumed (`ListingFilter` is used 3×, `AmChartPieDatum` 4×, and so on). They are building blocks, not orphans.

`BlobDownload`, `TurboMountLoader` and `trimText` are the same story: each is used within its own module (`http.ts:47`, `turboMount.ts:39`, `pameTableFormat.ts:12`).

**Nothing here is dead code.** The only defensible cleanup is dropping the redundant `export` keyword from module-internal types, which is a style call, not a deletion. Removed from the suggested order.

### ✅ DONE (wave 1) — whole file

**[app/presenters/cms_presenter.rb](../app/presenters/cms_presenter.rb)** — 49 lines, zero callers anywhere in `app`, `lib`, `config` or `test`, and already carries `TODO(backend): unused` explaining that the CMS versioning UI that fed it was removed.

### Still dead — methods (30 remaining, was 33)

All re-verified 2026-08-27 as having zero non-definition references anywhere in `app/`, `lib/` or `config/` — views included.

| Area | Count | Items | File |
|---|---|---|---|
| Helpers | 13 | `designation_link`, `facet_link` | `search_helper.rb` |
| | | `current_banner`, `get_square_side`, `is_regional_page` | `application_helper.rb` |
| | | `map_search_types`, `oecm_services_for_point_query`, `wdpa_services_for_point_query` | `map_helper.rb` |
| | | `has_pame_statistics_for`, `management_plan_document` | `protected_areas_helper.rb` |
| | | `has_restricted_sites` | `countries_helper.rb` |
| | | `has_documents` — dead **twice** | `regions_helper.rb` *and* `countries_helper.rb` |
| Presenters / services | 7 | `marine_page_statistics` (`country_presenter`), `get_designations` (`designations_presenter`), `marine_coverage` (`region_presenter`), `name_size` / `marine_designation` / `completeness_for` (`protected_area_presenter`), `import_completion` (`portal_release/notifier`) | |
| Models | 4 | `sum_of_most_protected_marine_areas` (`protected_area`), `sources_to_json` (`pame_evaluation`), `backup_timestamp_string` (`release`), `total_protected_marine_area` (`country_statistic`) | |
| `lib/` | 6 | `statistics_monthly_import` (`import_tools`), `country_tile` / `region_tile` (`asset_generator`), `configuration_for` (`search/aggregation`), `get_live_materialised_view_name_from_staging` (`portal/config/portal_import_config`), `attributes_for_green_list_status_create` (`portal/utils/green_list_column_mapper`) | |

### Still dead — controller

`search#map` ([app/controllers/search_controller.rb:42](../app/controllers/search_controller.rb#L42) — the line moved from 40) is `render :index` with no route, no view, and no reference anywhere.

### Still dead — CSS

One unused `@utility`: `tw-shared-font-hind-siliguri__normal-base-grey-black` in `app/frontend/styles/shared/typography.css`. Down from 39.

### Still dead — view

[app/views/partials/messages/_message-country-restricted.html.erb](../app/views/partials/messages/_message-country-restricted.html.erb) — unreferenced partial, re-confirmed.

---

## 11. [NOT DEAD] Do not delete these

Recorded because every one of them is flagged by a naive unused-code scan. Re-verified 2026-08-27.

| Thing | Why it looks dead | Why it is not |
|---|---|---|
| All **247** flag SVGs in `app/assets/images/flags/` *(count and mechanism corrected — the audit said 274 and named three call sites)* | No literal filename anywhere | Built at runtime from a single helper: `image_url("flags/#{iso_3}.svg")` in [app/helpers/application_helper.rb:49](../app/helpers/application_helper.rb#L49). Commit `9eb95ce1e` consolidated the lookup onto ISO3 filenames, which is why the earlier call sites no longer exist |
| `region_hash`, `country_hash`, `site_hash` | Never called by name | Reached via `send("#{geo_type}_hash", a)` at [app/serializers/search/areas_serializer.rb:49](../app/serializers/search/areas_serializer.rb#L49) |
| `lib/cms_tags/text_custom.rb` (`TextCustom`) | Class name appears nowhere else | Loaded by explicit `require Rails.root.join('lib/cms_tags/text_custom')` in `config/initializers/comfortable_media_surfer.rb:8`, so the class name never appears as a reference |
| `Tooltip/Index.vue`, `Tooltip/Panel.vue` | Their turbo-mount registrations were deleted | Live as child components of `Pame/Table/Head/Cell.vue` and `Stats/TooltipInfo.vue` — the registrations were the dead part, and they are already gone |
| `app/views/layouts/cms/_*.html.erb` (9 files) | `_data-areas` and `_thematic-and-data-area-default` have zero references in the repo | Comfy renders these by the `app_layout` value stored on each CMS layout **record in the database**. All nine also have a matching stylesheet imported from `tailwind.css`. Do not judge these statically — check `comfy_cms_layouts.app_layout` in a real database first |
| `app/views/comfy/admin/cms/partials/_navigation_inner.html.erb`, `_page_form_inner.html.erb` | Unreferenced | Comfy gem renders them by path convention |
| `@hotwired/stimulus`, `@types/node`, `vue-eslint-parser`, `vue-tsc` | No import statement | Stimulus is turbo-mount's runtime peer; the rest are type packages / the eslint parser / the `yarn typecheck` script — and as of `test.yml`, all three are now exercised in CI. *(`@vue/devtools-api` has left this list: it went with Pinia in `32461ad8a`.)* |
| `region#build_stats`, `country#build_stats` | Public methods with no route | Used as `before_action` callbacks |
| `ApplicationController` methods (`og_tags`, `set_locale`, `raise_404`, …) | No matching route | Callbacks and helper methods, not actions |
| `lib/tasks/portal_dev_tools.rake` | Zero static references | Live dev tooling for the current portal importer — see section 3 |
| `docker-compose.yml` | Was Jenkins's `COMPOSE_FILE`, and Jenkins is retired | Still the documented local dev environment (`docs/docker.md`, the `api` profile, the portal release runbook) — not Jenkins-specific |
| `config/sidekiq.yml` | — | Live: drives the `job_web`/`job` roles and the `pdf` capsule |
| `config/sidekiq-import.yml` | — | The file **is** wired into a running Kamal role. It is dead only because its queue has no producers — see section 7. Do not delete it in isolation; remove the role with it |
| The 25 module-internal types in `backend.ts` | No cross-file reference | Building blocks of live exported types — see the correction in section 10 |

> **A note on scanning Vue components:** a basename-matching scan reports ~118 of the ~120 SFCs as unreferenced. That is an artefact — components are imported by path (`@/components/Icon/Download.vue`) and registered under joined names, so the basename never appears as a standalone word. Do not run that scan.

**Not assessed:** the `Gemfile`. A gem-usage scan produced 35 hits that were nearly all false positives (constant-vs-gem-name mismatches like `comfortable_media_surfer` → `ComfortableMediaSurfer`, plus Capfile- and `database.yml`-level wiring). Treat gem pruning as a separate exercise with a proper tool. Note that three rounds of it have already happened since this audit (`16e8af033`, `0eaf9f884`, `54c707888`), so the low-hanging fruit is gone.

---

## Suggested order — executed in waves

Revised 2026-08-27. Work is being actioned wave by wave; each wave is one PR.

### ✅ Wave 1 — DONE (2026-08-27). Zero-risk: nothing here runs.

| Item | Section | Result |
|---|---|---|
| `.travis.yml` | 8 | Deleted. **The two encrypted tokens in it still need revoking — deleting the file does not invalidate them.** |
| `Rakefile` acceptance block | 8 | Deleted, along with the now-unused `require 'rake/testtask'`. `rake -T` verified clean, `test:acceptance` gone, `rake test` intact. |
| `Jenkinsfile` + `.env-jenkins-docker` | 8 | Deleted. See the porting note below. |
| `ImportWorkers::ProtectedAreasImporter` | 7 | Deleted. One file, no test file. |
| `CmsPresenter` | 10 | Deleted. |
| Stale Jenkins clause in `docs/docker.md:94` | 8 | Removed. |
| Stale future-tense Jenkins note in `.github/workflows/test.yml` | 8 | Corrected to past tense. |

Verified after the deletions: `rake -T` loads, `rake zeitwerk:check` reports *All is good!*

**Carried forward from the Jenkinsfile:**

- **SimpleCov did not need porting.** It lives in `test/test_helper.rb` and the `Gemfile`, both untouched; only the `COVERAGE=1` invocation went with Jenkins. Set `COVERAGE=1` on the Ruby job in `test.yml` whenever the suite is green enough for a floor to mean anything.
- **Snyk has no successor and now scans nothing.** It was a Jenkins-plugin step (`snykSecurity`, credential `wcmc-snyk`, org `informatics.wcmc`), so it stopped running when Jenkins was retired, not when the file was deleted. Porting it means a `snyk/actions` step plus a `SNYK_TOKEN` repo secret. **Open decision.**

### Wave 2 — straightforward, worth a review

1. **Broken and spent rake tasks** (section 3) — two of them cannot even run. While in `db.rake`, deal with the `db:test:prepare` seeding hook that is currently reddening CI (section 8).
2. **`Geospatial::Calculator` + `RegionalStatistic`** (section 5) — includes a model pointing at a nonexistent view.
3. **Dead helper/presenter/model/lib methods (30), `search#map`, the last unused `@utility`, the orphan partial** (section 10).

### Wave 3 — the big one, its own PR

4. **`db/cms_seeds/` + its 3 consumers** (section 2) — 334 MB, closed loop, nothing in the app reads it. Largest single win left. It is a commit to the `db` **submodule**, so it needs coordinating with anything else consuming that repo.

### Wave 4 — stale infrastructure

5. **`config/deploy/ansible/`** (section 9) — seven years stale, provisions hosts that no longer exist. Safe ahead of the rest of `config/deploy`.

### Wave 5 — blocked on one decision

6. **WDPA S3 release** (section 1), **the whole `import` queue + `sidekiq-import.yml` + the `job_import` role** (section 7), and **the rest of `config/deploy`** (section 9) — all three unblock together, the moment production is confirmed off Capistrano. Fix `docs/deployment.md` in the same change; it still documents `cap ... deploy` as the procedure.

### Not repo cleanup, but worth doing

7. **Database housekeeping** (section 6) — run `pp:portal:cleanup_backups` on the real environments, and **file the leaking `tmp_downloads_*` views as a bug**. Nothing to commit; `structure.sql` and `schema.rb` are gitignored.

Sections 1, 2, 5 and 7 touch import, CMS, stats and the worker fleet respectively, so each deserves its own PR rather than one sweeping cleanup commit.

## The one question that unblocks the most

**Does production still deploy via Capistrano?** A single answer settles sections 1, 7 and 9 — the WDPA S3 import chain, the entire `import` Sidekiq queue and its dedicated container, `config/deploy/*`, and 10 gems. Everything else in this document can be actioned without it.

*(The audit's second open question — "what replaces Jenkins as test CI?" — has been answered: `.github/workflows/test.yml`.)*
