# Step 3: Release Orchestration (Portal-backed)

## Status: Scaffolding implemented

This step coordinates a full release cycle using Step 2 importers to populate staging tables, performs preflight checks, writes a manifest, and (placeholder) prepares for atomic swap (Step 4).

## What’s included

- Orchestrator service and phases: `PortalRelease::Service`
- Advisory lock to prevent concurrent runs
- Preflight checks against Portal views (existence, counts, geometry validity, duplicates)
- Staging prep via Step 2’s `StagingTableManager`
- Import core via Step 2 `Wdpa::Portal::Importer`
- Validation + manifest writer
- Rake tasks: `pp:portal:release`, `pp:portal:abort`, `pp:portal:rollback`, `pp:portal:status`
- Audit trail models and events (`Release`, `ReleaseEvent`) + migrations
- Swap manager placeholder (actual atomic rename in Step 4)

## How to run

```bash
# Optional: refresh MVs during preflight
export PP_RELEASE_REFRESH_VIEWS=true

# Start a release
rake pp:portal:release['WDPA_YYYY_MM']

# Show status
rake pp:portal:status

# Abort (drops staging tables, no swap performed)
rake pp:portal:abort

# Rollback (no-op until Step 4 implements swap)
rake pp:portal:rollback
```

## Phases

1. acquire_lock: Single-run guard (pg advisory lock)
2. refresh_views: Optional concurrent refresh of `portal_standard_*`
3. preflight: Contract checks, counts, geometry validity, duplicates
4. build_staging: Recreate `staging_*` tables from live structure
5. import_core: Calls `Wdpa::Portal::Importer.import` to fill staging
6. import_related: Placeholder (Step 2 already imports related sets)
7. validate_and_manifest: Basic sanity checks + write manifest JSON under `public/manifests/`
8. finalise_swap: Placeholder (Step 4)
9. post_swap: ANALYZE and cache cleanup
10. cleanup_and_retention: Retention placeholder + success notification

## Configuration

- `PP_RELEASE_REFRESH_VIEWS=true` to refresh Portal materialized views in preflight
- `PP_SLACK_WEBHOOK_URL` to enable Slack notifications (optional)

## Next (Step 4)

- Implement `PortalRelease::SwapManager` to atomically rename `staging_* → live`, with rollback.
- Add retention and prev snapshots policy.

## Notes

- Counts between views and staging won’t be 1:1 due to parcel collapsing; validation checks for non-zero imports and geometry presence.
- All code is non-destructive until Step 4; swap/rollback are no-ops.

