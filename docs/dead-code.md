# Dead code audit

Audit of unused / no-longer-reached code in the ProtectedPlanet Rails app, produced 2026-08-21 on branch `staging_kamal`.

Nothing in this document has been deleted. It is a record of what was found, what evidence supports each finding, and what still needs a human decision.

Findings are grouped by confidence:

- **[CONFIRMED]** — verified unreachable, or the code itself/an adjacent comment says so. Safe to delete after a normal review.
- **[SUSPECTED]** — strong evidence of being dead, but there is a live-looking reference or an environment-dependent trigger. Needs the one decisive check named in the entry before deleting.
- **[NOT DEAD]** — things that look dead to a naive scan but are not. Recorded so nobody deletes them.

Method: import-graph reachability for the frontend, a fixed-point call-graph pass for Ruby helper methods (so dead *clusters* are caught, not just leaves), and per-item manual verification. This codebase uses `send("...#{}...")` dispatch heavily, so every Ruby finding was checked against those patterns individually.

> **Note on `db/`** — `db/` is a **git submodule** (`submodule.db.path db`). Deletions under `db/` are commits to a separate repository and need to be coordinated with anything else consuming it.

---

## 1. WDPA S3 release (legacy import path)

The pre-portal WDPA import: poll an S3 bucket for a new monthly WDPA GDB, download it, load it with OGR, build views, import.

**Chain:** `config/schedule.rb` (hourly cron) → `ImportWorkers::S3PollingWorker` → `ImportWorkers::MainWorker` → `Wdpa::Importer.import` → `Wdpa::Release.download` → `Wdpa::S3.download_latest_wdpa_to`

### [CONFIRMED] It has been superseded

[lib/modules/wdpa/s3.rb](../lib/modules/wdpa/s3.rb) says so in its own code, inside `current_wdpa`:

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

The only trigger is [config/schedule.rb](../config/schedule.rb):

```ruby
every :hour, :roles => [:util] do
  runner 'S3PollingWorker.perform_async'
end
```

That is the `whenever` gem, installed via Capistrano. This repo currently has **both** deploy systems present:

| Deploy path | Installs `schedule.rb` cron? | Effect on the legacy chain |
|---|---|---|
| Capistrano (`Capfile`, `config/deploy/{staging,production}.rb`, Linode hosts) | Yes | Chain can still fire hourly |
| Kamal (`config/deploy.yml`, `.kamal/`, Proxmox host) | **No** — `deploy.yml` contains no cron/whenever/schedule wiring at all | Chain has no trigger |

**Decisive check before deleting:** confirm production no longer deploys via Capistrano. Once production is on Kamal, this entire chain is unreachable and can go. While production is still Capistrano-deployed, `S3PollingWorker` is live code on a live cron.

There is a second, independent reason it may already be inert: the known-broken sidekiq scheduler (`connection_pool 3`) means scheduled/retried jobs do not fire. That is a bug, though, not a decision — don't rely on it as the justification.

### Files in scope, once the above is resolved

| File | Notes |
|---|---|
| [lib/modules/wdpa/s3.rb](../lib/modules/wdpa/s3.rb) | Self-declared redundant; hardcoded to `Oct2025` |
| [lib/modules/wdpa/release.rb](../lib/modules/wdpa/release.rb) | `Wdpa::Release::DOWNLOADS_VIEW_NAME` is still read by `download/config.rb:87` — extract that constant before deleting |
| [app/workers/import_workers/s3_polling_worker.rb](../app/workers/import_workers/s3_polling_worker.rb) | Cron entry point |
| [app/workers/import_workers/main_worker.rb](../app/workers/import_workers/main_worker.rb) | Only caller is `S3PollingWorker` |
| [config/schedule.rb](../config/schedule.rb) | Whole file is just this one job |

