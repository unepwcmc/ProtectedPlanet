# ProtectedPlanet Portal Release Runbook

> **Monthly portal-backed release orchestration for ProtectedPlanet**

## 🚀 Quick Start

### Prerequisites
- **Production**: Services running on production server
- **Local Development**: Docker and docker compose installed
- FDW configured to Portal DB with views created/validated
- Database credentials in `.env` or shell environment

### Start Local Services (Local Development Only)
```bash
# From repo root (local development only)
docker compose up -d db redis elasticsearch webpacker web
docker compose ps  # Check status
```

### Essential Commands

| Task | Production | Local Development |
|------|------------|------------------|
| **Run release** | `bundle exec rake pp:portal:release["Nov2025"]` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:release["Nov2025"]'` |
| **Dry run** | `PP_RELEASE_DRY_RUN=true bundle exec rake pp:portal:release["Nov2025"]` | `docker compose exec -T web bash -lc 'PP_RELEASE_DRY_RUN=true bundle exec rake pp:portal:release["Nov2025"]'` |
| **Check status** | `bundle exec rake pp:portal:status` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'` |
| **Abort release** | `bundle exec rake pp:portal:abort` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:abort'` |
| **Rollback** | `bundle exec rake pp:portal:rollback["2509121644"]` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:rollback["2509121644"]'` |

---

## 📋 Release Process

The release follows 11 phases:

1. **acquire_lock** - Ensures only one release runs at a time
2. **create_staging_materialized_views** - Create staging portal materialized views (optional)
3. **preflight** - Validates views, geometry, and data integrity
4. **build_staging** - Creates staging tables as copies of live tables
5. **import_core** - Runs the main importer into staging and some to live tables
6. **import_related** - Imports secondary/related data
7. **validate_and_manifest** - Performs sanity checks and creates manifest
8. **finalise_swap** - Atomically swaps staging → live (creates backups)
9. **post_swap** - VACUUM, cache clearing, search index rebuild
10. **cleanup_and_retention** - Marks release complete, manages backups
11. **release_lock** - Releases the release lock

### Key Components
- **Live tables**: `protected_areas`, `protected_area_parcels`, `sources`, `countries_*` junctions, `pame_*` and statistics tables
- **Portal views (FDW)**: `portal_standard_points`, `portal_standard_polygons`, `portal_standard_sources`
- **Backup naming**: `bkYYMMDDHHMM_` prefix (e.g., `bk2509121631_protected_areas`)

---

## 🛠️ Commands

> **⚠️ Important**: The release label is **REQUIRED** for all `pp:portal:release` commands. Format: `MMMYYYY` (e.g., `Nov2025`, `Jan2026`). The task will fail with an error if the label is not provided.

### Production Release
```bash
# Release label is REQUIRED (format: MMMYYYY, e.g., Nov2025, Jan2026)
RAILS_ENV=production bundle exec rake pp:portal:release["Oct2025"]
```

### Development & Testing
```bash
# Dry run with lightweight staging (label is REQUIRED)
PP_RELEASE_DRY_RUN=true \
PP_RELEASE_STAGING_LIGHTWEIGHT=true \
PP_RELEASE_CREATE_STAGING_MATERIALIZED_VIEWS=false \
bundle exec rake pp:portal:release["Nov2025"]

# Resume from specific phase (after dry run - use SAME label as dry run)
PP_RELEASE_START_AT=finalise_swap bundle exec rake pp:portal:release["Nov2025"]

# Run only specific phases (label is REQUIRED)
PP_RELEASE_ONLY_PHASES=create_staging_materialized_views,preflight bundle exec rake pp:portal:release["Sep2025"]
```

### Do a dry run without swapping tables

If want to do a release without the release becoming live you can do a dry run and it will stop at validate_and_manifest then you can check all staging_xxx tables in DB before continuing with the swap and make all staging tables to become live

When you run with `PP_RELEASE_DRY_RUN=true`, the release will:
- ✅ Complete all phases up to `validate_and_manifest` (includes validation and manifest creation)
- 🛑 **Stop after `validate_and_manifest`** (does not continue to `finalise_swap` or subsequent phases; lock is still released via ensure block)

