# ProtectedPlanet Portal Release Runbook

> **A guide for developers** - For code-level technical details, see [Release Orchestration](release_orchestration.md)

This guide provides step-by-step instructions for running a monthly data release. It covers the commands you need and workflows to follow.

---


## Release Timing

- Run the dry run before the monthly go-live date.
- Standard timing: go live (swap tables) on the **1st day of each month**.
- Exception: if the **1st falls on a Friday**, complete the dry run before Thursday and go live on **Thursday (the day before)**. This gives Thursday and Friday for any data fixes, if needed. (Agreed with NC Team)

---

## 🚀 Quick Start

### Prerequisites

- **Server**: the app containers are running (deployed with Kamal). You need SSH
  access to the server and membership of its `docker` group.
- **Local Development**: Docker and docker compose installed
- FDW configured to Portal DB with views created/validated
- Database credentials in `.env` or shell environment

### Getting a shell where you can run release commands

The app no longer runs directly on the server — it runs inside a container, so
every `rake pp:portal:*` command has to be run **inside the web container**.

```bash
# 1. SSH to the server, find out the current username and host from devops
ssh xxxxx@xxxxxx

# 2. Start a tmux session ON THE HOST (see the warning below — this order matters)
tmux new -s pp-release

# 3. Open a shell inside the running web container
WEB=$(docker ps -q --filter label=service=protectedplanet --filter label=role=web | head -1)
docker exec -it "$WEB" bash

# If several destinations share the host, narrow it:
#   --filter label=destination=staging
# Or just run `docker ps` and pick the web container by name.
```

You are now inside the container, at `/app`, with all the app's environment
variables already set. Run the release commands from here.

> **⚠️ tmux belongs on the HOST, not inside the container.** `docker exec -it`
> gives your rake process a TTY owned by your SSH session: when the SSH session
> ends (you `exit`, your laptop sleeps, the wifi drops), the terminal is hung up,
> bash gets `SIGHUP`, and it kills the release with it. A tmux server started on
> the host is a child of the host's init, so hanging up your terminal never
> reaches it. The container image has no `tmux` installed anyway.

> **⚠️ Never set `RAILS_ENV` by hand inside the container.** The container already
> has the right value (`staging` on staging). Overriding it to `production` does
> **not** just change a label: `config/database.yml`'s `production:` block
> hardcodes `database: pp_production`, while `staging:` reads `POSTGRES_DBNAME`
> from the environment. So `RAILS_ENV=production` inside the staging container
> keeps the staging host/user/password but swaps the database name — at best the
> release fails to connect, at worst it points a table-swapping release at the
> production database.

### Start Local Services (Local Development Only)

```bash
# From repo root (local development only)
docker compose up -d db redis elasticsearch webpacker web
docker compose ps  # Check status
```

### Essential Commands

