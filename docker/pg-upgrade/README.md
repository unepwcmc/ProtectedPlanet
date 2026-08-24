# Upgrading your local database: PostgreSQL 11 → 17

**TL;DR** — local dev used to run PostgreSQL 11.7 / PostGIS 2.5.4 while staging runs 17.5 /
PostGIS 3.5.2. Everyone has to upgrade their own database once. It takes about 10 minutes
and does not reimport your data.

Do it when you pull a branch where `docker-compose.yml` names `kartoza/postgis:17-3.5` and
your `db` container refuses to start with **"incompatible data directory"**. That error means
your volume still holds a PG11 cluster.

## Run this

```bash
docker compose stop db sidekiq web

# Back up first. The upgrade keeps the old cluster, but your volume is the only copy
# of your dev data. ~7GB, a few minutes.
mkdir -p ~/pg11-preupgrade-backup
docker compose --profile upgrade run --rm \
  -v ~/pg11-preupgrade-backup:/backup --entrypoint bash pg_upgrade \
  -c 'cd /var/lib/postgresql && tar -c -f - 11 | gzip -1 > /backup/pg11-cluster.tar.gz'

docker compose --profile upgrade run --rm pg_upgrade   # the upgrade itself

docker compose build web                               # the app image needs pg_dump 17
docker compose up -d
```

Then check it worked:

```bash
docker compose exec -u postgres db psql -d pp_development \
  -c 'select version()' -c 'select postgis_version()'

# in the container, like every bundle/rake command in this project
docker compose exec web bash -lc 'bundle exec rake db:migrate'   # must exit 0, schema dump included
```

`rake db:migrate` will rewrite your `db/structure.sql`, dropping the `pg_cron` line and any
`$libdir/postgis-2.5` function bindings. That is expected and wanted — the file is untracked
in the `db` submodule, so it is yours alone.

**Safe to re-run.** Everything that can fail is checked before anything is modified, and it
refuses to overwrite a half-finished PG17 directory (delete `/var/lib/postgresql/17` and
re-run if it tells you to).

## Why it is not just `pg_upgrade`

`pg_upgrade` copies function definitions over verbatim, so PG17 has to load the library the
old catalog names — `$libdir/postgis-2.5`, which has no PG17 build (PostGIS 2.5 stops at
PG12). But every PostGIS 3.x names its library `postgis-3.so`, so the script updates PostGIS
to **3.3.4 while still on PG11**, and only then upgrades Postgres. Both steps are supported
PostGIS paths — no symlink shims, no 57GB dump and reload.

That is why this directory builds its own image: `kartoza/postgis:17-3.5` plus PG11 binaries
and PostGIS 3.3 for PG11, so both majors are present in one container.

## Things that will surprise you

| | |
|---|---|
| `docker compose stop db` **does not** shut Postgres down cleanly | kartoza's entrypoint never forwards SIGTERM, so docker SIGKILLs it and the cluster is left dirty. The script recovers it for you. It also means your dev database routinely crash-recovers on start. |
| 113 raster functions block the upgrade | PostGIS 3 detaches raster from the `postgis` extension and orphans it. Handled automatically. |
| `pg_cron` gets dropped | PG17 ships pg_cron 1.6 and has no 1.2 install script. It never worked here anyway — not preloaded, no jobs, no code using it. |
| Your `pg_wal` may be enormous | Mine was 50GB of a 57GB data directory. The upgrade normalises the WAL settings, so expect to get most of that back. |
| The dev image's `pg_dump` was 11 | It refuses to dump a 17 server, so `rake db:migrate` failed at the schema dump even when the migrations succeeded. Hence `docker compose build web`. |
| This VM has ~1.5GB RAM | Running a second cluster alongside the stack OOM-killed elasticsearch and took everything down. Keep `web sidekiq vite elasticsearch kibana` stopped while working on the database. |

## If you need to go back to 11

Your backup tarball restores and starts — **but only under this directory's image**, not
`kartoza/postgis:11.5-2.5`. The upgrade moved that cluster's PostGIS to 3.3, so its catalog
references `postgis-3.so`, which the 2.5 image does not have. This is the main reason to keep
this tooling around.

```bash
docker compose stop db sidekiq web

# put the old cluster back (PG17's cluster lives at /var/lib/postgresql/17 and is untouched)
docker compose --profile upgrade run --rm \
  -v ~/pg11-preupgrade-backup:/backup --entrypoint bash pg_upgrade \
  -c 'cd /var/lib/postgresql && tar -xzf /backup/pg11-cluster.tar.gz && chown -R postgres:postgres 11'

# start PG11 by hand, since this image's entrypoint is the upgrade script
docker compose --profile upgrade run --rm --service-ports --entrypoint bash pg_upgrade -c '
  su postgres -c "/usr/lib/postgresql/11/bin/pg_ctl -D /var/lib/postgresql/11/main \
    -o \"-c listen_addresses=* -c unix_socket_directories=/tmp\" -w start"
  sleep infinity'
```

Verified end to end: restored, started on 11.22 / PostGIS 3.3, all three databases intact.
(The backup taken during the original 2026-08-24 upgrade is at
`~/Documents/WCMC/pg11-preupgrade-backup/`, with an `.md5` beside it.)

## Reclaiming space when you are happy

The upgrade runs `--copy`, so the PG11 cluster survives as a complete, startable cluster.
Once PG17 has been exercised:

```bash
docker compose --profile upgrade run --rm --entrypoint bash pg_upgrade \
  -c 'rm -rf /var/lib/postgresql/11'
```

## Knobs

| Variable | Default | |
|---|---|---|
| `PG_UPGRADE_MODE` | `--copy` | `--link` hard-links instead: much faster on a big cluster, but the old cluster is unusable afterwards |
| `PG_UPGRADE_JOBS` | `3` | parallelism for pg_upgrade and reindexing |
| `PG_UPGRADE_SKIP_REINDEX` | unset | skip the glibc-collation reindex (see `upgrade.sh`) |
| `PG_UPGRADE_NO_AUTORECOVER` | unset | fail instead of recovering a dirty cluster |

## More detail

- [`upgrade.sh`](./upgrade.sh) — every step is commented with why it is there
- [Plan: 06 — PostGIS & database](../../upgrade-plan/backend/06-postgis-and-database.md) —
  where this sits in the backend upgrade, the spatial regression checklist, and the open
  question of dev being on PostGIS 3.6.1 while CI is on 3.5.x