```bash
# 1. Dry run (stops after validate_and_manifest phase)
RAILS_ENV=production PP_RELEASE_DRY_RUN=true bundle exec rake pp:portal:release["Nov2025"]

# 2. Check the release status and note the label, you should see the status is currently at the validate_and_manifest phase
RAILS_ENV=production bundle exec rake pp:portal:status

# 3. Run the following from finalise_swap to do the actual swap and rest of steps to finish up
RAILS_ENV=production PP_RELEASE_START_AT=finalise_swap bundle exec rake pp:portal:release["Nov2025"]
```

**Important Notes:**
- Use the **same release label** that was used in the dry run
- The dry run stops automatically after `validate_and_manifest` phase completes
- Resuming from `finalise_swap` will perform the actual atomic swap and continue with remaining phases (`create_portal_downloads_view`, `post_swap`, `cleanup_and_retention`, `release_lock`)

### Developer Tools
```bash
# Import only selected components
bundle exec rake pp:portal:dev:import_only["sources,protected_areas"]

# Skip specific importers
bundle exec rake pp:portal:dev:import_skip["sources"]

# Resume importer using checkpoints
bundle exec rake pp:portal:dev:import_resume["label"]
```

---

## 🔄 Rollback

**⚠️ Safety**: Rollback is blocked if a release is running. Use `pp:portal:abort` first.

```bash
# List available backup timestamps
bundle exec rake pp:portal:list_backups

# Rollback to specific timestamp
bundle exec rake pp:portal:rollback["2509251325"]

# After rolling back all current tables/views become staging tables/views and then you can fix whatever that needs fixing and then start from finalise_swap to swap from staging to live tables to correct a release (label is REQUIRED)
PP_RELEASE_START_AT=finalise_swap bundle exec rake pp:portal:release["Nov2025"]
```

---

## ⚙️ Environment Variables

### Release Control
| Variable | Description | Default |
|----------|-------------|---------|
| `PP_RELEASE_START_AT` | Phase to start at | - |
| `PP_RELEASE_STOP_AFTER` | Phase to stop after | - |
| `PP_RELEASE_ONLY_PHASES` | Comma-separated phases to run | - |
| `PP_RELEASE_DRY_RUN` | Stop after validate_and_manifest (before swap) | `false` |
| `PP_RELEASE_STAGING_LIGHTWEIGHT` | Disable indexes and FKs during staging | `false` |

### Importer Control
| Variable | Description | Default |
|----------|-------------|---------|
| `PP_IMPORT_ONLY` | Comma list of importers to run | - |
| `PP_IMPORT_SKIP` | Comma list of importers to skip | - |
| `PP_IMPORT_SAMPLE` | Integer to limit batch sizes for sampling | - |
| `PP_IMPORT_PROGRESS_NOTIFICATIONS` | Show per-import progress notifications | `true` |

### Notifications
| Variable | Description | Default |
|----------|-------------|---------|
| `PP_SLACK_WEBHOOK_URL` | Slack webhook for notifications | - |
| `PP_RELEASE_SLACK_PHASE_COMPLETE` | Send per-phase complete notifications | `true` |

---

## 🔍 Monitoring

### View Logs
```bash
# Production
tail -n 100 -f log/portal_release.log
bundle exec rake pp:portal:status

# Local Development
docker compose exec -T web bash -lc 'tail -n 100 -f log/portal_release.log'
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'
```

### Enable Slack Notifications
```bash
# Production
export PP_SLACK_WEBHOOK_URL={{PP_SLACK_WEBHOOK_URL}}
export PP_RELEASE_SLACK_PHASE_COMPLETE=false  # Optional: reduce noise
export PP_IMPORT_PROGRESS_NOTIFICATIONS=false  # Optional: silence progress

# Local Development: Add to docker-compose.yml or .env file
# PP_SLACK_WEBHOOK_URL={{PP_SLACK_WEBHOOK_URL}}
# PP_RELEASE_SLACK_PHASE_COMPLETE=false
# PP_IMPORT_PROGRESS_NOTIFICATIONS=false
```

