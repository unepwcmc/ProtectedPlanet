# ProtectedPlanet Portal Release Runbook

> **A guide for developers** - For code-level technical details, see [Release Orchestration](release_orchestration.md)

This guide provides step-by-step instructions for running a monthly data release. It covers the commands you need and workflows to follow.

---

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

| Task | Command |
|------|------------|
| **⭐ Run release with dry run (Recommended)** | [See Dry Run section](#run-a-dry-run) |
| **Run release (Automatic)** |  [See Automatic release section](#running-an-auto-release) |
| **Check status** | `bundle exec rake pp:portal:status` |
| **Abort release** | `bundle exec rake pp:portal:abort` |
| **Rollback** | `bundle exec rake pp:portal:rollback["2509121644"]` |

> ** To run commands locally please see examples below
> - (Outside docker) ``docker compose exec -T web bash -lc 'bundle exec rake pp:portal:abort'``
> - (Inside docker) ``bundle exec rake pp:portal:abort``

> **⚠️ Important**: The release label is **REQUIRED** for all `pp:portal:release` commands. Format: `MMMYYYY` (e.g., `Nov2025`, `Jan2026`). The task will fail with an error if the label is not provided.

---

## 📋 What Happens During a Release

A release goes through several phases automatically:

1. **Lock** - Ensures only one release runs at a time
2. **Preflight** - Validates data before importing
3. **Build Staging** - Creates temporary tables for new data
4. **Import** - Imports new data from Portal
5. **Validate** - Checks data quality and creates manifest
6. **Swap** - Makes new data live (creates automatic backups)
7. **Cleanup** - Updates search index and clears caches

You don't need to run these phases individually - the release command handles everything automatically.

---

<a id="run-a-dry-run"></a>
## 🛠️ Running a Release

### Recommended: Dry Run Workflow

> **⭐ Recommended**: Use a dry run to prepare staging tables ahead of time. This allows you to:
> - Inspect staging data before making it live
> - Prepare staging tables in advance and swap on a specific date (e.g., first day of the month)
> - Verify data quality before the swap

Long-running releases should be run in a persistent terminal session so they keep running if your SSH connection drops.

```bash
# Start a named tmux session
tmux new -s pp-release

# Step 1: Dry run (stops after validation, does not swap tables)
RAILS_ENV=production PP_RELEASE_DRY_RUN=true bundle exec rake pp:portal:release["Feb2026"]

# Detach without stopping the process
Ctrl-b then d

# Reattach later
tmux attach -t pp-release
```

After the dry run completes, the staging tables are ready. You can then:

```bash
# Check the release status
RAILS_ENV=production bundle exec rake pp:portal:status

# And then inspect staging tables in the database to verify data looks correct. Check `staging_protected_areas`, `staging_sources` tables, etc...

# When ready to go live** (e.g., on the first day of the month), continue with the swap:
# IMPORTANT! Make sure you change the correct label
RAILS_ENV=production PP_RELEASE_START_AT=finalise_swap bundle exec rake pp:portal:release["Feb2026"]
```

**Important Notes:**
- Use the **same release label** that was used in the dry run
- The dry run stops automatically after validation completes
- Staging tables remain in the database until you run the swap
- Resuming from `finalise_swap` will perform the actual swap and continue with remaining phases

<a id="running-an-auto-release"></a>
### Alternative: Direct Release (Automatic)

If you want to run the entire release automatically:

```bash
# Start a named tmux session
tmux new -s pp-release

# Direct release (swaps tables immediately - no inspection step)
RAILS_ENV=production bundle exec rake pp:portal:release["Dec2025"]

# Detach without stopping the process
# Press: Ctrl-b then d

# Reattach later
tmux attach -t pp-release
```

> **⚠️ Note**: This approach skips the inspection step.


---

## 🔄 Rollback

If something goes wrong after a release, you can rollback to a previous version.

**⚠️ Safety**: Rollback is blocked if a release is currently running.

```bash
# List available backup timestamps
bundle exec rake pp:portal:list_backups

# Rollback to specific timestamp
bundle exec rake pp:portal:rollback["2511241422"]

# After rolling back, the current tables become staging tables. You can then fix any issues and run the release again from the swap phase:
RAILS_ENV=production PP_RELEASE_START_AT=finalise_swap bundle exec rake pp:portal:release["Nov2025"]

# Or you can start from fresh again and you don't need to clear out all staging tables as they will be removed by the system if you start fresh.
``` 

---

## 🔍 Monitoring

> **💬 Slack Updates**: All release updates are posted to the `#pp-release` Slack channel. Monitor this channel to see real-time progress, phase completions, and any notifications during the release.

### Check Release Status

```bash
# Production
bundle exec rake pp:portal:status

# Local Development
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'
```

### View Logs

```bash
# Production
tail -n 100 -f log/portal_release.log

# Local Development
docker compose exec -T web bash -lc 'tail -n 100 -f log/portal_release.log'
```

### Enable Slack Notifications

All release notifications are posted to the `#pp-release` Slack channel.

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

**Note**: If `PP_SLACK_WEBHOOK_URL` is not set, notifications will not be sent.

### Check Results

- **Status**: `bundle exec rake pp:portal:status`
- **Manifest**: `public/manifests/<LABEL>.json`
- **Release record**: Rails console or DB (`Release.last`)
- **Logs**: Container stdout and `log/portal_release.log`

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **"Required portal views missing"** | Ensure FDW is connected and portal views exist |
| **"Invalid geometry" or SRID ≠ 4326** | Fix upstream view geometry; must be valid and EPSG:4326 |
| **"Duplicate rows by (site_id, site_pid)"** | Check points/polygons logic; enforce DISTINCT ON upstream |
| **Importer errors** | Check logs for specific error details |
| **zsh bracket expansion errors** | Always quote rake arguments: `rake task['arg']` |
| **"timestamp not found"** | Use `pp:portal:list_backups` to see available timestamps |
| **Release stuck or failed** | Use `pp:portal:abort` to clean up, then check logs |

For advanced troubleshooting and technical details, see [Release Orchestration](release_orchestration.md).

---

## 🔧 Advanced Options

### Development & Testing

```bash
# Dry run with lightweight staging (faster for testing)
PP_RELEASE_DRY_RUN=true \
PP_RELEASE_STAGING_LIGHTWEIGHT=true \
PP_RELEASE_CREATE_STAGING_MATERIALIZED_VIEWS=false \
bundle exec rake pp:portal:release["Feb2026"]

# Resume from specific phase (after dry run - use SAME label as dry run)
PP_RELEASE_START_AT=finalise_swap bundle exec rake pp:portal:release["Nov2025"]

# Run only specific phases
PP_RELEASE_ONLY_PHASES=create_staging_materialized_views,preflight bundle exec rake pp:portal:release["Sep2025"]
```

### Environment Variables

Common environment variables you might need:

| Variable | Description |
|----------|-------------|
| `PP_RELEASE_DRY_RUN` | Stop after validation (before swap) |
| `PP_RELEASE_START_AT` | Phase to start at |
| `PP_RELEASE_STOP_AFTER` | Phase to stop after |
| `PP_RELEASE_STAGING_LIGHTWEIGHT` | Disable indexes during staging (faster) |

> For complete list of environment variables and configuration options, see [Release Orchestration](release_orchestration.md#configuration).

---

## 📚 Related Documentation

- [Monthly Release Process](release_process.md) - Overview of the complete monthly release workflow
- [Release Orchestration](release_orchestration.md) - Technical reference with code details

---

> **Note**: In zsh, always quote arguments with brackets or env values to avoid shell expansion.
