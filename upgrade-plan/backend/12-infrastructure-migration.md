# 12 — Infrastructure migration — new servers & Postgres major upgrade

| | |
|---|---|
| **Estimate** | 2–3 weeks · ~0.5–0.75 month (excluding waiting time on replication catch-up) |
| **Depends on** | [11 — Docker + Kamal 2](./11-deploy-and-devops.md) · [13 — GDAL](./13-gdal-and-spatial-tooling.md) |
| **Blocks** | Nothing in the Rails path — this is the final landing step |

[← Back to overview](./README.md)

---

## Goal

Move ProtectedPlanet onto new **Ubuntu 24.04** web and database servers, and take PostgreSQL from its current major to **17 or 18** with PostGIS upgraded in step.

The two are deliberately combined: doing the Postgres major upgrade *as* the server migration, via logical replication, gets both in one reversible switch.

---

## Target shape

```
┌──────────────────────────┐        ┌──────────────────────────┐
│  web host(s)             │        │  db host                 │
│  Ubuntu 24.04            │        │  Ubuntu 24.04            │
│  Docker + Kamal 2        │───────▶│  Postgres 17/18          │
│  kamal-proxy → Puma      │        │  PostGIS 3.5/3.6         │
│  sidekiq × 2 roles       │        │  ON THE HOST, not a      │
│  cron role               │        │  container               │
│  Redis accessory         │        └──────────────────────────┘
└──────────────────────────┘
              │
              └──────────▶ Elasticsearch 7.17 (existing separate host, unchanged)
```

### Why Postgres on the host, not containerised

Nothing is gained by containerising the primary database, and `pg_upgrade`, backup tooling, PITR and disk tuning are all materially easier on the host. The web tier is where containerisation pays off.

---

## Prerequisites — facts we do not have yet

**None of this can be finalised until these are answered.** No shell access on the backend side to check.

- [ ] **Current OS** on `new-web.pp-production.linode.protectedplanet.net` and the staging equivalent — are we already on 24.04?
- [ ] **Current Postgres and PostGIS versions** in production:
  ```bash
  psql -c "SELECT version();" -c "SELECT PostGIS_Full_Version();"
  ```
  Dev pins `kartoza/postgis:11.5-2.5` (PG 11 / PostGIS 2.5) in `docker-compose.yml` — production is assumed similar but **unconfirmed**
- [ ] **Production database size** — determines the replication catch-up window
- [ ] **WDPA release cadence** — the switchover must not land mid-import
- [ ] Current `postgresql.conf` tuning, read off the live box
- [ ] Contents of `config/deploy/ansible/` — what it provisions that isn't in the app repo

---

## Host OS — Ubuntu 24.04

**24.04 LTS, not 26.04.** Reasons:

- Ships **GDAL 3.8.4** in the standard repos. That is ≥ 3.6, which is the bar for `OpenFileGDB` write support — this is what makes [13](./13-gdal-and-spatial-tooling.md) work without a source build
- ubuntugis ecosystem maturity — the PPA lags on newer releases
- PostgreSQL 17 and 18 both available via PGDG

---

## Postgres target

| Option | When to pick it |
|---|---|
| **PG 17 + PostGIS 3.5** | If the DB move happens *inside* the Rails upgrade window — avoids stacking a brand-new Postgres major under a large spatial DB at the same time as a Rails 8 migration and an adapter jump |
| **PG 18 + PostGIS 3.6** | If the infra move is its own window — the better landing spot. PostGIS 3.6.x supports PG 12–18; 3.6.2 (Feb 2026) is the version tuned for PG 18 |

Current plan sequences this **after** the Rails work, so **PG 18 + PostGIS 3.6** is the default target. Fall back to 17 if the window compresses.

The `activerecord-postgis-adapter` version is driven by Rails, not by the server — see [06](./06-postgis-and-database.md).

---

## Migration path — logical replication, not dump/restore

