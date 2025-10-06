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

# Check status
docker compose ps
```

### Common Commands

| Task | Production Command | Local Development Command |
|------|-------------------|---------------------------|
| **Production release** | `bundle exec rake pp:portal:release` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:release'` |
| **Dry run** | `PP_RELEASE_DRY_RUN=true bundle exec rake pp:portal:release` | `docker compose exec -T web bash -lc 'PP_RELEASE_DRY_RUN=true bundle exec rake pp:portal:release'` |
| **Check status** | `bundle exec rake pp:portal:status` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'` |
| **Abort release** | `bundle exec rake pp:portal:abort` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:abort'` |
| **List backups** | `bundle exec rake pp:portal:list_backups` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:list_backups'` |
| **Rollback** | `bundle exec rake pp:portal:rollback["2509121644"]` | `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:rollback["2509121644"]'` |

---

## 📋 Release Process Overview

The release process follows these 11 phases:

1. **acquire_lock** - Ensures only one release runs at a time
2. **refresh_views** - Refreshes portal materialized views (optional)
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

## 🛠️ Detailed Commands

### Production Release
```bash
# Production: Full production release
bundle exec rake pp:portal:release

# With specific month year
bundle exec rake pp:portal:release['Oct2025']
```

### Development & Testing
```bash
# Dry run with lightweight staging
PP_RELEASE_DRY_RUN=true \
PP_RELEASE_STAGING_LIGHTWEIGHT=true \
PP_RELEASE_REFRESH_VIEWS=false \
bundle exec rake pp:portal:release

# Resume from specific phase
PP_RELEASE_START_AT=import_core \
bundle exec rake pp:portal:release["Sep2025"]

# Run only specific phases
PP_RELEASE_ONLY_PHASES=refresh_views,preflight \
bundle exec rake pp:portal:release["Sep2025"]
```

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

## 🔄 Rollback Process

The rollback process is atomic and safe:

1. **Check for active release** - Prevents rollback during active release
2. **Validate timestamp exists** - Ensures backup timestamp is available
3. **Atomic database rollback** - Swaps live tables with backup tables
4. **Update current release** - Makes rolled-back release the active one
5. **Clear downloads/cache** - Removes generated downloads from S3 and Redis
6. **Rebuild search index** - Recreates Elasticsearch index
7. **Clear Rails cache** - Ensures fresh data is served

**⚠️ Safety Note**: Rollback is blocked if a release is running. Use `pp:portal:abort` first.

### Rollback Commands
```bash
# List available backup timestamps
bundle exec rake pp:portal:list_backups

# Rollback to specific timestamp
bundle exec rake pp:portal:rollback["2509251325"]

#Post-rollback resume
PP_RELEASE_START_AT=import_related bundle exec rake pp:portal:release
```

---

## ⚙️ Environment Variables

### Release Flow Control
| Variable | Description | Default |
|----------|-------------|---------|
| `PP_RELEASE_START_AT` | Phase to start at (e.g., `import_core`) | - |
| `PP_RELEASE_STOP_AFTER` | Phase to stop after | - |
| `PP_RELEASE_ONLY_PHASES` | Comma-separated phases to run | - |
| `PP_RELEASE_DRY_RUN` | Skip atomic swap and VACUUM | `false` |
| `PP_RELEASE_REFRESH_VIEWS` | Refresh portal materialized views | `true` |

### Staging Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `PP_RELEASE_STAGING_LIGHTWEIGHT` | Disable indexes and FKs during staging creation | `false` |
| `PP_RELEASE_STAGING_INCLUDE_INDEXES` | Include indexes in staging (ignored if LIGHTWEIGHT=true) | `true` |
| `PP_RELEASE_STAGING_INCLUDE_FKS` | Include foreign keys in staging (ignored if LIGHTWEIGHT=true) | `true` |

### Importer Configuration
| Variable | Description | Default |
|----------|-------------|---------|
| `PP_IMPORT_ONLY` | Comma list of importers to run | - |
| `PP_IMPORT_SKIP` | Comma list of importers to skip | - |
| `PP_IMPORT_SAMPLE` | Integer to limit batch sizes for sampling | - |
| `PP_IMPORT_CHECKPOINTS_DISABLE` | Enable checkpoint resume mode | `true` |
| `PP_IMPORT_PROGRESS_NOTIFICATIONS` | Show per-import progress notifications | `true` |

### Logging & Notifications
| Variable | Description | Default |
|----------|-------------|---------|
| `PP_SLACK_WEBHOOK_URL` | Slack webhook for notifications | - |
| `PP_RELEASE_SLACK_PHASE_COMPLETE` | Send per-phase complete notifications | `true` |
| `PP_RELEASE_LOG_PATH` | Path to JSON log file | `log/portal_release.log` |

---

## 🔍 Monitoring & Observability

### View Logs
```bash
# Production: Tail dedicated JSON log
tail -n 100 -f log/portal_release.log

# Production: Check release status
bundle exec rake pp:portal:status

# Local Development: Tail dedicated JSON log
docker compose exec -T web bash -lc 'tail -n 100 -f log/portal_release.log'

# Local Development: Check release status
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'
```

