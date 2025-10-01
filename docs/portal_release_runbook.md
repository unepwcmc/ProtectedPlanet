# ProtectedPlanet monthly portal-backed release runbook

## Overview

High-level flow:

1) Refresh portal materialized views (optional, recommended before a fresh import)
2) Preflight: validate required views, geometry SRID/validity, and no parcel duplicates
3) Build staging: create staging_ tables as copies of live, optionally lightweight
4) Import core: run the Step 2 importer into staging (supports only/skip/sample)
5) Import related: secondary/related data
6) Validate + Manifest: sanity checks and publish per‑release manifest JSON
7) Finalise swap: atomically swap staging → live (creates timestamped backups)
8) Post‑swap: VACUUM ANALYZE live tables, clear downloads/cache, rebuild search index, and clean old backups
9) Retention: keep the most recent backups (configurable in code)

Key tables (live):
- protected_areas, protected_area_parcels, sources, countries_* junctions, pame_* and statistics tables

Key portal views (FDW):
- portal_standard_points, portal_standard_polygons, portal_standard_sources

Backups created on swap use prefix: bkYYMMDDHHMM_ (example: bk2509121631_protected_areas)

---

## Prerequisites

- Docker and docker compose installed
- Services started for ProtectedPlanet: Postgres, Redis, Web, Webpacker, (Elasticsearch optional for search)
- FDW (foreign data wrapper) configured to the Portal DB and portal views created/validated
- .env or shell env has database credentials to run rake tasks inside the web container

Start services (example):

```bash
# From the repo root
docker compose up -d db redis elasticsearch webpacker web
```

Check services:

```bash
docker compose ps
```


---

## Quick start examples

Monthly release (production):

```bash
  bundle exec rake pp:portal:release
```

Mimic Monthly release without refreshing portal views:

```bash
  PP_RELEASE_REFRESH_VIEWS=false bundle exec rake pp:portal:release
```

Dry run (no swap), lightweight staging, do NOT refresh portal MVs:

```bash
docker compose exec -T web bash -lc \
  'PP_RELEASE_DRY_RUN=true \
   PP_RELEASE_STAGING_LIGHTWEIGHT=true \
   PP_RELEASE_REFRESH_VIEWS=false \
   bundle exec rake pp:portal:release["Sep2025_DRYRUN"]'
```

Real swap (production-like):

```bash
docker compose exec -T web bash -lc \
  'PP_RELEASE_DRY_RUN=false \
   PP_RELEASE_STAGING_LIGHTWEIGHT=false \
   PP_RELEASE_REFRESH_VIEWS=true \
   bundle exec rake pp:portal:release["Sep2025"]'
```

Resume a release from a specific phase (e.g. import_core):

```bash
docker compose exec -T web bash -lc \
  'PP_RELEASE_START_AT=import_core \
   bundle exec rake pp:portal:release["Sep2025"]'
```

Run only certain phases:

```bash
docker compose exec -T web bash -lc \
  'PP_RELEASE_ONLY_PHASES=refresh_views,preflight \
   bundle exec rake pp:portal:release["Sep2025_CHECK"]'
```

Status, abort & list_backups & rollback helpers:

```bash
# Status JSON
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'

# Abort current in‑flight release (drops staging tables)
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:abort'

# List available rollback timestamps (newest first)
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:list_backups'

# Rollback to a backup timestamp (YYMMDDHHMM) — note quoting for zsh
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:rollback["2509121644"]'
```

---

## Release phases and what they do

Phases (in order):

1) acquire_lock
- Ensures only one release runs; fails if a lock is held.

2) refresh_views (optional via flag)
- When PP_RELEASE_REFRESH_VIEWS=true, calls the portal ViewManager to refresh materialized views.

3) preflight
- Validates required portal views exist, geometry SRID=4326 and valid, and that there are no duplicates by (site_id, site_pid) in points/polygons. Requires at least one of points or polygons to be non‑empty.

4) build_staging
- Creates staging tables as copies of live; options to include/exclude indexes and foreign keys.

5) import_core
- Executes importer into staging using importer filters/flags.