| Method | Downtime | Verdict |
|---|---|---|
| `pg_dump` / restore | Hours+ | **No** — not viable at our data volume; needs ~2× disk |
| `pg_upgrade --link` | Minutes | **No** — in-place on the same host, conflicts with moving to a new DB server |
| **Logical replication → blue/green switch** | Near-zero | **Yes** — combines the version bump and the server migration in one reversible operation |

### Sequence

1. Provision the new DB host: Ubuntu 24.04, PG 17/18, PostGIS 3.5/3.6
2. Port `postgresql.conf` tuning deliberately — **it does not come across automatically in any method**
3. Schema-only load onto the new host, PostGIS extension created first
4. Start logical replication from the old primary; let it catch up
5. Verify: row counts, spatial regression suite ([06](./06-postgis-and-database.md)), `PostGIS_Full_Version()`
6. Quiesce the app, confirm replication lag is zero, promote the new host
7. Repoint `POSTGRES_HOST` in Kamal secrets, redeploy
8. Keep the old primary intact and readable for the rollback window

### PostGIS extension upgrade

Run on the new host after the data lands:

```sql
ALTER EXTENSION postgis UPDATE;
SELECT postgis_extensions_upgrade();
SELECT PostGIS_Full_Version();
```

---

## `db/structure.sql`

Regenerating against a new Postgres major produces a **large, noisy diff**.

- [ ] Regenerate and review it **properly** — it is the file that guarantees our geometry column types
- [ ] Confirm the PostGIS extension line survives
- [ ] Confirm geometry column types and SRIDs are unchanged
- [ ] Do not rubber-stamp this diff

---

## What must come across (not in the app repo)

| Item | Where it lives now |
|---|---|
| `.env` — AWS keys, `POSTGRES_*`, AppSignal key, ES URL | Capistrano `linked_file` on the server |
| `config/database.yml` | Capistrano `linked_file` |
| Elasticsearch route — separate host at `192.168.176.65:9200` | Network config; ES stays 7.17 and is out of scope, but the new web hosts need reachability |
| Sidekiq queue split (`pp_default`, `pp_import`) | `capistrano-service` tasks → Kamal roles ([11](./11-deploy-and-devops.md)) |
| Ansible provisioning | `config/deploy/ansible/` |
| SSL certificates / DNS | Server config → kamal-proxy handles Let's Encrypt |
| Cron (`S3PollingWorker`, hourly) | `config/schedule.rb` → Kamal cron role ([11](./11-deploy-and-devops.md)) |
| DB git submodule | `capistrano-git-with-submodules` — confirm whether still needed under Docker |

---

## Cutover — staging first

Build and prove the entire new stack on staging before touching production.

### Staging acceptance

- [ ] New staging web + DB hosts on Ubuntu 24.04
- [ ] Kamal deploy succeeds; all roles healthy
- [ ] PG 17/18 + PostGIS 3.5/3.6 reachable; spatial regression suite passes ([06](./06-postgis-and-database.md))
- [ ] **A real WDPA import completes end to end**
- [ ] **A real `.gdb` download generates and opens correctly in ArcGIS/QGIS** — see [13](./13-gdal-and-spatial-tooling.md)
- [ ] A real shapefile and CSV download generate correctly
- [ ] CMS admin works ([09](./09-cms-comfy.md))
- [ ] Site search returns results (ES route intact)
- [ ] Cron job fires
- [ ] `kamal rollback` works

The `.gdb` download is the acceptance test to hold the whole migration against — it exercises GDAL, the FileGDB driver, PostGIS and S3 in a single path.

### Production

- [ ] Repeat the staging build
- [ ] Schedule the switchover outside the WDPA release window
- [ ] Announce a maintenance window even though downtime should be minutes
- [ ] Keep the old web and DB hosts intact for an agreed rollback period before decommissioning

---

## Exit criteria

- Web and DB hosts on Ubuntu 24.04
- Postgres 17/18 + PostGIS 3.5/3.6 in production, extension upgraded, spatial suite green
- `structure.sql` regenerated and reviewed
- Staging acceptance list passed before production cutover
- Old hosts retained through the rollback window, then decommissioned
- Runbook updated: new hosts, new deploy path, new DB upgrade procedure
