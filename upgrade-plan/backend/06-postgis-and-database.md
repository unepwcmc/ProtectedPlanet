# 06 — PostGIS & database

| | |
|---|---|
| **Estimate** | Embedded in each Rails bump (not a standalone phase) — 1–2 wk of focused spatial testing across all phases |
| **Depends on** | Each Rails phase ([03](./03-rails-6.md), [04](./04-rails-7.md), [05](./05-rails-8.md)) |
| **Blocks** | Nothing independently — must not break spatial queries at any step |

[← Back to overview](./README.md)

---

## Goal

Spatial data correctness is non-negotiable for Protected Planet. PostGIS queries and geometry imports must work correctly at every Rails bump. This document tracks the adapter version steps and the spatial regression checklist to run at each one.

---

## Current state

| Component | Version |
|-----------|---------|
| PostgreSQL adapter | `activerecord-postgis-adapter` 5.1.0 |
| PostgreSQL gem | `pg` ~> 0.21 |
| DB schema format | SQL (`config.active_record.schema_format = :sql`) |
| PostGIS extension | On production (version unknown — check below) |
| Local dev server | **PostgreSQL 17.5 / PostGIS 3.5.2** (`db` and `db_test`, `postgis/postgis:17-3.5`) since 2026-08-24 — was 11.7 / PostGIS 2.5.4 on kartoza; see [below](#local-dev-postgresql-11--17-done-2026-08-24--every-developer-must-run-it-once) |
| CI server | PostgreSQL 17 / PostGIS 3.5 (`postgis/postgis:17-3.5`) — same image as dev |
| Staging server | PostgreSQL 17.5 / PostGIS 3.5.2 — PGDG apt packages on the host, not a container |
| Spatial models | `ProtectedArea`, `ProtectedAreaParcel`, `Country`, likely others |

---

## Adapter version map

`activerecord-postgis-adapter` majors track ActiveRecord majors/minors one-to-one:

| Rails (AR) version | PostGIS adapter version | Min Ruby |
|--------------------|-------------------------|----------|
| Rails 5.2 (current) | 5.1.0 (current) | — |
| Rails 6.0 | **7.0.x** | — |
| Rails 6.1 | **7.1.x** | — |
| Rails 7.0 | **8.x** | 2.7+ |
| Rails 7.1 | **9.x** | 3.0+ |
| Rails 7.2 | **10.x** | 3.1+ |
| Rails 8.0 | **11.0.x** | 3.2+ |
| Rails 8.1 | **11.1.x** | 3.2+ |

**Important:** The version jump from 5.x to 7.x is not a typo — the gem skipped 6.x to align with AR versioning. Check `rubygems.org/gems/activerecord-postgis-adapter` for the latest compatible version at each step.

**Final target is 11.x, not 8.x.** 8.x is the Rails **7.0** row — we pass through it (and 9.x) en route to Rails 8.

**`PostgisDatabaseTasks` was removed in 8.x.** From that step onward, the PostGIS extension is no longer created automatically by `db:create` — CI, the Docker entrypoint and any fresh-DB setup must run `CREATE EXTENSION postgis;` explicitly. Catch this at the Rails 7.0 bump, not later.

**Also upgrade `pg` from 0.21 to `~> 1.5` at the Ruby 2.7 step** — `pg` 0.21 does not compile on Ruby 3.

---

## Spatial regression checklist

Run this after every Rails bump that changes the PostGIS adapter version. Add to CI once Rails 6+ is running.

### Basic geometry

- [ ] `ProtectedArea.where("ST_Within(coordinates, ?)", some_polygon)` returns expected results
- [ ] `ProtectedArea.first.coordinates` — returns a `RGeo::Geographic` object (not nil, not a string)
- [ ] Creating a `ProtectedArea` with a geometry value round-trips correctly through `save` / `reload`
- [ ] `Country` geometry loads and can be used in spatial predicates

### Import pipeline spatial operations

- [ ] Run a test WDPA import (can use a small fixture set) — geometry population step completes without errors
- [ ] `GeometryPopulatorWorker` processes at least one record correctly
- [ ] `ProtectedAreasImporter` — geometry is persisted with correct SRID

### Download / search spatial queries

- [ ] Country PA download includes correct geometries
- [ ] Marine protected area filter returns expected results (uses `marine` boolean + spatial)
- [ ] Geo search filter (`location` in `config/search.yml`) returns results within expected bounds

### Schema

- [ ] `db/structure.sql` generates correctly after `db:migrate` (SQL schema format — must not revert to Ruby schema format)
- [ ] PostGIS extension line present in `structure.sql`
- [ ] Geometry column types preserved correctly after schema dump

---

## PostGIS server version check

Before any upgrade, confirm the PostgreSQL and PostGIS extension versions on the production DB server:

```bash
ssh wcmc@new-web.pp-production.linode.protectedplanet.net 'psql pp_production -c "SELECT version();" -c "SELECT PostGIS_Full_Version();"'
```

The PostGIS extension version on the server constrains which geometry functions are available. Upgrading the Ruby adapter does not change the server — but new adapter versions may expose new server functions; ensure the server PostGIS version supports them if any new spatial queries are added.

---

## PostgreSQL server major upgrade

The server-side move to **PG 17/18 + PostGIS 3.5/3.6** is planned as part of the infrastructure migration, since it is done *as* the server move via logical replication. Full detail: **[12 — Infrastructure migration](./12-infrastructure-migration.md)**.

What this phase owns at that point:

- [ ] Re-run the full spatial regression checklist above against the new server
- [ ] Confirm the PostGIS extension upgraded cleanly (`postgis_extensions_upgrade()`)
- [ ] Regenerate and review `db/structure.sql` on the new major — the diff is large and it is what guarantees our geometry column types

---

## Local dev: PostgreSQL 11 → 17 (done 2026-08-24 — every developer must run it once)

Local dev used to run `kartoza/postgis:11.5-2.5` (PG 11.7 / PostGIS 2.5.4) while staging runs 17.5 / PostGIS 3.5.2 — **six majors apart**. That is not a cosmetic gap: it is why the `date_part` → `extract` break reached staging with every local check green (see CARRYOVER §"three PostgreSQL majors"). `db` and `db_test` are both on 17 now, and CI already was.

Each developer has their own `protectedplanet_pg_data` volume, so **each has to do this once on their own machine**. The tooling is committed at **[`docker/pg-upgrade/`](../../docker/pg-upgrade/)** — read its README before running; this section is the summary.

```bash
# 1. stop everything that touches the database
docker compose stop db sidekiq web

# 2. back up first. The upgrade runs --copy so the old cluster survives it, but the volume
#    is still the only copy of your dev data, and this is what makes rollback possible.
#    ~7GB for an 8GB cluster; takes a few minutes.
mkdir -p ~/Documents/WCMC/pg11-preupgrade-backup
docker compose --profile upgrade run --rm \
  -v ~/Documents/WCMC/pg11-preupgrade-backup:/backup --entrypoint bash pg_upgrade \
  -c 'cd /var/lib/postgresql && tar -c -f - 11 | gzip -1 > /backup/pg11-cluster.tar.gz'

# 3. upgrade (~10 min for an 8GB cluster on the dev VM). Safe to re-run after a failure:
#    every check happens before anything is modified, and it refuses to clobber a
#    half-finished PG17 directory (delete /var/lib/postgresql/17 first if told to).
docker compose --profile upgrade run --rm pg_upgrade

# 4. the dev image needs pg_dump 17 too -- see the last gotcha below
docker compose build web
docker compose up -d
```

You do **not** need to shut Postgres down cleanly by hand first: `docker compose stop db` leaves the cluster dirty (first gotcha below) and the script detects that and recovers it itself, since it carries the PG11 binaries. Doing it via the `db` service would only work while your `db` container is still the old kartoza 11 image — `docker-compose.yml` now names `postgis/postgis:17-3.5`, so a freshly created container refuses a PG11 data directory outright.

### Why it is not a straight pg_upgrade

`pg_upgrade` carries function definitions over verbatim, so the new cluster must load the library the old catalog names — `$libdir/postgis-2.5`, which has no PG17 build (PostGIS 2.5 stops at PG12). Every PostGIS 3.x minor, though, names its library `postgis-3.so`, so the upgrade updates PostGIS to 3.3.4 **while still on PG11** and only then runs `pg_upgrade`. Both soft upgrades are supported PostGIS paths; no symlink shims.

### Gotchas, all of them hit for real

| What | Why it matters |
|---|---|
| **Your existing PG11 cluster is probably not cleanly shut down** | kartoza never forwarded SIGTERM, so docker SIGKILLed postgres after 10s and left the cluster `in production` with a stale `postmaster.pid`. `pg_upgrade` refuses that. The script recovers it automatically (`PG_UPGRADE_NO_AUTORECOVER=1` to opt out). Fixed going forward — `postgis/postgis` stops cleanly. |
| **The data directory's `postgresql.conf` / `pg_hba.conf` are incomplete** | kartoza generated its real config into `/settings` on every start, so the on-disk copies never had `listen_addresses` or a non-localhost host rule. The official image reads the data directory, so the script writes both. Without them the server looks healthy in its own logs while every other container gets "Connection refused", then "no pg_hba.conf entry". |
| **113 orphaned raster functions per database** | PostGIS 2.5 kept raster inside the `postgis` extension; the 2.5 → 3.x update *unpackages* them, leaving them bound to `$libdir/rtpostgis-2.5` with nothing owning them, so no later `ALTER EXTENSION` can fix it. The script adopts them with `CREATE EXTENSION postgis_raster FROM unpackaged` and drops that extension when no table stores a raster. |
| **1GB WAL segments** | The old cluster is not on the 16MB default, `pg_upgrade` requires a match, and kartoza's `MIN_WAL_SIZE=1024MB` is then illegal (`min_wal_size must be at least twice wal_segment_size`) so the server won't start. The script matches for the upgrade then normalises to 32MB with `pg_resetwal`. |
| **`pg_cron 1.2` must be dropped** | PG17 ships pg_cron 1.6, which has no 1.2 install script, so `pg_upgrade` refuses the cluster. It had never worked here — see the closed CARRYOVER item. |
| **The dev image's `pg_dump` is 11** | It refuses to dump a 17 server, so `rake db:migrate` fails at the schema dump *even when every migration succeeded*. PGDG has no 17 for buster (frozen at 16), so `Dockerfile` compiles the 17 client from source — no base-image change needed. |

### What you get

- `db` and `db_test` on PostgreSQL 17.5 / PostGIS 3.5.2 — staging's exact versions — same data, no reimport
- `rake db:migrate` exits 0 including the schema dump, and regenerates a **clean `structure.sql`** — mine went 341KB → 270KB with the `pg_cron` line and any `postgis-2.5` function bindings gone. Since `structure.sql` is untracked in the `db` submodule, each developer's copy differs; regenerating yours after the upgrade is the fix for stale `$libdir/postgis-2.5` references in it.
- Rollback: the backup from step 2 restores and starts — **but only under the `docker/pg-upgrade` image**, not `kartoza/postgis:11.5-2.5`, because the upgrade moved that cluster's PostGIS to 3.3. Recipe in the tooling README.

### Image choice: why `postgis/postgis`, not kartoza

Dev originally landed on `kartoza/postgis:17-3.5` simply because that is what the stack
already used for PG11. That put dev on **PostGIS 3.6.1** — the tag is mistagged, its package
is `3.6.1+dfsg-1~exp1.pgdg12+1` — leaving dev a minor *ahead* of staging and CI. Moved to the
official `postgis/postgis:17-3.5` on the same day, which ships **PostgreSQL 17.5 + PostGIS
3.5.2: staging's exact versions**, and is already what CI runs.

Since a PostGIS extension cannot be downgraded, this was not an image swap — the 17 cluster
was rebuilt from the PG11 backup against the new image. Worth knowing if the same choice comes
up again for another environment.

Three kartoza behaviours disappeared with it, all of which had cost time:

- **It never forwarded SIGTERM**, so every `docker compose stop db` SIGKILLed postgres and left
  the cluster requiring crash recovery. `postgis/postgis` stops cleanly.
- **It generated its real config into `/settings` at each start** and ignored the data
  directory's `postgresql.conf`. That makes the on-disk config quietly incomplete — no
  `listen_addresses`, no non-localhost `pg_hba` rule (its "Add rule to pg_hba: 0.0.0.0/0" log
  line was writing to the generated copy). The official image reads the data directory, so the
  upgrade script now writes both explicitly.
- **It defaulted to 1GB WAL segments**, which with `max_wal_size = 64GB` is how a dev data
  directory reached 57GB holding 8GB of data.

One thing the official image brings that kartoza did not: it declares
`VOLUME /var/lib/postgresql/data`, so docker mounts an anonymous volume over that path and
shadows the named volume mounted at the parent. Both `db` and `db_test` therefore set
`PGDATA=/var/lib/postgresql/17/main`.

---

## `structure.sql` — important note

The app uses `config.active_record.schema_format = :sql`, which generates `db/structure.sql` instead of `schema.rb`. This is correct for PostGIS (geometry types cannot be represented in Ruby schema format).

At each Rails bump:
- [ ] Run `rails db:migrate` (even if no new migrations) and check that `structure.sql` diff looks sane
- [ ] Ensure `PostGIS` extension creation line is still present
- [ ] Commit the updated `structure.sql` if it changes

---

## GDAL

`gdal ~> 2.0` (the abandoned gdal-ruby SWIG bindings) and the proprietary ESRI FileGDB driver are **being removed entirely**, not upgraded. See **[13 — GDAL & spatial tooling](./13-gdal-and-spatial-tooling.md)**.

Until that phase lands, `gdal` remains a native-extension risk at each Ruby bump ([02](./02-ruby-upgrade.md)). After it lands, the risk disappears — there is no Ruby GDAL binding left to compile.

---

## Exit criteria (across all phases)

- `activerecord-postgis-adapter` bumped correctly at each Rails step, landing on **11.x** at Rails 8
- `pg` gem on 1.x
- PostGIS extension creation handled explicitly (no `PostgisDatabaseTasks` from 8.x)
- Spatial regression checklist passes at Rails 6.1, 7.1, and 8.0
- `structure.sql` generates correctly at each step
- Spatial regression checklist re-passes on the new Postgres major ([12](./12-infrastructure-migration.md))