6) import_related
- Runs additional related importers (e.g., junctions, statistics), as configured.

7) validate_and_manifest
- Performs minimal sanity checks (e.g., some geometry present) and writes public/manifests/<label>.json.

8) finalise_swap
- If PP_RELEASE_DRY_RUN=false, runs an atomic table swap staging→live; backups are created with bkYYMMDDHHMM_ prefix.

9) post_swap
- Non‑dry run: VACUUM ANALYZE live tables, clear downloads/cache, rebuild search index, and cleanup backups beyond retention.
- Dry run: ANALYZE staging for visibility only.

10) cleanup_and_retention
- Marks the release succeeded; retention is handled by the cleanup service keeping the most recent backups (see config below).

11) release_lock
- Releases the release lock.


---

## Rake tasks

Core tasks (lib/tasks/portal_release.rake):
- pp:portal:release — run the full release orchestration
  - If you need a different month then you can do pp:portal:release["Sep2025"]
- pp:portal:abort — abort current in‑flight release (drops staging tables)
- pp:portal:rollback["YYMMDDHHMM"] — rollback to specific backup timestamp
- pp:portal:list_backups — list available backup timestamps (newest first)
- pp:portal:status — print last release status JSON

Developer helpers (lib/tasks/portal_dev_tools.rake):
- pp:portal:dev:import_only["a,b,c"] — run importer with only list
- pp:portal:dev:import_skip["a,b,c"] — run importer skipping list
- pp:portal:dev:import_resume["label"] — resume importer using checkpoints
- pp:portal:dev:release_resume["label","phase"] — resume full release from a phase (default phase: import_core)


---

## Rollback process

The rollback process performs the following steps:

1) **Check for active release** — prevents rollback while a release is in progress (safety check)
2) **Validate timestamp exists** — checks that the provided backup timestamp is available
3) **Atomic database rollback** — swaps live tables with backup tables using database transactions
4) **Update current release** — automatically makes the release corresponding to the backup timestamp the current active release
5) **Clear downloads/cache** — removes generated downloads from S3 and Redis cache
6) **Rebuild search index** — recreates Elasticsearch index to reflect rolled-back data
7) **Clear Rails cache** — ensures fresh data is served after rollback

Rollback is considered successful if the database rollback completes, even if cleanup operations fail.

**Safety Note:** Rollback will be blocked if a release is currently running. Use `pp:portal:abort` to stop an active release before attempting rollback.

---

## Environment flags (all optional unless noted)

Release flow control (app/services/portal_release/service.rb):
- PP_RELEASE_START_AT — phase name to start at (e.g. import_core)
- PP_RELEASE_STOP_AFTER — phase name to stop after
- PP_RELEASE_ONLY_PHASES — comma‑separated list of phases to run
- PP_RELEASE_DRY_RUN — true/false; if true, skip atomic swap and post‑swap VACUUM of live tables
- PP_RELEASE_REFRESH_VIEWS — true/false; refresh portal MVs in the refresh_views phase (defaults to true)

Swap/rollback (app/services/portal_release/swap_manager.rb):
- No environment variables needed — rollback timestamp is passed as argument to rake task

Staging table creation (lib/modules/wdpa/portal/managers/staging_table_manager.rb):
- PP_RELEASE_STAGING_LIGHTWEIGHT — true to disable indexes and FKs during initial staging creation
- PP_RELEASE_STAGING_INCLUDE_INDEXES — default true; set false to skip index creation (ignored if LIGHTWEIGHT=true)
- PP_RELEASE_STAGING_INCLUDE_FKS — default true; set false to skip foreign key creation (ignored if LIGHTWEIGHT=true)

Importer (app/services/portal_release/importer.rb and dev tasks):
- PP_IMPORT_ONLY — comma list of importers to run (e.g., sources,protected_areas)
- PP_IMPORT_SKIP — comma list of importers to skip
- PP_IMPORT_SAMPLE — integer to limit batch sizes for sampling
- PP_IMPORT_CHECKPOINTS_DISABLE — set to 'false' to enable checkpoint resume mode via dev tasks
- PP_IMPORT_PROGRESS_NOTIFICATIONS — set to 'false' to silence per-import progress notifications (defaults to true)

