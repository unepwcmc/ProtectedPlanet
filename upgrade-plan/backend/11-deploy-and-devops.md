# 11 — Deploy & DevOps — Docker + Kamal 2 (B2, B5)

| | |
|---|---|
| **Estimate** | 3–4 weeks · ~0.75–1 month (replaces the previous 1–2 wk Capistrano-refresh scope) |
| **Depends on** | [04 — Rails 7.1 (B0)](./04-rails-7.md) · [02 — Ruby upgrade](./02-ruby-upgrade.md) · **[13 — GDAL](./13-gdal-and-spatial-tooling.md) (hard prerequisite)** |
| **Blocks** | **B2** (staging deploy with `vite build`) · **B5** (Webpacker removed from deploy) · [12 — Infrastructure](./12-infrastructure-migration.md) |

[← Back to overview](./README.md)

---

## Goal

Replace Capistrano with **production Docker images deployed by Kamal 2**. Kill Ruby-via-rvm and Node-via-nvm drift on the servers, and get identical GDAL in dev, CI and production.

---

## Decision — Docker + Kamal 2, not Capistrano 3.18

The earlier version of this phase planned a Capistrano refresh (3.11 → 3.18, Node 20 via nvm, Ruby via rvm). That is superseded.

| | Capistrano refresh | **Docker + Kamal 2** |
|---|---|---|
| Ruby / Node on server | rvm + nvm, drifts | Baked into the image |
| GDAL version | Differs dev vs prod — **currently a live source of spatial-output differences** | Identical everywhere |
| App server | Passenger | Puma behind kamal-proxy |
| Rollback | Release symlink | Image tag |
| Multi-app per host | nginx vhosts by hand | kamal-proxy handles it (PP + PP-API can share a box) |

Kamal 2 (currently 2.12.x) covers the Capistrano feature set we actually use: zero-downtime deploys, rolling restarts, rollbacks.

**No blocking reason not to do this.** There are four things that must be designed in, below — one of which is a genuine prerequisite.

---

## Starting point — we are not at zero

The repo already has a **dev** `Dockerfile` and `docker-compose.yml`. They are not production-grade:

| Current dev image | Problem |
|---|---|
| `FROM ruby:2.6.3` | EOL |
| Debian buster via `archive.debian.org` with `Check-Valid-Until "0"` | EOL distro, unverified package dates |
| Node 12 from nodesource | EOL |
| **GDAL 2.2.3 built from source + ESRI FileGDB SDK** | The blocker — see [13](./13-gdal-and-spatial-tooling.md) |
| `bundler 2.4.22` | Bumped from 1.17.3 during the Rails 6.0 step; 2.5+ needs Ruby 3.0 |
| `webpacker` service | Removed at B5 |

So this phase is "make production-grade images and adopt Kamal", not greenfield.

---

## Prerequisite — GDAL / FileGDB

**Do not treat dockerization as a packaging exercise.** Our `.gdb` downloads depend on a proprietary ESRI driver compiled into a from-source GDAL 2.2.3 build, which will not build on Ubuntu 24.04 / gcc 13.

That work is its own phase: **[13 — GDAL & spatial tooling](./13-gdal-and-spatial-tooling.md)**. It must land before the production image can be built. It is the single largest piece of work hiding inside "dockerize the project".

---

## Step 1 — Production Dockerfile

- [ ] Multi-stage build: builder (native ext compilation) → slim runtime
- [ ] Base on a Ruby 3.3 image on a **modern Debian/Ubuntu base** (see [12](./12-infrastructure-migration.md) for host OS)
- [ ] Install **distro GDAL** (`gdal-bin`, `libgdal-dev`) — no source build, no ESRI SDK (requires [13](./13-gdal-and-spatial-tooling.md))
- [ ] `libgeos-dev`, `libproj-dev`, `libpq-dev` for the spatial/DB stack
- [ ] Node 20 LTS + yarn for the asset build
- [ ] `zip` — shelled out to by `Download::Generators::Gdb` and `lib/modules/shapefile.rb`
- [ ] Puppeteer/Chromium deps — only in the image that needs them; keep them out of the web image if possible
- [ ] `bundle install --deployment`, then `bin/vite build` at image build time (B2)
- [ ] Non-root runtime user
- [ ] Confirm the image builds on both `linux/amd64` and Apple Silicon (dev currently forces `platform: linux/x86_64`)