### Check Results
- **Status**: `bundle exec rake pp:portal:status`
- **Manifest**: `public/manifests/<LABEL>.json`
- **Release record**: Rails console or DB (`Release.last`)
- **Logs**: Container stdout and `log/portal_release.log`

---

## 🔧 Maintenance

### Database Cleanup
```bash
# Report backup/staging sizes
bundle exec rails r "require \"./script/db_space_report.rb\"; puts Scripts::DbSpaceReport.run"

# Drop all backups and staging tables
bundle exec rails r "require \"./script/drop_backups_and_staging.rb\"; puts Scripts::DropBackupsAndStaging.run"
```

### Docker Cleanup (Local Development Only)
```bash
docker image prune -f
docker builder prune -af
docker container prune -f
docker image prune -a -f
```

### Portal FDW Views
```bash
# Production
PGPASSWORD={{PP_DB_PASSWORD}} \
psql -h {{PP_DB_HOST}} -p {{PP_DB_PORT}} -U {{PP_DB_USER}} -d {{PP_DB_NAME}} -f FDW_VIEWS.sql

# Local Development
PGPASSWORD={{PP_DB_PASSWORD}} \
psql -h 127.0.0.1 -p 55432 -U postgres -d pp_development -f FDW_VIEWS.sql
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **"Required portal views missing"** | Ensure FDW is connected and portal views exist |
| **"Invalid geometry" or SRID ≠ 4326** | Fix upstream view geometry; must be valid and EPSG:4326 |
| **"Duplicate rows by (site_id, site_pid)"** | Check points/polygons logic; enforce DISTINCT ON upstream |
| **Importer hard errors** | Use `PP_IMPORT_ONLY`/`PP_IMPORT_SKIP` for isolation |
| **Swap fails due to PK/index conflicts** | Ensure staging PK names have `staging_` prefix |
| **zsh bracket expansion errors** | Always quote rake arguments: `rake task['arg']` |
| **"timestamp not found"** | Use `pp:portal:list_backups` to see available timestamps |

---

## 📊 Auditing

### Swap Audit
```bash
# Pre-swap snapshot
bundle exec rails r "require \"./script/swap_audit.rb\"; Scripts::SwapAudit.snapshot(\"tmp/swap_audit_pre.json\")"

# Post-swap snapshot
bundle exec rails r "require \"./script/swap_audit.rb\"; Scripts::SwapAudit.snapshot(\"tmp/swap_audit_post.json\")"

# Generate diff report
bundle exec rails r "require \"./script/swap_audit.rb\"; puts Scripts::SwapAudit.diff(\"tmp/swap_audit_pre.json\",\"tmp/swap_audit_post.json\")" > tmp/swap_audit_diff.json
```

---

## 📚 Reference

### Phase Names
Valid phase names for `PP_RELEASE_START_AT` / `PP_RELEASE_STOP_AFTER` / `PP_RELEASE_ONLY_PHASES`:
- `acquire_lock`, `create_staging_materialized_views`, `preflight`, `build_staging`
- `import_core`, `import_related`, `validate_and_manifest`
- `finalise_swap`, `post_swap`, `cleanup_and_retention`, `release_lock`

### Configuration
- **Backup retention**: `PortalImportConfig.keep_backup_count` (default: 2)
- **Backup naming**: `bkYYMMDDHHMM_<table>`
- **Staging naming**: `staging_<table>`
- **Swap order**: independent tables → main entities → junctions

### Rake Tasks
- **Core**: `pp:portal:release`, `pp:portal:abort`, `pp:portal:rollback`, `pp:portal:list_backups`, `pp:portal:status`
- **Dev tools**: `pp:portal:dev:import_only`, `pp:portal:dev:import_skip`, `pp:portal:dev:import_resume`, `pp:portal:dev:release_resume`

---

> **Note**: In zsh, always quote arguments with brackets or env values to avoid shell expansion.