| Task | Command |
|------|------------|
| **⭐ Run release with dry run (Recommended, Current method for monthly release as of Dec2025)** | [See Dry Run section](#run-a-dry-run) |
| **Run release (Automatic)** |  [See Automatic release section](#running-an-auto-release) |
| **Check status** | `bundle exec rake pp:portal:status` |
| **Abort release** | `bundle exec rake pp:portal:abort` |
| **Rollback** | `bundle exec rake pp:portal:rollback["2509121644"]` |

> **Where to run these.** All of them run *inside* a container:
> - (On the server, already inside the web container) ``bundle exec rake pp:portal:abort``
> - (On the server, one-off from the host) ``docker exec -it "$WEB" bash -lc 'bundle exec rake pp:portal:abort'``
> - (Local development) ``docker compose exec -T web bash -lc 'bundle exec rake pp:portal:abort'``

> **⚠️ Deploys are blocked while a release runs.** `.kamal/hooks/pre-deploy` runs
> `rake pp:portal:deploy_gate` and aborts the deploy if a release holds the release lock.
> Without it, `kamal deploy` replaces the app containers and kills the release mid-phase —
> the process is SIGKILLed, so the release is left stranded with no Slack error.
> There is no override — wait for the release to finish, or abort it with
> `rake pp:portal:abort` before deploying.

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

A release runs for hours, so it must not be tied to your SSH session. Start tmux
on the host **before** stepping into the container (see
[Getting a shell](#getting-a-shell-where-you-can-run-release-commands)).

```bash
# --- on the server, OUTSIDE the container ---
ssh xxxxx@xxxxx

# Kill any old pp-release session if existing
tmux kill-session -t pp-release
# Start a named tmux session
tmux new -s pp-release

# Step into the web container
WEB=$(docker ps -q --filter label=service=protectedplanet --filter label=role=web | head -1)
docker exec -it "$WEB" bash

# --- from here on, INSIDE the container ---

# Step 1: Dry run (stops after validation, does not swap tables), can do this as
# soon as NC completes all drafts approval on all needed data.
# Do NOT set RAILS_ENV — the container already has it right.
PP_RELEASE_DRY_RUN=true bundle exec rake 'pp:portal:release[Sep2026]'

# Detach without stopping the process (this detaches the HOST tmux session,
# leaving both the container shell and the release running)
Ctrl-b then d

# Reattach later — ssh back to the server first, then:
tmux attach -t pp-release
```

After the dry run completes, the staging tables are ready. You can then:

```bash
# All of the below run INSIDE the web container.

# Check the release status
bundle exec rake pp:portal:status

# This is something you would see. It says it is stopped/completed at validating stage/state
{"id":14,"label":"Apr2026","state":"validating","created_at":"2026-03-26T14:21:32.343Z","updated_at":"2026-03-26T17:25:18.350Z","manifest_url":"/manifests/14_Apr2026.json"}


# And then inspect staging tables in the database to verify data looks correct. Check `staging_protected_areas`, `staging_sources` tables, etc...

# When ready to go live** (normally on the first day of the month), continue with the swap:
# If the first day is a Friday, run this on Thursday instead (see Monthly Release Date Rule above)
# IMPORTANT! Make sure you change the correct label
PP_RELEASE_START_AT=finalise_swap bundle exec rake 'pp:portal:release[Sep2026]'


# When everything is done: leave the container, then kill the HOST tmux session
# so the next release starts fresh
exit                              # back to the host
tmux kill-session -t pp-release
```
 
**Important Notes:**
- The swap step now takes the release lock too, so it will refuse to start with
  `Another release is running` if the dry-run process is somehow still alive, or if a
  colleague is mid-release. Check with `rake pp:portal:status` and wait, or
  `rake pp:portal:abort`, before retrying.
- Use the **same release label** that was used in the dry run
- The dry run stops automatically after validation completes
- Staging tables remain in the database until you run the swap
- Resuming from `finalise_swap` will perform the actual swap and continue with remaining phases
- **Deploys are NOT blocked while a dry run is parked.** The deploy gate only
  detects a *running* release process, so the window between the dry run finishing
  and you starting the swap is wide open. See the warning below before letting a
  deploy go out in that window.
- If the release is killed mid-phase (container restart, OOM, a deploy that got
  past the gate), nothing is corrupted: the `Release` row is left in a
  non-terminal state and the Postgres advisory lock is released with the session.
  Run `rake pp:portal:abort` to clean up, then resume with `PP_RELEASE_START_AT`.
  You lose the phase that was in flight, not the whole release.

> ### ⚠️ Deploying between the dry run and the swap
>
> A parked dry run does **not** block deployments, and this is by design — there is
> no release process running for a deploy to kill. `.kamal/hooks/pre-deploy` asks
> `rake pp:portal:deploy_gate`, which only reports "a release is running" while the
> long-lived rake process holds the Postgres advisory lock. The dry run releases that
> lock when it stops, so the gate says "No release running" and the deploy proceeds.
>
> A routine deploy in this window is fine. Your staging tables and checkpoints live in
> the database (checkpoints are in `releases.stats_json`), so they survive containers
> being replaced, and `PP_RELEASE_START_AT=finalise_swap` resumes normally afterwards.
>
> **Two things to check before you let one through:**
>
> 1. **Does the deploy carry a migration that touches the WDPA tables?**
>    `pre-deploy` runs `db:migrate` right after the gate. Your staging tables were
>    built against the *old* schema, so the swap would put a stale-schema table live.
>    If in doubt, `rake pp:portal:abort` and re-run the dry run after the deploy.
> 2. **Does the deploy change the release/swap code itself?**
>    (`app/services/portal_release/`, `lib/modules/wdpa/portal/`). Staging was built
>    by the old image; the swap would run from the new one. Prefer to swap first, or
>    re-run the dry run after deploying.
>
> Everything else — CMS, front-end, unrelated app code — is safe to deploy while a
> dry run is parked. And once you start the swap, the gate does its job again: the
> swap phase takes the lock, so a deploy launched during it is blocked.

### ✅ Once You see Congragulations xxxx message on slack then you have completed a monthly release using dry run method! If you are looking for direct release read below
<br>
<br>
<a id="running-an-auto-release"></a>

### Alternative: Direct Release (Automatic)

If you want to run the entire release automatically:

```bash
# --- on the server, OUTSIDE the container ---
ssh xxxx@xxxxxx

# Kill any old pp-release session if existing
tmux kill-session -t pp-release
# Start a named tmux session
tmux new -s pp-release

# Step into the web container
WEB=$(docker ps -q --filter label=service=protectedplanet --filter label=role=web | head -1)
docker exec -it "$WEB" bash

# --- INSIDE the container ---
# Direct release (swaps tables immediately - no inspection step)
bundle exec rake 'pp:portal:release[May2026]'

# Detach without stopping the process
# Press: Ctrl-b then d

# Reattach later if needed — ssh back to the server, then:
tmux attach -t pp-release

# When done: exit the container, then kill the session so the next release
# starts fresh
exit
tmux kill-session -t pp-release
```

### ✅ Once You see Congragulations xxxx message on slack then you have completed a monthly release

> **⚠️ Note**: This approach skips the inspection step.

<a id="dedicated-release-container"></a>
### Advanced: run the release in its own container (long production releases)

`docker exec` runs the release inside the **live web container**, sharing a memory
cgroup with Puma. That is fine on staging and for dry runs. For a long production
release against a site under real traffic, an import spike can trigger the OOM
killer in that container and take the site down along with the release.

To isolate it, start the release as its own detached container from the same
image. It carries none of Kamal's `service`/`role`/`destination` labels, so
`kamal deploy` cannot stop it — and the pre-deploy gate still blocks deploys
anyway, because it reads the advisory lock rather than the process table.

```bash
# --- on the server, OUTSIDE the container ---
WEB=$(docker ps -q --filter label=service=protectedplanet --filter label=role=web | head -1)
IMAGE=$(docker inspect -f '{{.Config.Image}}' "$WEB")
ENVFILE=$(ls ~/.kamal/apps/*/env/roles/*web*.env | head -1)   # confirm this path exists

docker run -d --name pp-release-aug2026 \
  --add-host host.docker.internal:host-gateway \
  --env-file "$ENVFILE" \
  -e PP_RELEASE_DRY_RUN=true \
  -v /data/pp-imports:/app/tmp/imports \
  "$IMAGE" \
  bundle exec rake 'pp:portal:release[Aug2026]'

# Follow it. Ctrl-C only stops the tail, never the release.
docker logs -f pp-release-aug2026
```

Notes:
- `docker run -d` is already detached from your SSH session, so tmux is optional
  here — use it only if you want the `docker logs -f` tail to survive a drop.
- No `--rm`: the container's logs outlive the run, so a failure is still readable
  afterwards. `docker rm pp-release-aug2026` once you are done — that replaces
  "kill the tmux session".
- For the swap, run the same command with a new `--name`, without
  `PP_RELEASE_DRY_RUN`, and with `-e PP_RELEASE_START_AT=finalise_swap`.


---

## 🔄 Rollback

If something goes wrong after a release, you can rollback to a previous version.

**⚠️ Safety**: Rollback is blocked if a release is currently running.

```bash
# All of these run INSIDE the web container.

# List available backup timestamps
bundle exec rake pp:portal:list_backups

# Rollback to specific timestamp
bundle exec rake 'pp:portal:rollback[2511241422]'

# After rolling back, the current tables become staging tables. You can then fix any issues and run the release again from the swap phase:
PP_RELEASE_START_AT=finalise_swap bundle exec rake 'pp:portal:release[Nov2025]'

# Or you can start from fresh again and you don't need to clear out all staging tables as they will be removed by the system if you start fresh.
``` 

---

## 🔍 Monitoring

> **💬 Slack Updates**: All release updates are posted to the `#pp-release` Slack channel. Monitor this channel to see real-time progress, phase completions, and any notifications during the release.

### Check Release Status

```bash
# On the server, inside the web container
bundle exec rake pp:portal:status

# On the server, one-off from the host
docker exec -it "$WEB" bash -lc 'bundle exec rake pp:portal:status'

# Local Development
docker compose exec -T web bash -lc 'bundle exec rake pp:portal:status'
```

### View Logs

```bash
# On the server, inside the web container
tail -n 100 -f log/portal_release.log

# On the server, one-off from the host
docker exec -it "$WEB" bash -lc 'tail -n 100 -f log/portal_release.log'

# Local Development
docker compose exec -T web bash -lc 'tail -n 100 -f log/portal_release.log'
```

> **⚠️ `log/portal_release.log` lives inside the container and is ephemeral.** It
> is lost when the container is replaced by the next deploy — so copy anything you
> need for a post-mortem out to the host (`docker cp "$WEB":/app/log/portal_release.log .`)
> before deploying. Slack (`#pp-release`) and `docker logs` are the durable record.

### Enable Slack Notifications

All release notifications are posted to the `#pp-release` Slack channel.

```bash
# On the server: PP_SLACK_WEBHOOK_URL is already set in the container by Kamal
# (config/deploy.yml `env.secret`). Only set these to change the defaults:
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
bundle exec rake 'pp:portal:release[Feb2026]'

# Resume from specific phase (after dry run - use SAME label as dry run)
PP_RELEASE_START_AT=finalise_swap bundle exec rake 'pp:portal:release[Nov2025]'

# Run only specific phases
PP_RELEASE_ONLY_PHASES=create_staging_materialized_views,preflight bundle exec rake 'pp:portal:release[Sep2025]'
```

### Environment Variables

Common environment variables you might need:

| Variable | Description |
|----------|-------------|
| `PP_RELEASE_DRY_RUN` | Stop after validation (before swap) |
| `PP_RELEASE_START_AT` | Phase to start at |
| `PP_RELEASE_STOP_AFTER` | Phase to stop after |
| `PP_RELEASE_STAGING_LIGHTWEIGHT` | Disable indexes during staging (faster) |
| `PP_STATS_SOURCE` | `csv` (default) or `db` — where the release imports national/PAME/global stats from. See [Stats Server DB Ingestion](../stats_server_db_ingestion.md) |

> For complete list of environment variables and configuration options, see [Release Orchestration](release_orchestration.md#configuration).

---

## 📚 Related Documentation

- [Monthly Release Process](release_process.md) - Overview of the complete monthly release workflow
- [Release Orchestration](release_orchestration.md) - Technical reference with code details

---

> **Note**: Always quote the whole rake task argument — `rake 'pp:portal:release[Aug2026]'`
> — rather than just the label. In zsh `[...]` is a glob and fails outright; in the
> container's bash it silently passes through only while nothing happens to match.