---

## Step 2 — Kamal roles

| Role | Command | Notes |
|---|---|---|
| `web` | Puma | Behind kamal-proxy |
| `worker_default` | `sidekiq -q pp_default` | Replaces the `pp_default` service |
| `worker_import` | `sidekiq -q pp_import` | Replaces the `pp_import` service; **needs the tmp volume** (Step 4) |
| `cron` | supercronic | Replaces `whenever` — see Step 5 |

Accessories: Redis. **Postgres and Elasticsearch stay on their own hosts** — do not make them Kamal accessories, see [12](./12-infrastructure-migration.md).

- [ ] `config/deploy.yml` written with the roles above
- [ ] Secrets via `.kamal/secrets` — sourced from the existing `.env` (currently a Capistrano `linked_file`)
- [ ] Registry decided (GHCR under `unepwcmc`, or Docker Hub) and credentials provisioned
- [ ] Healthcheck endpoint confirmed — kamal-proxy holds traffic on the old container until it passes

---

## Step 3 — Passenger → Puma

Passenger (via `capistrano-passenger`) is the current app server. A Puma config exists but is passive.

- [ ] Activate and tune `config/puma.rb` — workers and threads
- [ ] **Load test download generation** — it is long-running and blocking, so thread counts matter more than usual here
- [ ] Confirm request timeouts at kamal-proxy do not cut off large download responses
- [ ] Remove `capistrano-passenger`

---

## Step 4 — Import disk and volumes

The WDPA pipeline writes **multi-GB** shapefiles and zips to `tmp` before uploading to S3 (`lib/modules/download.rb`, `Download::Generators::*`, `lib/modules/countries_geometries_importer.rb`).

- [ ] Mount a **sized host volume at `tmp`** on the import worker role — container overlay storage is not adequate
- [ ] Size it against the largest full WDPA release plus headroom for concurrent downloads
- [ ] Confirm cleanup (`Download.clean_up`) actually runs in the container lifecycle
- [ ] **ActiveStorage needs no volume** — already S3 in staging and production (`config/storage.yml`)

---

## Step 5 — Cron

`config/schedule.rb` (whenever) runs `S3PollingWorker` hourly on the `:util` role. **Kamal has no cron primitive** — this silently disappears if nobody designs it in.

- [ ] Choose: dedicated `cron` role container running supercronic, **or** move the schedule to `sidekiq-cron`
- [ ] Recommendation: `sidekiq-cron` — one fewer role, and the job is already a Sidekiq worker
- [ ] Remove the `whenever` gem and `config/schedule.rb` once migrated

---

## Step 6 — Migrations

Kamal does not run migrations as part of the deploy the way Capistrano did. A failed migration mid-deploy leaves a partially migrated database.

- [ ] Run migrations **explicitly before the traffic swap** (`kamal app exec`), not as a deploy hook
- [ ] Update the deploy runbook to make this an explicit step
- [ ] For large/locking migrations on the spatial tables, plan them separately — see [06](./06-postgis-and-database.md)

---

## Step 7 — Vite build (B2)

Under Kamal, `bin/vite build` moves **into the image build** rather than being a deploy-time step on the server.

**B2 is satisfied when:** the staging image is built with `bin/vite build` and the built assets are served correctly.

- [ ] `NODE_ENV=production` set at image build time
- [ ] `VITE_*` build args available during the image build (Mapbox token, etc.) — these are build-time, not runtime, so they must be passed as build args and **must not be baked as secrets into a public image layer**
- [ ] `public/vite/manifest.json` present in the final image
- [ ] Test rollback: `kamal rollback` — previous image tag serves the matching manifest
- [ ] Document the dual-compile period (Webpacker + Vite) — both build until B5