`Wdpa::S3.current_wdpa_identifier` is stubbed globally in [test/test_helper.rb:72](../test/test_helper.rb#L72), so removing it means updating that stub and `test/unit/workers/download_workers/search_test.rb`.

---

## 2. `db/cms_seeds/*` — [CONFIRMED] dead cluster, 592 files / **334 MB**

The CMS seed dump and everything that reads it form one closed, dead loop. Nothing in the running app touches it.

Consumers, all three legacy:

1. **[lib/tasks/staging_seeds.rake](../lib/tasks/staging_seeds.rake)** — rsyncs seeds off staging over SSH. Hardcodes a host that is no longer the staging server:
   ```ruby
   PP_STAGING = 'new-web.pp-staging.linode.protectedplanet.net'
   ```
   Staging is now `pp-web-staging-01.internal.unep-wcmc.org` (see `config/deploy.yml`). This task points at the retired Linode box.
2. **[lib/modules/sync_seeds.rb](../lib/modules/sync_seeds.rb)** — the SSH/rsync implementation. `staging_seeds.rake` is its **only** caller.
3. **[lib/tasks/export_to_s3.rake](../lib/tasks/export_to_s3.rake)** — reads `cms_seeds/protected-planet/files` to reconcile filenames during a one-time local-ActiveStorage → S3 migration.

`db/README.md` also states seed changes never affect the apps unless someone manually runs `comfy:cms_seeds:import`, and that this "should not be done on production".

Deleting the 334 MB is the single largest win in this audit. It lives in the `db` submodule.

---

## 3. Rake tasks

### [CONFIRMED] Broken — depend on paths that no longer exist

| Task | Missing dependency |
|---|---|
| `db:lazy_seed` — [lib/tasks/db.rake](../lib/tasks/db.rake) | Reads `lib/data/seeds/pre_seeded_database.sql`, **which does not exist**. The task cannot succeed. |
| `cms_update_2:reattach_files` — [lib/tasks/reattach_files.rake](../lib/tasks/reattach_files.rake) | Reads `public/system/comfy/cms/files/files/000/000`, **which does not exist**. Paperclip is also no longer in the `Gemfile` — this was the one-time Paperclip → ActiveStorage migration. |

### [CONFIRMED] Spent one-off data migrations

Each is a single-purpose data fix, run once, never touched since. Dates are last commit to the file.

| File | Last touched |
|---|---|
| [lib/tasks/reattach_files.rake](../lib/tasks/reattach_files.rake) | 2020-01-07 |
| [lib/tasks/update_cms_tags.rake](../lib/tasks/update_cms_tags.rake) | 2020-01-09 — Comfy v1→v2 tag rewrite, namespace `cms_update_2` |
| [lib/tasks/fix_french_guiana_typo.rake](../lib/tasks/fix_french_guiana_typo.rake) | 2022-06-08 |
| [lib/tasks/rename_and_assign_chinese_territories.rake](../lib/tasks/rename_and_assign_chinese_territories.rake) | 2022-06-08 |
| [lib/tasks/rename_turkey_turkiye.rake](../lib/tasks/rename_turkey_turkiye.rake) | 2022-12-15 |
| [lib/tasks/country_changes_326_327.rake](../lib/tasks/country_changes_326_327.rake) | 2023-07-24 — `remove_gbr_iot_link`, `rename_countries`; named after a ticket/release pair |

### [CONFIRMED] Empty stub

`comfy:sync_staging_production` in [lib/tasks/export_to_s3.rake](../lib/tasks/export_to_s3.rake) has no body — just a `TODO` comment. It does nothing when run.

### [SUSPECTED] `comfy:export_to_s3`

Same file. A one-time migration of local ActiveStorage blobs into the staging S3 bucket. Dead by intent, but unlike the tasks above it is not *broken* — it would still run. Delete alongside `db/cms_seeds` (section 2), since it is one of that directory's three consumers.

### [SUSPECTED] `comfy:staging_import`

[lib/tasks/staging_seeds.rake](../lib/tasks/staging_seeds.rake). Dead because its hardcoded Linode host is retired (section 2). Worth one check that nobody on the team still uses it to refresh a local CMS from a *current* host before removing.

### [NOT DEAD] `lib/tasks/portal_dev_tools.rake`

You listed this one, but it is **live developer tooling for the current importer**, not legacy. Its four tasks (`dev:import_only`, `dev:import_skip`, `dev:import_resume`, `dev:release_resume`) wrap the *portal* importer — the system that replaced the WDPA S3 path in section 1. Removing it would delete the resume/partial-import escape hatches for the import path you actually depend on.

Its tasks show 0 static references only because rake tasks are invoked from a shell, which is expected for every legitimate task. Recommend keeping.

---

## 4. `db/views/*` — [CONFIRMED] inert

Eight `.sql` files under [db/views/](../db/views/). These are *not* managed by `scenic` — the gem is not in the `Gemfile`. They are read by a local helper, `view_sql(timestamp, view)` in [config/initializers/migration_helpers.rb](../config/initializers/migration_helpers.rb), and referenced only from 2019–2020 migrations.

Two reasons they can never execute in normal operation:

1. **`config.active_record.schema_format = :sql`** ([config/application.rb:55](../config/application.rb#L55)) — databases are built from `db/structure.sql`, so those 2019–2020 migrations are never replayed. The only way to reach these files is to manually roll back a six-year-old migration.
2. **Neither view exists in `db/structure.sql`.** The only views there are `portal_downloads_protected_areas`, one `bk…` backup, and one `tmp_downloads_…`.

Per view:

| View | Files | Status |
|---|---|---|
| `aichi11_target_dashboard_view` | 3 | **Feature deleted.** [db/migrate/20260701120000_drop_aichi11_targets.rb](../db/migrate/20260701120000_drop_aichi11_targets.rb) drops the view and the `aichi11_targets` table, and there are zero `aichi11`/`Aichi` references left anywhere in `app/` or `lib/`. |
| `regional_statistics_view` | 5 | View does not exist in `structure.sql`. See section 5 — its model is broken. |

Caveat: deleting these files makes those old migrations un-rollable. Given `schema_format = :sql` that is already effectively true, but if you want migration history to stay self-consistent, leave the files and just record them as inert.

---

## 5. [CONFIRMED] `Geospatial::Calculator` + `RegionalStatistic` — dead cluster

This is the finding that came out of the `db/views` trail, and it is a clean kill.

**`Geospatial::Calculator`** ([lib/modules/geospatial/calculator.rb](../lib/modules/geospatial/calculator.rb)) has exactly one non-test reference, and it is **commented out** — [app/workers/import_workers/finaliser_worker.rb:41](../app/workers/import_workers/finaliser_worker.rb#L41):

```ruby
# Here for historical reasons. Country stats are no more generated
# dynamically, but received by the PA programme every month.
# Geospatial::Calculator.calculate_statistics
```

The comment states the decision explicitly: stats now arrive as monthly CSVs from the PA programme.

**`RegionalStatistic`** ([app/models/regional_statistic.rb](../app/models/regional_statistic.rb)) sets `self.table_name = 'regional_statistics_view'` — a view that **does not exist in `db/structure.sql`**. Any query through this model raises. Its only non-test caller is `Geospatial::Calculator.clear_cache`, which is itself dead. (The `regional_statistics` *table* does still exist; the model does not point at it.)

Dies with them:

- `lib/modules/geospatial/templates/{country,regional,global}_statistics_query.erb` — reached only via `"#{@level}_statistics_query.erb"` in `calculator.rb`, zero other references
- `lib/modules/geospatial/templates/base_calculation.erb` — referenced only from `calculator.rb:3`
- `test/unit/geospatial/calculator_test.rb`
- the 5 `db/views/regional_statistics_view/*.sql` files from section 4

Keep the rest of `lib/modules/geospatial/` — `country_geometry_populator*` and `geometry.rb` are separate and live.

Also note the already-commented-out stubs in [test/unit/workers/import_workers/finaliser_worker_test.rb](../test/unit/workers/import_workers/finaliser_worker_test.rb) lines 14 and 34, left behind by the same change.

---

## 6. [SUSPECTED] Leftover database objects in `structure.sql`

Not code, but committed schema that looks like uncleaned release residue:

- **17** `bk2607161214_*` tables/views — a release backup snapshot from 2026-07-16 12:14, created by the portal release backup mechanism
- **1** `tmp_downloads_e0951491c49000538f6269141c8a6d5deae01d79` view — a download generator temp view that outlived its request

`rake pp:portal:cleanup_backups[N]` exists precisely to drop old backups. Worth confirming with whoever ran the July release, then cleaning up and regenerating `structure.sql` — these are carried in every checkout.

Also: **[db/schema.rb](../db/schema.rb)** is a leftover from before the switch to `:sql` (its last commit is literally *"Uses SQL schema rather than ruby"*). With `schema_format = :sql` it is never read or regenerated, so it is stale by definition and misleading to read.

---

## 7. The `import` Sidekiq queue — [CONFIRMED] no live producer

`config/sidekiq-import.yml` itself is **wired and live**: [config/deploy.staging.yml:57](../config/deploy.staging.yml#L57) runs a dedicated `job_import` Kamal role whose whole job is `bundle exec sidekiq -C config/sidekiq-import.yml`, serving the `import` queue.

The problem is that **nothing can put a job on that queue any more.** Every producer is dead:

| Worker on `:import` | Enqueued by | Status |
|---|---|---|
| `ImportWorkers::MainWorker` | `S3PollingWorker` only | Dead with the cron chain (section 1) |
| `ImportWorkers::S3PollingWorker` | `config/schedule.rb` cron only | No cron under Kamal (section 1) |
| `ImportWorkers::GeometryPopulatorWorker` | `Wdpa::CountryGeometryPopulator.populate` | That class has **no non-test callers**, and [config/initializers/bystander.rb:26](../config/initializers/bystander.rb#L26) says: `# As of 19Aug2025 CountryGeometryPopulator is not used as stats are now from NC team` |
| `ImportWorkers::FinaliserWorker` | Its only enqueue site is **commented out** — [app/workers/import_workers/base.rb:18](../app/workers/import_workers/base.rb#L18) `# ImportWorkers::FinaliserWorker.perform_async` |
| `ImportWorkers::ProtectedAreasImporter` | **Nothing, anywhere** — zero references outside its own definition, including tests |

The replacement portal release path enqueues nothing at all: `rake pp:portal:release` runs synchronously, and there is not a single `perform_async` in `lib/modules/wdpa/portal/` or `lib/tasks/portal_release.rake`.

So the `job_import` container starts, health-checks, and idles on a queue with no producers. Net effect: a permanently empty Sidekiq process on every deploy.

**Consequence:** `config/sidekiq-import.yml` is dead *by extension*, not on its own. It should be removed together with the `job_import` role in `config/deploy.staging.yml` and the `import_workers` tree — and only once section 1 is resolved, since `S3PollingWorker` is the piece whose liveness is still deploy-dependent.

Also dead, found here:

- **`ImportWorkers::ProtectedAreasImporter`** — the cleanest kill of the group; nothing references it.
- **`ImportWorkers::FinaliserWorker`** — never enqueued.
- [app/workers/import_workers/protected_areas_importer.rb:18](../app/workers/import_workers/protected_areas_importer.rb#L18) references `ImportWorkers::WikipediaSummaryWorker` in a comment — **a class that does not exist anywhere in the repo**.

---

## 8. CI and build files

### [CONFIRMED] The `Rakefile` acceptance-test block is dead

[Rakefile:9-13](../Rakefile#L9-L13):

```ruby
Rake::TestTask.new("test:acceptance" => "test:prepare") do |t|
  t.pattern = "test/acceptance/**/*_test.rb"
end

Rake::Task["test:run"].enhance ["test:acceptance"]
```

Three independent reasons it does nothing:

1. **`test/acceptance/` does not exist.** The `test/` tree is `contracts, controllers, factories, fixtures, helpers, integration, mailers, models, presenters, services, unit`.
2. **The retired Jenkinsfile said so.** Its `rakeTest()` comment read: *"Both run the same set here (no test/acceptance)."*
3. **Nothing invokes `test:run`.** The `enhance` hook only fires on `rake test`. Jenkins used `bundle exec rails test` (deliberately — so SimpleCov loaded before the app), and now that Jenkins is gone nothing invokes either.

The Rakefile has not been touched since 2019-03-15. Only these two statements are dead; keep the `require`s and `Rails.application.load_tasks`.

### [CONFIRMED] `.travis.yml` — abandoned 2020

Last commit 2020-01-07. It provisions an environment that no longer resembles this app in any respect:

| `.travis.yml` | Actual |
|---|---|
| `rvm: 2.6.3` | Ruby 3.3.7 |
| `dist: trusty` (Ubuntu 14.04, EOL) | Debian-based Docker images |
| `postgresql: 9.3`, `libgdal1` | Current PostGIS / GDAL |
| Elasticsearch 7.0.1 `.deb` | Containerised |

Travis has not been in the loop for years, and with Jenkins now retired too the only surviving CI is the GitHub Actions deploy workflow.

> **Security note, not just cleanup:** this file contains encrypted-but-live-looking credentials — a `notifications.slack.secure` token and a `code_climate.repo_token`. Deleting the file does not invalidate them. Have them **revoked**, don't just remove the file.

### [CONFIRMED] `Jenkinsfile` — Jenkins is no longer used

**Confirmed by the team (2026-08-21): Jenkins is retired.** The whole file goes, not just parts of it.

The file's recency is misleading — last commit 2026-07-28, with comments referencing the Media Surfer asset work — so a scan reads it as live. It isn't; the pipeline it describes is no longer run.

Dies with it:

- **[Jenkinsfile](../Jenkinsfile)** — the entire pipeline: build, prepare, test, Snyk scan, Slack notifications to `#jenkins-cicd-pp`, docker cleanup.
- **`.env-jenkins-docker`** — read from exactly one place, `Jenkinsfile:136` (`cp .env-jenkins-docker .env`). Nothing else in the repo touches it.

Two functions in it were already dead even while Jenkins ran, worth noting only because they show how long the Capistrano path had been unused: `deploy()` (`bundle exec cap staging deploy`, hardcoding `git checkout develop`) and `deleteDeployDir()` were defined but never called from any stage.

**Keep `docker-compose.yml`.** Jenkins used it (`COMPOSE_FILE`), but it is also the documented local development environment — see [docs/docker.md](docker.md), which is built around `docker compose up`, plus the `api` profile and the portal release runbook. It is not Jenkins-specific.

Two follow-ups this creates, neither of which is dead code:

- [docs/docker.md:94](docker.md) still refers to *"this project's Jenkins setup"* — now stale.
- `upgrade-plan/backend/10-test-suite.md` and `00-scope-and-shared-milestones.md` describe Jenkins as the CI system and record fixing its Test stage as a milestone. They are historical planning records, so leaving them is defensible, but they no longer describe reality.

> ### ⚠️ This leaves the project with no test CI at all
>
> Verified: `.github/workflows/` contains **only** `deploy-staging-kamal.yml`. There is no test job anywhere — nothing runs `bundle exec rails test`, and nothing runs `vitest` either (`package.json` defines `yarn test`, but no workflow calls it).
>
> That matters more than usual here. Per `upgrade-plan/backend/10-test-suite.md`, the Ruby suite had been silently skipped for years because the Jenkins Test stage read `echo "rakeTest()"` instead of `rakeTest()` — which is *why* a 2021 breakage went unnoticed. It was revived to 624 runs / 0 failures in Jul 2026, and the Jenkins fix that finally made CI enforce it landed at the same time. Retiring Jenkins without replacing that job puts the suite straight back to being unenforced, along with the SimpleCov coverage floor (`COVERAGE=1`) and the Snyk vulnerability scan.
>
> Deleting the Jenkinsfile is correct. Porting the test + coverage + Snyk stages to a GitHub Actions workflow first is strongly recommended — otherwise this cleanup silently removes the guardrail that the backend upgrade work just finished restoring.

### [SUSPECTED] Stale comment in the deploy workflow

[.github/workflows/deploy-staging-kamal.yml](../.github/workflows/deploy-staging-kamal.yml) says *"The existing deploy.yml targets the old Linode staging via Kamal 1 and is left alone, so both run side by side until Linode is decommissioned."* — but `.github/workflows/` now contains **only this one workflow**. The Kamal 1 / Linode workflow it defers to is gone, so the comment describes a coexistence that no longer exists. Worth correcting while the Linode decommission is fresh.

---

## 9. `config/deploy` — [SUSPECTED] Capistrano is superseded

Same open question as section 1: this is dead the moment production stops deploying via Capistrano, and not before.

| Path | Last commit | Notes |
|---|---|---|
| [config/deploy/staging.rb](../config/deploy/staging.rb) | 2021-01-29 | Targets `new-web.pp-staging.linode.protectedplanet.net` — the retired Linode box |
| [config/deploy/production.rb](../config/deploy/production.rb) | 2021-01-29 | Targets `new-web.pp-production.linode.protectedplanet.net` |
| [config/deploy/ansible/](../config/deploy/ansible/) | **2019-05-17** | A whole provisioning tree — `site.yml`, `user.yml`, inventories, and vendored roles (`elasticsearch`, `ruby`, `git`, `nodesource.node`). Untouched for seven years and superseded twice over, by Docker and then Kamal. |
| [config/deploy.rb](../config/deploy.rb) | 2025-11-21 | The only recently-touched piece |
| [Capfile](../Capfile) | 2025-03-06 | |

`config/deploy/ansible/` is the strongest candidate in this group — it provisions bare-metal Linode hosts that no longer exist, and predates the Docker migration entirely. It can reasonably go ahead of the rest.

Note the staging host here is the same retired Linode box hardcoded in `staging_seeds.rake` (section 2) — the same decommission covers both.

**Still-live references to Capistrano**, which must be updated in the same change:

- [docs/deployment.md](deployment.md) lines 8–9 — documents `cap staging deploy` / `cap production deploy` as *the* deploy procedure
- [docs/docker.md](docker.md) lines 112, 117

(The `Jenkinsfile`'s `deploy()` function was the fourth, and goes with the file — section 8.)

`docs/deployment.md` documenting Capistrano while the repo deploys via Kamal is itself a live-documentation bug, independent of whether the code is deleted.

Retiring Capistrano would also let you drop 9 `capistrano-*` gems plus `whenever` from the `Gemfile` — but see the note in section 11 about gem pruning needing its own pass.

---

## 10. Other confirmed dead code

Full detail lives in the audit that produced this document; summarised here so this file is self-contained.

### Whole file

**[app/presenters/cms_presenter.rb](../app/presenters/cms_presenter.rb)** — 49 lines, zero callers, and already carries `TODO(backend): unused` explaining that the CMS versioning UI that fed it was removed.

### Dead methods

| Area | Count | Items |
|---|---|---|
| Helpers | 16 | `autocomplete_link`, `country_autocomplete_link`, `pa_autocomplete_link`, `designation_link`, `facet_link` (`search_helper`); `current_banner`, `get_square_side`, `is_regional_page` (`application_helper`); `map_search_types`, `oecm_services_for_point_query`, `wdpa_services_for_point_query` (`map_helper`); `has_pame_statistics_for`, `management_plan_document`; `has_restricted_sites`; `has_documents` — dead **twice**, in both `regions_helper` and `countries_helper` |
| Presenters / services | 7 | `marine_page_statistics`, `get_designations`, `marine_coverage`, `name_size`, `marine_designation`, `completeness_for`, `import_completion` |
| Models | 4 | `sum_of_most_protected_marine_areas`, `sources_to_json`, `backup_timestamp_string`, `total_protected_marine_area` |
| `lib/` | 6 | `statistics_monthly_import`, `country_tile`, `region_tile`, `configuration_for`, `get_live_materialised_view_name_from_staging`, `attributes_for_green_list_status_create` |

### Controller

`search#map` ([app/controllers/search_controller.rb:40](../app/controllers/search_controller.rb#L40)) is `render :index` with no route, no view, and no reference anywhere.

Also stale: `before_action ... only: %i[show pdf]` in [app/controllers/country_controller.rb:7-8](../app/controllers/country_controller.rb#L7) names a `pdf` action that no longer exists. Harmless, but the comment above it describes fixing an endpoint that has since been deleted.

### Assets

- **[app/assets/images/icons/](../app/assets/images/icons/)** — all 40 files unreferenced; **36 are byte-identical** to `app/frontend/assets/icons/`, which is the copy the CSS actually points at. Sprockets is still active and compiles these into `public/assets`, so this is real shipped weight.
- **25 SVGs** in `app/frontend/assets/icons/` referenced *only* by dead CSS utilities (below).
- 6 orphaned images: `social-marine.png`, `social-sharing-target-dashboard-banff-canada.jpg`, `green_list/logo-white.png`, `green_list/iucn_wcpa_logo.jpg`, `green_list/capebyron.jpg`, `icons/circle-chevron-black-down.svg`.

### CSS

**39 unused `@utility` definitions**, including **30 of the 45** icon utilities in [app/frontend/styles/shared/icons.css](../app/frontend/styles/shared/icons.css) — superseded by the `Icon/*.vue` components during the Vue 3 migration. Also 3 unused in `forms.css`, 2 in `flex.css`, 4 unused typography utilities.

### Frontend

- 28 unused TypeScript exports — 24 of them types in [app/frontend/types/backend.ts](../app/frontend/types/backend.ts), plus `BlobDownload`, `TurboMountLoader`, `trimText`.
- 2 dead `turbo_mount` registrations in [app/frontend/entrypoints/application.ts](../app/frontend/entrypoints/application.ts): `Tooltip` and `TooltipSecond` are registered as mountable islands but never rendered from any ERB. **The components themselves are live** as child components — only the registration entries are dead.

### View

[app/views/partials/messages/_message-country-restricted.html.erb](../app/views/partials/messages/_message-country-restricted.html.erb) — unreferenced partial.

---

## 11. [NOT DEAD] Do not delete these

Recorded because every one of them is flagged by a naive unused-code scan.

| Thing | Why it looks dead | Why it is not |
|---|---|---|
| All 274 flag SVGs in `app/assets/images/flags/` | No literal filename anywhere | Built at runtime: `image_url("flags/#{slug}.svg")` in `areas_serializer.rb`, `country_controller.rb`, `country_presenter.rb` |
| `region_hash`, `country_hash`, `site_hash` | Never called by name | Reached via `send("#{geo_type}_hash", a)` in the same file |
| `lib/cms_tags/text_custom.rb` (`TextCustom`) | Class name appears nowhere else | Loaded by explicit `require Rails.root.join('lib/cms_tags/text_custom')` in `config/initializers/comfortable_media_surfer.rb`, so the class name never appears as a reference |
| `Tooltip/Index.vue`, `Tooltip/Second.vue` | Registrations are dead (section 10) | Live as child components of `Pame/Table/Head/Cell.vue` and `Stats/TooltipInfo.vue` |
| `@hotwired/stimulus`, `@types/node`, `@vue/devtools-api`, `vue-eslint-parser`, `vue-tsc` | No import statement | Stimulus is turbo-mount's runtime peer; `@vue/devtools-api` is pinned for the documented `optimizeDeps` fix; the rest are type packages / eslint parser / the `yarn typecheck` script |
| `region#build_stats`, `country#build_stats` | Public methods with no route | Used as `before_action` callbacks |
| `ApplicationController` methods (`og_tags`, `set_locale`, `raise_404`, …) | No matching route | Callbacks and helper methods, not actions |
| `lib/tasks/portal_dev_tools.rake` | Zero static references | Live dev tooling for the current portal importer — see section 3 |
| `app/views/comfy/admin/cms/partials/_navigation_inner.html.erb` | Unreferenced | Comfy gem renders it by path convention |
| `docker-compose.yml` | Was Jenkins's `COMPOSE_FILE`, and Jenkins is retired | Still the documented local dev environment (`docs/docker.md`, the `api` profile, the portal release runbook) — not Jenkins-specific |
| `config/sidekiq.yml` | — | Live: drives the `job_web`/`job` roles and the `pdf` capsule |
| `config/sidekiq-import.yml` | — | The file **is** wired into a running Kamal role. It is dead only because its queue has no producers — see section 7. Do not delete it in isolation; remove the role with it |

**Not assessed:** the `Gemfile`. A gem-usage scan produced 35 hits that were nearly all false positives (constant-vs-gem-name mismatches like `comfortable_media_surfer` → `ComfortableMediaSurfer`, plus Capfile- and `database.yml`-level wiring). Treat gem pruning as a separate exercise with a proper tool.

---

## Suggested order

Cheapest and safest first:

Zero-risk first — these touch nothing that runs:

1. **`.travis.yml`** (section 8) — and get those two tokens revoked.
2. **The `Rakefile` acceptance block** (section 8) — 5 lines, three independent proofs it is inert.
3. **`Jenkinsfile` + `.env-jenkins-docker`** (section 8) — Jenkins is retired. **Port the test/coverage/Snyk stages to GitHub Actions first** — see the warning in section 8; there is currently no test CI at all.
4. **`ImportWorkers::ProtectedAreasImporter`** (section 7) — zero references anywhere, including tests.
5. **`db/cms_seeds/` + its 3 consumers** (section 2) — 334 MB, closed loop, nothing in the app reads it.
6. **`CmsPresenter`** (section 10) — self-documented as unused.
7. **`app/assets/images/icons/`** (section 10) — 40 files, 36 exact duplicates, wrong copy.

Then, straightforward but worth a review:

8. **Broken and spent rake tasks** (section 3) — two of them cannot even run.
9. **`Geospatial::Calculator` + `RegionalStatistic`** (section 5) — includes a model pointing at a nonexistent view.
10. **30 dead icon utilities + 25 SVGs** (section 10).
11. **Dead helper/presenter/model/lib methods, `search#map`** (section 10).
12. **`config/deploy/ansible/`** (section 9) — seven years stale, provisions hosts that no longer exist.

Blocked on one decision:

13. **WDPA S3 release** (section 1), **the whole `import` queue + `sidekiq-import.yml` + the `job_import` role** (section 7), and **the rest of `config/deploy`** (section 9) — all three unblock together, the moment production is confirmed off Capistrano. Fix `docs/deployment.md` in the same change; it still documents `cap ... deploy` as the procedure.
14. **DB leftovers and `db/schema.rb`** (section 6) — coordinate with whoever ran the July release.

Sections 1, 2, 5 and 7 touch import, CMS, stats and the worker fleet respectively, so each deserves its own PR rather than one sweeping cleanup commit.

## The one question that unblocks the most

**Does production still deploy via Capistrano?** A single answer settles sections 1, 7 and 9 — the WDPA S3 import chain, the entire `import` Sidekiq queue and its dedicated container, `config/deploy/*`, and 10 gems. Everything else in this document can be actioned without it.