### Enable Slack Notifications
```bash
# Production: Set environment variables
export PP_SLACK_WEBHOOK_URL={{PP_SLACK_WEBHOOK_URL}}
export PP_RELEASE_SLACK_PHASE_COMPLETE=false  # Optional: reduce noise
export PP_IMPORT_PROGRESS_NOTIFICATIONS=false  # Optional: silence progress

# Local Development: Set environment variables in docker-compose or .env
# Add to docker-compose.yml or .env file:
# PP_SLACK_WEBHOOK_URL={{PP_SLACK_WEBHOOK_URL}}
# PP_RELEASE_SLACK_PHASE_COMPLETE=false
# PP_IMPORT_PROGRESS_NOTIFICATIONS=false
```

### Check Results
- **Status**: 
  - Production: `bundle exec rake pp:portal:status`
  - Local: `docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'`
- **Manifest**: `public/manifests/<LABEL>.json`
- **Release record**: Rails console or DB (`Release.last`)
- **Logs**: 
  - Production: Container stdout and `log/portal_release.log`
  - Local: `docker compose logs web` and `log/portal_release.log`

---

## 🔧 Maintenance & Cleanup

### Database Space Management
```bash
# Production: Report backup/staging sizes
bundle exec rails r "require \"./script/db_space_report.rb\"; puts Scripts::DbSpaceReport.run"

# Production: Drop all backups and staging tables
bundle exec rails r "require \"./script/drop_backups_and_staging.rb\"; puts Scripts::DropBackupsAndStaging.run"

# Local Development: Report backup/staging sizes
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/db_space_report.rb\"; puts Scripts::DbSpaceReport.run"'

# Local Development: Drop all backups and staging tables
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/drop_backups_and_staging.rb\"; puts Scripts::DropBackupsAndStaging.run"'
```

### Docker Cleanup (Local Development Only)
```bash
# Clean up Docker resources (local development only)
docker image prune -f
docker builder prune -af
docker container prune -f
docker image prune -a -f
```

### Portal FDW Views
```bash
# Production: Refresh FDW views (replace variables as needed)
PGPASSWORD={{PP_DB_PASSWORD}} \
psql -h {{PP_DB_HOST}} -p {{PP_DB_PORT}} -U {{PP_DB_USER}} -d {{PP_DB_NAME}} -f FDW_VIEWS.sql

# Local Development: Refresh FDW views (replace variables as needed)
PGPASSWORD={{PP_DB_PASSWORD}} \
psql -h 127.0.0.1 -p 55432 -U postgres -d pp_development -f FDW_VIEWS.sql
```

---

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **"Required portal views missing"** | Ensure FDW is connected and portal views exist |
| **"Invalid geometry" or SRID ≠ 4326** | Fix upstream view geometry; must be valid and EPSG:4326 |
| **"Duplicate rows by (site_id, site_pid)"** | Check points/polygons logic; enforce DISTINCT ON upstream |
| **Importer hard errors** | Use `PP_IMPORT_ONLY`/`PP_IMPORT_SKIP` for isolation |
| **Swap fails due to PK/index conflicts** | Ensure staging PK names have `staging_` prefix |
| **Backup cleanup fails** | Some MVs may depend on backup tables; cleanup uses CASCADE |
| **zsh bracket expansion errors** | Always quote rake arguments: `rake task['arg']` |
| **"timestamp not found"** | Use `pp:portal:list_backups` to see available timestamps |

---

## 📊 Auditing & Verification

### Swap Audit
```bash
# Production: Pre-swap snapshot
bundle exec rails r "require \"./script/swap_audit.rb\"; Scripts::SwapAudit.snapshot(\"tmp/swap_audit_pre.json\")"

# Production: Post-swap snapshot
bundle exec rails r "require \"./script/swap_audit.rb\"; Scripts::SwapAudit.snapshot(\"tmp/swap_audit_post.json\")"

# Production: Generate diff report
bundle exec rails r "require \"./script/swap_audit.rb\"; puts Scripts::SwapAudit.diff(\"tmp/swap_audit_pre.json\",\"tmp/swap_audit_post.json\")" > tmp/swap_audit_diff.json

# Local Development: Pre-swap snapshot
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/swap_audit.rb\"; Scripts::SwapAudit.snapshot(\"tmp/swap_audit_pre.json\")"'

# Local Development: Post-swap snapshot
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/swap_audit.rb\"; Scripts::SwapAudit.snapshot(\"tmp/swap_audit_post.json\")"'

# Local Development: Generate diff report
docker compose exec -T web bash -lc \
  'bundle exec rails r "require \"./script/swap_audit.rb\"; puts Scripts::SwapAudit.diff(\"tmp/swap_audit_pre.json\",\"tmp/swap_audit_post.json\")" > tmp/swap_audit_diff.json'
```

The audit reports row counts, PK/FK/index counts, invalid indexes, sequences, and relation sizes.

---

## 📚 Reference

### Phase Names
Valid phase names for `PP_RELEASE_START_AT` / `PP_RELEASE_STOP_AFTER` / `PP_RELEASE_ONLY_PHASES`:
- `acquire_lock`, `refresh_views`, `preflight`, `build_staging`
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

