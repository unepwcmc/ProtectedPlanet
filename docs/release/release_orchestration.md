# Portal Release Orchestration - Technical Reference

> **For developers only** - Assumes you've read [Portal Release Runbook](portal_release_runbook.md) for basic usage

This document provides code-level technical details about the portal-backed release orchestration system. It references actual code and implementation details rather than duplicating usage instructions.

> **Related**: See [Release Data Imports](release_data_imports.md) for a comprehensive guide to what data is imported during a release.

---

## Architecture Overview

The release system coordinates a full release cycle using portal importers to populate staging tables, performs preflight checks, writes a manifest, and atomically swaps staging tables to live.

**Key Services:**
- `PortalRelease::Service` (`app/services/portal_release/service.rb`) - Main orchestrator
- `PortalRelease::SwapManager` (`app/services/portal_release/swap_manager.rb`) - Handles table swapping
- `Wdpa::Portal::Services::Core::TableSwapService` (`lib/modules/wdpa/portal/services/core/table_swap_service.rb`) - Atomic table swaps

**Key Components:**
- **Advisory lock**: PostgreSQL advisory lock (key: `42000001`) prevents concurrent runs
- **Staging tables**: `staging_*` prefix - Temporary tables for new data
- **Live tables**: `protected_areas`, `protected_area_parcels`, `sources`, etc.
- **Backup tables**: `bkYYMMDDHHMM_*` prefix - Automatic backups before swap
- **Portal views (FDW)**: `portal_standard_points`, `portal_standard_polygons`, `portal_standard_sources`

---

## Release Phases

The release follows 11 phases executed in sequence:

### 1. acquire_lock
- **Purpose**: Ensures only one release runs at a time
- **Implementation**: PostgreSQL advisory lock (`pg_advisory_lock`)
- **Lock key**: `42000001`
- **Failure**: Raises error if another release is running

### 2. create_staging_materialized_views
- **Purpose**: Create staging portal materialized views (optional)
- **Control**: `PP_RELEASE_CREATE_STAGING_MATERIALIZED_VIEWS` (default: `true`)
- **Views created**: `staging_portal_standard_*` versions of live views

### 3. preflight
- **Purpose**: Validates views, geometry, and data integrity
- **Checks**:
  - Required portal views exist
  - Non-zero counts for points/polygons
  - Geometry validity (SRID 4326, valid geometries)
  - No duplicate rows by (site_id, site_pid)
- **Failure**: Raises error if validation fails

### 4. build_staging
- **Purpose**: Creates staging tables as copies of live tables
- **Implementation**: `Wdpa::Portal::Managers::StagingTableManager`
- **Options**: 
  - `PP_RELEASE_STAGING_LIGHTWEIGHT=true` - Disable indexes and FKs during build
- **Tables created**: All tables with `staging_` prefix

### 5. import_core
- **Purpose**: Runs the main importer into staging tables
- **Implementation**: `Wdpa::Portal::Importer`
- **Data imported**: Protected areas, parcels, sources
- **Progress**: Optional Slack notifications via `PP_IMPORT_PROGRESS_NOTIFICATIONS`

### 6. import_related
- **Purpose**: Imports secondary/related data
- **Implementation**: `PortalRelease::RelatedImporters`
- **Data imported**: Statistics, PAME data, etc.

### 7. validate_and_manifest
- **Purpose**: Performs sanity checks and creates manifest
- **Validation**: Basic data integrity checks
- **Manifest**: JSON file written to `public/manifests/<LABEL>.json`
- **Dry run stop**: If `PP_RELEASE_DRY_RUN=true`, stops here

### 8. finalise_swap
- **Purpose**: Atomically swaps staging → live (creates backups)
- **Implementation**: `PortalRelease::SwapManager` → `TableSwapService`
- **Process**:
  1. Ensure staging has indexes/FKs
  2. Create backups of live tables (`bkYYMMDDHHMM_*`)
  3. Atomic rename: `live → backup`, `staging → live`
  4. Rename primary keys, indexes, sequences
  5. Swap materialized views
- **Transaction**: All swaps happen in a single database transaction
- **Safety**: Lock timeout (30s) and statement timeout (5min)

### 9. create_portal_downloads_view
- **Purpose**: Creates/updates portal downloads view
- **Implementation**: `PortalRelease::Preflight.create_portal_downloads_view!`
- **View**: `portal_downloads_protected_areas`
- **Process**: Atomic swap of staging view → live view