Logging & Slack (app/services/portal_release/*.rb):
- PP_SLACK_WEBHOOK_URL — Slack Incoming Webhook for release notifications (start/phase complete/swap/fail/rollback)
- PP_RELEASE_SLACK_PHASE_COMPLETE — set to 'false' to silence per‑phase complete posts (defaults to true)
- PP_RELEASE_LOG_PATH — path to JSON log file (default: log/portal_release.log)

Retention (lib/modules/wdpa/portal/config/portal_import_config.rb):
- keep_backup_count is set in code (default 2). Change method PortalImportConfig.keep_backup_count if needed.


---

## How to refresh portal FDW views

If your FDW views need to be recreated/updated:

```bash
# Option 1: from host (replace vars accordingly)
PGPASSWORD={{PP_DB_PASSWORD}} \
psql -h 127.0.0.1 -p 55432 -U postgres -d pp_development -f FDW_VIEWS.sql

# Option 2: inside the db container (if psql installed and file mounted)
```

Make sure the FDW foreign tables reflect schema changes (e.g., new columns) and the portal read‑only user has SELECT grants on new tables.


---

## Observability quick checks (dev)

1) Tail dedicated JSON log:

```bash
docker compose exec -T web bash -lc 'tail -n 100 -f log/portal_release.log'
```

2) Enable Slack notifications (replace {{PP_SLACK_WEBHOOK_URL}} with your secret):

```bash
# Within the web container session or your compose env
export PP_SLACK_WEBHOOK_URL={{PP_SLACK_WEBHOOK_URL}}
# Optional: reduce noise by disabling per‑phase posts
export PP_RELEASE_SLACK_PHASE_COMPLETE=false
# Optional: silence importer progress notifications (defaults to true)
export PP_IMPORT_PROGRESS_NOTIFICATIONS=false
```

3) Run a dry run and watch for start/phase/finish messages in Slack and the log file:

```bash
docker compose exec -T web bash -lc \
  'PP_RELEASE_DRY_RUN=true \
   PP_RELEASE_REFRESH_VIEWS=false \
   bundle exec rake pp:portal:release["WDPA_2025_09_DEV_OBS"]'
```

---

## Examples

1) Full dry run for this month (fast staging):

```bash
docker compose exec -T web bash -lc \
  'PP_RELEASE_DRY_RUN=true \
   PP_RELEASE_STAGING_LIGHTWEIGHT=true \
   PP_RELEASE_REFRESH_VIEWS=false \
   bundle exec rake pp:portal:release["WDPA_2025_10_DRYRUN"]'
```

2) Real run with swap and post‑swap cleanup:

```bash
docker compose exec -T web bash -lc \
  'PP_RELEASE_DRY_RUN=false \
   PP_RELEASE_STAGING_LIGHTWEIGHT=false \
   PP_RELEASE_REFRESH_VIEWS=true \
   bundle exec rake pp:portal:release["WDPA_2025_10"]'
```

3) Import only selected components (dev):

```bash
docker compose exec -T web bash -lc \
  'bundle exec rake pp:portal:dev:import_only["sources,protected_areas"]'
```

4) Resume a release from import_core:

```bash
docker compose exec -T web bash -lc \
  'PP_RELEASE_START_AT=import_core \
   bundle exec rake pp:portal:release["WDPA_2025_10"]'
```

5) Rollback to a specific backup:

```bash
# First, list available timestamps
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:list_backups'

# Then rollback to a specific timestamp
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:rollback["2509251325"]'
```

6) Post-rollback data fixes and resume:

```bash
# Resume release from import_related phase
docker compose exec -T web bash -lc \
  'PP_RELEASE_START_AT=import_related bundle exec rake pp:portal:release'
```

Note: In zsh, always quote arguments with brackets or env values to avoid shell expansion.


---

## Where to see results

- Status: `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'`
- Available rollback timestamps: `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:list_backups'`
- Manifest: public/manifests/<LABEL>.json
- Release record: via Rails console or DB (Release.last)
- Logs: application logs (container stdout) include phase events
- Dedicated JSON log: `log/portal_release.log` (tail with `docker compose exec -T web bash -lc 'tail -n 100 -f log/portal_release.log'`)


---

## Audits and verification

Swap audit (script/swap_audit.rb):

```bash
# Pre-swap or pre-rollback snapshot
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/swap_audit.rb\"; Scripts::SwapAudit.snapshot(\"tmp/swap_audit_pre.json\")"'

# Post-swap or post-rollback snapshot
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/swap_audit.rb\"; Scripts::SwapAudit.snapshot(\"tmp/swap_audit_post.json\")"'

# Diff and save JSON report
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/swap_audit.rb\"; puts Scripts::SwapAudit.diff(\"tmp/swap_audit_pre.json\",\"tmp/swap_audit_post.json\")" > tmp/swap_audit_diff.json'
```

The diff reports row counts, PK/FK/index counts, invalid indexes, sequences, and relation sizes.


---

## Disk usage and cleanup

Report backup/staging sizes (script/db_space_report.rb):

```bash
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/db_space_report.rb\"; puts Scripts::DbSpaceReport.run" && \
   cat tmp/db_space_report.json'
```

Drop all backups and all staging tables (script/drop_backups_and_staging.rb):

```bash
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/drop_backups_and_staging.rb\"; puts Scripts::DropBackupsAndStaging.run" && \
   cat tmp/drop_report.json'
```

Docker space reclamation (host):

```bash
# Dangling images, builder cache, stopped containers, unused images
docker image prune -f
docker builder prune -af
docker container prune -f
docker image prune -a -f

# Optional: prune unused volumes (be careful)
# docker volume prune -f
```


---

## Troubleshooting

- Preflight: "Required portal views missing"
  - Ensure FDW is connected and portal views exist; run ViewManager.validate_required_views_exist.

- Preflight: "Invalid geometry" or SRID ≠ 4326
  - Fix upstream view geometry; all geometries must be valid and in EPSG:4326.

- Preflight: "Duplicate rows by (site_id, site_pid)"
  - Check your points/polygons logic; DISTINCT ON (site_id, site_pid) should be enforced upstream.

- Importer hard errors in import_core
  - Inspect Step 2 importer output; use PP_IMPORT_ONLY/PP_IMPORT_SKIP for isolation; check staging table model PKs.

- Swap fails due to PK/index rename conflicts
  - The swap service renames PKs, indexes, and sequences; ensure staging PK names have staging_ prefix; fix any name collisions.

- Backup cleanup fails due to dependencies
  - Some materialized views may depend on backup tables; cleanup uses CASCADE if needed. Recreate dependent MVs after cleanup if required.

- zsh bracket expansion errors
  - Always quote rake arguments with brackets: rake task['arg'] inside single quotes.

- Rollback fails with "timestamp not found"
  - Use `pp:portal:list_backups` to see available timestamps before attempting rollback.


---

## Configuration reference

- PortalImportConfig.keep_backup_count — how many backup sets to retain (default 2)
- Backup/table naming:
  - Backups: bkYYMMDDHHMM_<table>
  - Staging: staging_<table>
- Swap order: independent tables → main entities → junctions (to satisfy FK dependencies)


---

## Appendix: Phase names

Valid phase names for PP_RELEASE_START_AT / PP_RELEASE_STOP_AFTER / PP_RELEASE_ONLY_PHASES:
- acquire_lock
- refresh_views
- preflight
- build_staging
- import_core
- import_related
- validate_and_manifest
- finalise_swap
- post_swap
- cleanup_and_retention
- release_lock


---

## Appendix: Portal importer flags (Step 2)

- PP_IMPORT_ONLY — list of importers to include
- PP_IMPORT_SKIP — list of importers to exclude
- PP_IMPORT_SAMPLE — integer sample size
- PP_IMPORT_CHECKPOINTS_DISABLE — set to 'false' to enable checkpoint resume via dev task

Run via dev rake tasks in lib/tasks/portal_dev_tools.rake.

