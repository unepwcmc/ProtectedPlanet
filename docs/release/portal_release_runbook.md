# ProtectedPlanet Portal Release Runbook

> For code-level details, see [Release Orchestration](release_orchestration.md)

Step-by-step instructions for running a monthly data release.

---

## Release Timing

- Dry run before the monthly go-live date.
- Go live (swap tables) on the **1st of each month**.
- If the 1st is a **Friday**, dry run before Thursday and go live **Thursday** instead — leaves Thu/Fri for data fixes. (Agreed with Conservation Team)

---

## Prerequisites

- SSH access to the server + membership of its `docker` group (app runs in a container, deployed via Kamal)
- Local dev only: Docker + docker compose
- FDW configured to Portal DB with views created/validated
- DB credentials in `.env` / shell environment

**Local dev only:**
```bash
docker compose up -d db redis elasticsearch webpacker web
```

---

## Essential Commands

| Task | Command |
|------|---------|
| ⭐ Release with dry run (recommended) | [Dry Run Workflow](#dry-run-workflow) |
| Release (automatic) | [Direct Release](#direct-release) |
| Check status | `bundle exec rake pp:portal:status` |
| Abort release | `bundle exec rake pp:portal:abort` |
| Rollback | `bundle exec rake pp:portal:rollback["2509121644"]` |

Run these inside the web container, e.g. one-off from the host: `docker exec -it "$WEB" bash -lc 'bundle exec rake pp:portal:abort'` (local dev: `docker compose exec -T web bash -lc '...'`).

> **Deploys are blocked while a release runs.** Kamal's pre-build/pre-deploy hooks run `rake pp:portal:deploy_gate` and fail closed — a deploy can't kill a release mid-phase. No override; wait for the release or `rake pp:portal:abort` first.

> **Release label is required**, format `MMMYYYY` (e.g. `Nov2025`). Commands fail without it.

---

## What Happens During a Release

Lock → Preflight → Build Staging → Import → Validate → Swap (creates automatic backups) → Cleanup (search index, caches) — all automatic, no need to run phases individually.

---

<a id="dry-run-workflow"></a>
## Dry Run Workflow (Recommended)

Lets you inspect staging data and choose exactly when to swap.

```bash
# --- on the host ---
ssh xxxxx@xxxxx                               # ask devops for user/host
tmux kill-session -t pp-release 2>/dev/null   # clear any stale session
tmux new -s pp-release                         # ON THE HOST not inside docker container bash

WEB=$(docker ps -q --filter label=service=protectedplanet --filter label=role=web | head -1)
docker exec -it "$WEB" bash                    # after triggering this command you are now inside the container, at /app

# --- inside the container ---
PP_RELEASE_DRY_RUN=true bundle exec rake 'pp:portal:release[Sep2026]'

# Detach: Ctrl-b then d   (release keeps running; reattach later with `tmux attach -t pp-release`)
```

> **tmux goes on the HOST, not in the container.** `docker exec -it` ties the process to your SSH TTY — if your session drops, bash gets SIGHUP and kills the release. A host tmux session survives that. (The container image has no tmux anyway.)

> **Never set `RAILS_ENV` by hand.** It's already correct. Setting it to `production` inside staging keeps staging's host/user/password but swaps in `pp_production` as the database name (per `config/database.yml`) — best case it fails to connect, worst case it points a table-swapping release at prod.

Once it stops at `validating`, check status and inspect the staging tables (`staging_protected_areas`, `staging_sources`, etc.):

```bash
bundle exec rake pp:portal:status
# {"id":14,"label":"Apr2026","state":"validating", ...}
```

When ready to go live (same label!):

```bash
PP_RELEASE_START_AT=finalise_swap bundle exec rake 'pp:portal:release[Sep2026]'

# Detach: Ctrl-b then d   (release keeps running; reattach later with `tmux attach -t pp-release`)

# Wait for it to complete and successful messages you should see on Slack are Release MMMYYYY succeeded and reset_checkpoints complete in 0.0s — Reset portal checkpoints for next release
```

**Notes:**
- Swap also takes the release lock — if it says `Another release is running`, check `rake pp:portal:status` / `rake pp:portal:abort` first.
- Staging tables persist until you swap; dry run stops itself after validation.
- **Deploys are NOT blocked while a dry run is parked** — the gate only detects a *running* process, and the dry run releases its lock when it stops. See warning below.
- If the release is killed mid-phase (OOM, restart), nothing is corrupted — the `Release` row stays non-terminal and the Postgres advisory lock releases with the session. Run `pp:portal:abort`, then resume with `PP_RELEASE_START_AT`. You only lose the in-flight phase.

> **⚠️ Deploying between dry run and swap.** Staging tables/checkpoints live in the DB, so a routine deploy in this window is generally safe. Check first:
> 1. **Migration touching WDPA tables?** `pre-deploy` runs `db:migrate` — staging was built on the old schema. If in doubt, abort and re-run the dry run after deploying.
> 2. **Deploy changes release/swap code** (`app/services/portal_release/`, `lib/modules/wdpa/portal/`)? Prefer swapping first, or re-run the dry run after.
>
> Everything else (CMS, frontend, unrelated app code) is safe to deploy in this window. Once the swap starts, the lock/gate protects it again.

✅ Done when you see the **Congratulations** message in Slack.

<a id="direct-release"></a>
## Direct Release (Automatic)

Same as above but skips the inspection step — swaps immediately:

```bash
# --- on the host ---
ssh xxxxx@xxxxx                               # ask devops for user/host
tmux kill-session -t pp-release 2>/dev/null   # clear any stale session
tmux new -s pp-release                         # ON THE HOST not inside docker container bash

WEB=$(docker ps -q --filter label=service=protectedplanet --filter label=role=web | head -1)
docker exec -it "$WEB" bash                    # after triggering this command you are now inside the container, at /app

# --- inside the container ---
bundle exec rake 'pp:portal:release[Sep2026]'

# Detach: Ctrl-b then d   (release keeps running; reattach later with `tmux attach -t pp-release`)

# Wait for it to complete and successful messages you should see on Slack are Release MMMYYYY succeeded and reset_checkpoints complete in 0.0s — Reset portal checkpoints for next release
```

> **tmux goes on the HOST, not in the container.** `docker exec -it` ties the process to your SSH TTY — if your session drops, bash gets SIGHUP and kills the release. A host tmux session survives that. (The container image has no tmux anyway.)

> **Never set `RAILS_ENV` by hand.** It's already correct. Setting it to `production` inside staging keeps staging's host/user/password but swaps in `pp_production` as the database name (per `config/database.yml`) — best case it fails to connect, worst case it points a table-swapping release at prod.

When done: `exit` back to the host, then `tmux kill-session -t pp-release`.

---

## Rollback

Blocked while a release is running.

```bash
bundle exec rake pp:portal:list_backups
bundle exec rake 'pp:portal:rollback[2511241422]'

# Current tables become staging tables — fix issues, then re-swap:
PP_RELEASE_START_AT=finalise_swap bundle exec rake 'pp:portal:release[Nov2025]'
# or start fresh — stale staging tables are cleared automatically.
```

---

## Monitoring

All updates post to Slack `#pp-release` (requires `PP_SLACK_WEBHOOK_URL`).

```bash
bundle exec rake pp:portal:status
```

### Logs — four places, different content

| Where | Content |
|---|---|
| tmux/stdout | rake output + all `Rails.logger` importer detail (counts, soft errors). On the server (`RAILS_LOG_TO_STDOUT=1`) this is the **only** place importer detail goes. |
| `log/portal_release.log` | structured phase/event JSON only |
| DB: `release_events` | audit trail |
| DB: `releases.stats_json` | full importer result hash, incl. `soft_errors` |

Tee stdout so it isn't lost to scrollback:
```bash
PP_RELEASE_DRY_RUN=true bundle exec rake 'pp:portal:release[Sep2026]' 2>&1 | tee log/release_Sep2026.out
```

Query results after the fact:
```ruby
r = Release.find_by(label: 'Sep2026')
r.stats_json.dig('importer', 'protected_areas', 'protected_areas_attributes', 'soft_errors')
r.stats_json['checkpoints']   # should be empty after a clean run
```

> **Log files are ephemeral** — lost on next deploy. Copy out before deploying: `docker cp "$WEB":/app/log/portal_release.log .`. Slack and the `release_events`/`releases` tables are the durable record.

> `docker logs "$WEB"` shows puma (PID 1), not your `docker exec` rake process.

### Check Results

- Status: `bundle exec rake pp:portal:status`
- Manifest: `public/manifests/<LABEL>.json`
- Release record: `Release.last`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Required portal views missing" | Check FDW connection + portal views exist |
| "Invalid geometry" / SRID ≠ 4326 | Fix upstream view geometry; must be EPSG:4326 |
| "Duplicate rows by (site_id, site_pid)" | Enforce `DISTINCT ON` upstream |
| "checkpoint … does not match key" | View's batch key columns changed mid-release. `pp:portal:abort` and restart — checkpoints alone won't re-import existing staging rows. |
| Importer errors | Check logs |
| zsh bracket expansion errors | Quote rake args: `rake task['arg']` |
| "timestamp not found" | `pp:portal:list_backups` for valid timestamps |
| Release stuck/failed | `pp:portal:abort`, then check logs |

See [Release Orchestration](release_orchestration.md) for more.

---

## Advanced Options

```bash
# Lightweight staging (faster, for testing)
PP_RELEASE_DRY_RUN=true \
PP_RELEASE_STAGING_LIGHTWEIGHT=true \
PP_RELEASE_CREATE_STAGING_MATERIALIZED_VIEWS=false \
bundle exec rake 'pp:portal:release[Feb2026]'

# Resume from a phase (same label as the dry run)
PP_RELEASE_START_AT=finalise_swap bundle exec rake 'pp:portal:release[Nov2025]'

# Run only specific phases
PP_RELEASE_ONLY_PHASES=create_staging_materialized_views,preflight bundle exec rake 'pp:portal:release[Sep2025]'
```

| Variable | Description |
|----------|-------------|
| `PP_RELEASE_DRY_RUN` | Stop after validation (before swap) |
| `PP_RELEASE_START_AT` | Phase to start at |
| `PP_RELEASE_STOP_AFTER` | Phase to stop after |
| `PP_RELEASE_STAGING_LIGHTWEIGHT` | Disable indexes during staging (faster) |
| `PP_STATS_SOURCE` | `csv` (default) or `db` — see [Stats Server DB Ingestion](../stats_server_db_ingestion.md) |

Full list: [Release Orchestration](release_orchestration.md#configuration).

---

## Related Docs

- [Monthly Release Process](release_process.md)
- [Release Orchestration](release_orchestration.md)

---

> Always quote the whole rake task arg — `rake 'pp:portal:release[Aug2026]'`. In zsh, unquoted `[...]` is a glob and fails; in the container's bash it silently passes through only when nothing matches.