### 10. post_swap
- **Purpose**: VACUUM, cache clearing, search index rebuild
- **Operations**:
  - `VACUUM ANALYZE` on all swapped tables
  - Rebuild search index (`Search::Index.delete` → `create`)
  - Clear downloads cache (`Download.clear_downloads`)
  - Clear Rails cache (`Rails.cache.clear`)

### 11. cleanup_and_retention
- **Purpose**: Marks release complete, manages backups
- **Operations**:
  - Cleanup old backups (keeps N most recent, configurable)
  - Update release state to `succeeded`
  - Send success notification

### 12. release_lock
- **Purpose**: Releases the advisory lock
- **Always runs**: Via `ensure` block even on failure

### 13. reset_checkpoints
- **Purpose**: Resets import checkpoints for next release
- **Implementation**: `Wdpa::Portal::Checkpoint.reset_all!`

---

## Table Swap Sequence

Tables are swapped in a specific order to respect foreign key dependencies:

1. **Independent tables** (no FKs): `sources`, `green_list_status`, `no_take_status`, etc.
2. **Main entity tables** (referenced by junctions): `protected_areas`, `protected_area_parcels`
3. **Junction tables** (have FKs): `countries_pas`, `countries_pa_parcels`, etc.

This ordering ensures referenced tables exist before tables that reference them.

---

## Configuration

### Release Control Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PP_RELEASE_START_AT` | Phase to start at | - |
| `PP_RELEASE_STOP_AFTER` | Phase to stop after | - |
| `PP_RELEASE_ONLY_PHASES` | Comma-separated phases to run | - |
| `PP_RELEASE_DRY_RUN` | Stop after validate_and_manifest (before swap) | `false` |
| `PP_RELEASE_STAGING_LIGHTWEIGHT` | Disable indexes and FKs during staging | `false` |
| `PP_RELEASE_CREATE_STAGING_MATERIALIZED_VIEWS` | Create staging MVs during preflight | `true` |

### Importer Control Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PP_IMPORT_ONLY` | Comma list of importers to run | - |
| `PP_IMPORT_SKIP` | Comma list of importers to skip | - |
| `PP_IMPORT_SAMPLE` | Integer to limit batch sizes for sampling | - |
| `PP_IMPORT_PROGRESS_NOTIFICATIONS` | Show per-import progress notifications | `true` |

### Notification Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PP_SLACK_WEBHOOK_URL` | Slack webhook for notifications | - |
| `PP_RELEASE_SLACK_PHASE_COMPLETE` | Send per-phase complete notifications | `true` |

### Code Configuration

- **Backup retention**: `PortalImportConfig.keep_backup_count` (default: `1`)
- **Backup naming**: `bkYYMMDDHHMM_<table>`
- **Staging naming**: `staging_<table>`
- **Lock timeout**: `PortalImportConfig.lock_timeout_ms` (default: `30000` = 30 seconds)
- **Statement timeout**: `PortalImportConfig.statement_timeout_ms` (default: `300000` = 5 minutes)

---

## Rake Tasks

