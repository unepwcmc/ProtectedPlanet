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

`activerecord-postgis-adapter` tracks ActiveRecord versions closely:

| Rails (AR) version | PostGIS adapter version |
|--------------------|-------------------------|
| Rails 5.2 (current) | 5.1.0 (current) |
| Rails 6.0 | **7.0.x** |
| Rails 6.1 | **7.1.x** |
| Rails 7.0 | **8.0.x** |
| Rails 7.1 | **8.0.x** (same) |
| Rails 8.0 | **8.0.x** or 9.x if released |

**Important:** The version jump from 5.x to 7.x is not a typo — the gem skipped 6.x to align with AR versioning. Check `rubygems.org/gems/activerecord-postgis-adapter` for the latest compatible version at each step.

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

Before any upgrade, confirm the PostGIS extension version on the production DB server:

```bash
ssh wcmc@new-web.pp-production.linode.protectedplanet.net \
  'psql pp_production -c "SELECT PostGIS_Full_Version();"'
```

The PostGIS extension version on the server constrains which geometry functions are available. Upgrading the Ruby adapter does not change the server — but new adapter versions may expose new server functions; ensure the server PostGIS version supports them if any new spatial queries are added.

---

## `structure.sql` — important note

The app uses `config.active_record.schema_format = :sql`, which generates `db/structure.sql` instead of `schema.rb`. This is correct for PostGIS (geometry types cannot be represented in Ruby schema format).

At each Rails bump:
- [ ] Run `rails db:migrate` (even if no new migrations) and check that `structure.sql` diff looks sane
- [ ] Ensure `PostGIS` extension creation line is still present
- [ ] Commit the updated `structure.sql` if it changes

---

## GDAL native extension

`gdal ~> 2.0` is a native extension used in geometry / shapefile processing. At each Ruby version bump:

- [ ] Confirm `gem install gdal` compiles against the system GDAL library
- [ ] Check production server GDAL version: `gdalinfo --version`
- [ ] If GDAL 2.x gem does not compile on Ruby 3.x, investigate `ffi-gdal` or the maintained `gdal` gem fork

---

## Exit criteria (across all phases)

- `activerecord-postgis-adapter` bumped correctly at each Rails step
- `pg` gem on 1.x
- Spatial regression checklist passes at Rails 6.1, 7.1, and 8.0
- `structure.sql` generates correctly at each step
- GDAL compiles on Ruby 3.3
