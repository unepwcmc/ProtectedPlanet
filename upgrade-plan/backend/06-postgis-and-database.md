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

The dev stack pins `kartoza/postgis:11.5-2.5` (PG 11 / PostGIS 2.5) in `docker-compose.yml`; the production version is **unconfirmed** — run the check above.

The server-side move to **PG 17/18 + PostGIS 3.5/3.6** is planned as part of the infrastructure migration, since it is done *as* the server move via logical replication. Full detail: **[12 — Infrastructure migration](./12-infrastructure-migration.md)**.

What this phase owns at that point:

- [ ] Re-run the full spatial regression checklist above against the new server
- [ ] Confirm the PostGIS extension upgraded cleanly (`postgis_extensions_upgrade()`)
- [ ] Regenerate and review `db/structure.sql` on the new major — the diff is large and it is what guarantees our geometry column types

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