For usage instructions, see [Portal Release Runbook - Essential Commands](portal_release_runbook.md#essential-commands).

**Core tasks** (defined in `lib/tasks/portal_release.rake`):
- `pp:portal:release[LABEL]` - Main release task
- `pp:portal:abort` - Abort current release
- `pp:portal:rollback[TIMESTAMP]` - Rollback to backup
- `pp:portal:list_backups` - List available backups
- `pp:portal:status` - Show release status

**Developer tools**:
- `pp:portal:dev:import_only[COMPONENTS]` - Import only selected components
- `pp:portal:dev:import_skip[COMPONENTS]` - Skip specific importers
- `pp:portal:dev:import_resume[LABEL]` - Resume importer using checkpoints
- `pp:portal:cleanup_backups[KEEP_COUNT]` - Manually clean up old backups

---

## Phase Names Reference

Valid phase names for `PP_RELEASE_START_AT` / `PP_RELEASE_STOP_AFTER` / `PP_RELEASE_ONLY_PHASES`:

See `PortalRelease::Service::PHASES` in `app/services/portal_release/service.rb`

---

## Database Objects

### Tables

**Live tables** (swapped during release):
- Independent tables: See `independent_table_names` in `lib/modules/wdpa/portal/config/portal_import_config.rb`
- Main entity tables: See `main_entity_tables` in `lib/modules/wdpa/portal/config/portal_import_config.rb`
- Junction tables: See `junction_tables` in `lib/modules/wdpa/portal/config/portal_import_config.rb`
- Swap order: See `swap_sequence_live_table_names` in `lib/modules/wdpa/portal/config/portal_import_config.rb`

**Staging tables** (temporary, created during release):
- Generated by adding `staging_` prefix to live table names
- Created via `Wdpa::Portal::Managers::StagingTableManager`

**Backup tables** (created during swap):
- Format: `bkYYMMDDHHMM_<table>` (e.g., `bk2509121631_protected_areas`)
- Generated by `generate_backup_name` method in `lib/modules/wdpa/portal/config/portal_import_config.rb`

### Materialized Views

**Live views**:
- View definitions: See `portal_materialised_views_hash` in `lib/modules/wdpa/portal/config/portal_import_config.rb`
- View names: See `portal_live_materialised_view_values` in `lib/modules/wdpa/portal/config/portal_import_config.rb`

**Staging views**:
- Generated by adding `staging_` prefix to live view names
- Retrieved via `portal_staging_materialised_view_values` method in `lib/modules/wdpa/portal/config/portal_import_config.rb`

### Regular Views

- `portal_downloads_protected_areas` - Used by download generators

---

## Rollback Process

Rollback reverses a release by restoring backup tables to live. For usage instructions, see [Portal Release Runbook - Rollback](portal_release_runbook.md#rollback).

**Implementation** (`app/services/portal_release/swap_manager.rb` and `lib/modules/wdpa/portal/services/core/table_rollback_service.rb`):

**Safety Checks:**
- Lock check: Rollback is blocked if a release is currently running (via `PortalRelease::Lock.lock_available?`)
- Backup validation: Verifies backup tables exist before rollback
- Transaction: All rollback operations happen in a single database transaction

**Rollback Steps:**
1. Validate backup tables exist for the given timestamp
2. Move current live tables → staging
3. Restore backup tables → live
4. Rename primary keys, indexes, sequences
5. Rollback materialized views
6. Rollback downloads view
7. Update release record to mark previous release as current

---

## Monitoring & Logging

For usage instructions, see [Portal Release Runbook - Monitoring](portal_release_runbook.md#monitoring).

**Log Files:**
- Release log: `log/portal_release.log` (written by `PortalRelease::Logger`)
- Rails log: `log/production.log` (or environment-specific)

**Status Checking:**
- `pp:portal:status` rake task queries `Release.last` and returns JSON
- Status includes: id, label, state, created_at, updated_at, manifest_url

**Database Queries** (Rails console):
```ruby
# Get current release
Release.current_release

# Get release events
Release.last.release_events.order(created_at: :asc)

# Check release state
Release.last.state
```

---

## Troubleshooting

For common issues and solutions, see [Portal Release Runbook - Troubleshooting](portal_release_runbook.md#troubleshooting).

**Technical Debugging:**

**Phase Control** (via environment variables):
- `PP_RELEASE_ONLY_PHASES` - Run only specific phases
- `PP_RELEASE_START_AT` - Start from specific phase
- `PP_RELEASE_STOP_AFTER` - Stop after specific phase

**Common Technical Issues:**
- **Lock timeout errors**: Check for long-running queries blocking table renames (lock timeout: 30s)
- **Swap fails due to PK/index conflicts**: Ensure staging PK names have `staging_` prefix (see `validate_staging_live_table_primary_key` in `table_operation_utilities.rb`)
- **Transaction rollback**: All swaps happen in transactions - check logs for specific error

---

## Implementation Details

### Services

- `PortalRelease::Service` - Main orchestrator
- `PortalRelease::SwapManager` - Handles table swapping
- `PortalRelease::Preflight` - Validation and checks
- `PortalRelease::Lock` - Advisory lock management
- `PortalRelease::Cleanup` - Post-swap cleanup
- `Wdpa::Portal::Services::Core::TableSwapService` - Atomic table swaps
- `Wdpa::Portal::Services::Core::TableRollbackService` - Rollback operations
- `Wdpa::Portal::Services::Core::TableCleanupService` - Backup cleanup

### Models

- `Release` - Release records with state tracking
- `ReleaseEvent` - Event log for each release

### Safety Features

- **Advisory locks**: Prevent concurrent releases
- **Transactions**: Atomic swaps and rollbacks
- **Timeouts**: Lock timeout (30s) and statement timeout (5min)
- **Validation**: Preflight checks before swap
- **Backups**: Automatic backup creation before swap
- **Dry run**: Test releases without swapping

---

## Related Documentation

- [Portal Release Runbook](portal_release_runbook.md) - Usage instructions and commands (read this first)
- [Monthly Release Process](release_process.md) - Complete monthly release workflow overview