---

## Step 8 — Webpacker removal (B5)

B5 is shared with the frontend team. Do not remove Webpacker until the frontend Vite cutover is complete.

- [ ] Coordinate with frontend: confirm all `javascript_pack_tag` / `stylesheet_pack_tag` removed from ERB
- [ ] Remove `gem 'webpacker'` from the Gemfile
- [ ] Remove the webpacker stage from the Dockerfile and the `webpacker` service from `docker-compose.yml`
- [ ] Delete `config/webpacker.yml` and `docker/scripts/webpacker`
- [ ] Remove Webpacker env vars (`WEBPACKER_DEV_SERVER_HOST`)
- [ ] Deploy to staging — confirm no Webpacker-related errors
- [ ] Tag B5

---

## Step 9 — Capistrano removal

Only after a Kamal staging deploy is proven. **Keep Capistrano working until then** — do not delete it as the first step.

- [ ] Remove all `capistrano*` gems from the Gemfile
- [ ] Delete `config/deploy.rb` and `config/deploy/{production,staging}.rb`
- [ ] Preserve anything still needed from `config/deploy/ansible/` — see [12](./12-infrastructure-migration.md)
- [ ] Update the deploy runbook

---

## Dev environment

`docker-compose.yml` stays for local dev and follows the same base image:

- [ ] Rebase on the new production base image
- [ ] Bump `kartoza/postgis:11.5-2.5` to match the production Postgres target — see [12](./12-infrastructure-migration.md)
- [ ] Drop the `webpacker` service at B5
- [ ] Keep the `api` and `mailpit` profiles as-is

---

## AppSignal

- [ ] Upgrade `appsignal` to `~> 4.x` before Rails 8 (3.x has no Rails 8 support)
- [ ] Confirm the AppSignal agent works inside the container (it needs the extension compiled at bundle time)
- [ ] Move the agent key from `.env` into Kamal secrets

---

## Environment variables reference

Currently supplied via the `.env` Capistrano `linked_file`. These move into Kamal secrets / env:

| Variable | Purpose | Change |
|----------|---------|--------|
| `POSTGRES_HOST` / `_USER` / `_PASSWORD` / `_DBNAME` | DB | **Host changes** — see [12](./12-infrastructure-migration.md) |
| `ELASTIC_SEARCH_URL` | ES client | Currently `http://192.168.176.65:9200` — separate host, stays 7.17; new web hosts need the network route |
| `REDIS_URL` | Sidekiq | Points at the Kamal Redis accessory |
| `NODE_ENV` | Vite build | `production`, build-time |
| `VITE_*` | Frontend build-time vars | **Build args, not runtime env** |
| `RAILS_MASTER_KEY` | Credentials | Added after [04](./04-rails-7.md) |
| AWS keys / `s3_region` / buckets | ActiveStorage + downloads | Move to Kamal secrets |

---

## Sequencing

Do this **after B0 (Rails 7.1)**. Dockerizing on Ruby 2.6 / Rails 5.2 means building the image twice.

```
B0 (Rails 7.1) ──▶ [13 GDAL] ──▶ [11 Docker + Kamal] ──▶ [12 New servers + Postgres]
                                        │
                          Capistrano stays live until here ──┘
```

---

## Exit criteria

- Production-grade Docker image builds with distro GDAL and no ESRI SDK
- Kamal 2 deploys to **staging**: web, both worker roles, cron
- Puma load-tested against download generation
- `bin/vite build` in the image; staging serves built assets (B2 ✓)
- Cron job migrated off `whenever` and verified firing
- Webpacker removed from image and Gemfile (B5 ✓)
- Capistrano removed **only after** a production Kamal deploy is proven
- Deploy runbook rewritten: image build, explicit migration step, `kamal deploy`, `kamal rollback`
