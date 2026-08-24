#!/usr/bin/env bash
#
# In-place PostgreSQL 11 -> 17 upgrade of the dev database, PostGIS included.
#
#   docker compose stop db sidekiq web
#   docker compose --profile upgrade run --rm pg_upgrade
#
# WHY THIS WORKS AT ALL
#
# pg_upgrade copies function definitions over verbatim, so the new cluster must be able
# to load the library the old catalog names. A PostGIS 2.5 catalog names
# $libdir/postgis-2.5, and PostGIS 2.5 has no build for PG17 (it stops at PG12) -- so a
# direct 11+2.5 -> 17+3.x hop is impossible.
#
# Every PostGIS 3.x minor, however, names its library postgis-3.so. So we soft-upgrade
# PostGIS to 3.3.4 while still on PG11 (step 2 below). After that the catalog references
# postgis-3, which PG17's PostGIS 3.x provides under exactly that name, and pg_upgrade
# has nothing to complain about. A second soft upgrade on the far side (step 6) takes
# 3.3.4 -> 3.6.x. Both soft upgrades are supported PostGIS paths; no symlink shims, and
# no 57GB dump/restore.
#
# SAFETY
#
# The default is --copy, which leaves the old cluster fully intact and startable no matter
# what happens. That is normally the slow option, but it is cheap here: the 57GB data
# directory is 50GB of WAL and only ~8GB of actual data (pg_development 943MB, the stale
# pp_development_cloned_07apr26 clone 6.9GB), and WAL is not copied. Set
# PG_UPGRADE_MODE=--link if the databases have grown a lot since -- everything that can
# realistically fail (the PostGIS update, pg_upgrade --check, the schema restore) happens
# before any linking, but once linking begins the old cluster must be considered gone.
set -euo pipefail

OLD_BIN=/usr/lib/postgresql/11/bin
NEW_BIN=/usr/lib/postgresql/17/bin
OLD_DATA=/var/lib/postgresql/11/main
NEW_DATA=/var/lib/postgresql/17/main
MODE="${PG_UPGRADE_MODE:---copy}"
JOBS="${PG_UPGRADE_JOBS:-3}"
WORKDIR=/var/lib/postgresql/pg_upgrade

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1. Preflight
# ---------------------------------------------------------------------------
say "Preflight"

[ -d "$OLD_DATA" ] || die "no old data directory at $OLD_DATA -- is the volume mounted?"

old_version="$(cat "$OLD_DATA/PG_VERSION")"
[ "$old_version" = "11" ] || die "old cluster is PG $old_version, expected 11. Nothing to do, or already upgraded."

if [ -f "$NEW_DATA/PG_VERSION" ]; then
  die "$NEW_DATA already exists (PG $(cat "$NEW_DATA/PG_VERSION")). Refusing to overwrite it.
       If a previous run failed before linking, the old cluster is still fine: remove
       $NEW_DATA and re-run. If it failed *during* linking, restore from a backup instead."
fi

# pg_upgrade refuses to run as root, so everything below goes through `su postgres` -- and
# `postgres` is not the same uid it used to be. The old data was written by the buster-based
# kartoza:11.5-2.5 image, where postgres is uid 102; this image is bookworm-based, where it
# is uid 101. Without this chown the old cluster is unreadable by the very user that has to
# read it. Metadata-only, so it is quick even across the 50GB of WAL.
mkdir -p "$WORKDIR"
chown -R postgres:postgres "$WORKDIR"
chown -R postgres:postgres /var/lib/postgresql/11 || true

# pg_upgrade refuses a cluster that was not shut down cleanly, and `docker compose stop db`
# does not give you one: the kartoza entrypoint does not forward SIGTERM to postgres, so
# after 10 seconds docker SIGKILLs it and the cluster is left "in production" with a stale
# postmaster.pid. Check the control file rather than trusting the container being stopped.
cluster_state="$("$OLD_BIN/pg_controldata" -D "$OLD_DATA" | awk -F': *' '/Database cluster state/ {print $2}')"
if [ -f "$OLD_DATA/postmaster.pid" ] || [ "$cluster_state" != "shut down" ]; then
  if [ "${PG_UPGRADE_NO_AUTORECOVER:-}" = "1" ]; then
    die "old cluster was not shut down cleanly (state: ${cluster_state:-unknown}) and
         PG_UPGRADE_NO_AUTORECOVER=1. Nothing has been modified."
  fi

  # Recover it here rather than sending the operator away to do it: this image has the PG11
  # binaries, and `docker compose start db` only works for someone whose db container still
  # happens to be the old 11 image -- docker-compose.yml now names 17-3.5, so a freshly
  # created container would refuse the PG11 data directory outright.
  #
  # Starting an unclean cluster replays WAL, which is ordinary crash recovery and exactly
  # what the server does on any boot; then we stop it properly so pg_upgrade will accept it.
  say "Old cluster was not shut down cleanly (state: ${cluster_state:-unknown}) -- recovering it"
  echo "    This is expected: the kartoza entrypoint does not forward SIGTERM, so"
  echo "    \`docker compose stop db\` SIGKILLs postgres and leaves the cluster dirty."
  rm -f "$OLD_DATA/postmaster.pid"
  chown -R postgres:postgres /var/lib/postgresql/11 || true
  su postgres -c "$OLD_BIN/pg_ctl -D $OLD_DATA -l $WORKDIR/recover.log \
    -o \"-c listen_addresses='' -c unix_socket_directories=/tmp\" -w start" \
    || { cat "$WORKDIR/recover.log"; die "could not start the old cluster to recover it"; }
  su postgres -c "$OLD_BIN/pg_ctl -D $OLD_DATA -m fast -w stop"

  cluster_state="$("$OLD_BIN/pg_controldata" -D "$OLD_DATA" | awk -F': *' '/Database cluster state/ {print $2}')"
  [ "$cluster_state" = "shut down" ] || die "cluster is still '$cluster_state' after recovery; stopping here"
  echo "    recovered: cluster state is now 'shut down'"
fi

printf 'mode:          %s\njobs:          %s\nold data size: %s\nfree space:    %s\n' \
  "$MODE" "$JOBS" \
  "$(du -sh "$OLD_DATA" | cut -f1) (of which WAL: $(du -sh "$OLD_DATA/pg_wal" | cut -f1))" \
  "$(df -h /var/lib/postgresql | awk 'NR==2 {print $4}')"

# ---------------------------------------------------------------------------
# 2. PostGIS 2.5.4 -> 3.3.4, on the old PG11 cluster
# ---------------------------------------------------------------------------
say "Starting the old PG11 cluster (local socket only)"

# -c listen_addresses='' keeps this private to the container: nothing else can connect
# to a cluster that is mid-upgrade.
su postgres -c "$OLD_BIN/pg_ctl -D $OLD_DATA -l $WORKDIR/old-server.log \
  -o \"-c listen_addresses='' -c unix_socket_directories=/tmp\" -w start" \
  || { cat "$WORKDIR/old-server.log"; die "old cluster would not start"; }

psql_old() { su postgres -c "$OLD_BIN/psql -h /tmp -v ON_ERROR_STOP=1 $*"; }

databases="$(psql_old "-tAc \"select datname from pg_database where datallowconn and datname <> 'template1'\"" | tr -d '\r')"

say "Upgrading the PostGIS extension in place (PG11 side)"
for db in $databases; do
  has_postgis="$(psql_old "-d $db -tAc \"select 1 from pg_extension where extname='postgis'\"" | tr -d '\r')"
  if [ "$has_postgis" = "1" ]; then
    before="$(psql_old "-d $db -tAc \"select extversion from pg_extension where extname='postgis'\"" | tr -d '\r')"
    psql_old "-d $db -c 'ALTER EXTENSION postgis UPDATE'"
    after="$(psql_old "-d $db -tAc \"select extversion from pg_extension where extname='postgis'\"" | tr -d '\r')"
    echo "    $db: postgis $before -> $after"
  fi

  # Raster. In PostGIS 2.5 raster lived inside the `postgis` extension; 3.0 split it into
  # its own `postgis_raster`, and the 2.5 -> 3.x update above does that split by
  # *unpackaging* the raster objects -- detaching them from the extension and leaving them
  # behind as ordinary functions still bound to $libdir/rtpostgis-2.5. Nothing owns them, so
  # no later ALTER EXTENSION will ever fix them, and pg_upgrade fails on exactly this with
  # "could not load library $libdir/rtpostgis-2.5" (113 functions per database here).
  #
  # The documented way to adopt orphaned objects is CREATE EXTENSION ... FROM unpackaged,
  # which re-attaches them as postgis_raster and rebinds them to rtpostgis-3. If no table
  # actually stores a raster we then drop that extension, which removes precisely the
  # raster objects and nothing else -- much safer than hand-picking 113 functions.
  raster_fns="$(psql_old "-d $db -tAc \"select count(*) from pg_proc where probin like '%rtpostgis%'\"" | tr -d '\r')"
  if [ "${raster_fns:-0}" != "0" ]; then
    raster_cols="$(psql_old "-d $db -tAc \"
      select count(*) from pg_attribute a
      join pg_class c on c.oid = a.attrelid
      join pg_type t on t.oid = a.atttypid
      where t.typname = 'raster' and c.relkind = 'r' and not a.attisdropped\"" | tr -d '\r')"

    psql_old "-d $db -c 'CREATE EXTENSION IF NOT EXISTS postgis_raster FROM unpackaged'"
    if [ "${raster_cols:-0}" = "0" ]; then
      psql_old "-d $db -c 'DROP EXTENSION postgis_raster'"
      echo "    $db: dropped $raster_fns orphaned raster objects (no table stores a raster)"
    else
      echo "    $db: adopted $raster_fns raster objects as postgis_raster ($raster_cols raster column(s) in use)"
    fi
  fi

  # pg_cron 1.2 has to go: PG17 ships pg_cron 1.6, which has no 1.2 install script, so
  # pg_upgrade would refuse the whole cluster. It was never actually functional here --
  # not in shared_preload_libraries, no scheduled jobs, no application code using it --
  # and its presence in db/structure.sql is itself a known problem (see
  # upgrade-plan/backend/CARRYOVER.md). If you ever want it back, PG17's pg_cron.so is
  # already in the kartoza image; add it to shared_preload_libraries and CREATE EXTENSION.
  has_cron="$(psql_old "-d $db -tAc \"select 1 from pg_extension where extname='pg_cron'\"" | tr -d '\r')"
  if [ "$has_cron" = "1" ]; then
    psql_old "-d $db -c 'DROP EXTENSION pg_cron CASCADE'"
    echo "    $db: dropped pg_cron (unused, and PG17 has no 1.2 install script)"
  fi
done

say "Stopping the old cluster cleanly"
su postgres -c "$OLD_BIN/pg_ctl -D $OLD_DATA -m fast -w stop"

# ---------------------------------------------------------------------------
# 3. New PG17 cluster
# ---------------------------------------------------------------------------
say "Creating the PG17 cluster"

# Locale, encoding and superuser name must match the old cluster or pg_upgrade aborts.
# The old cluster is UTF8 / en_US.UTF-8 with lc_messages=lc_monetary=lc_numeric=lc_time=C,
# but only encoding/collate/ctype have to line up here; the rest come across with
# postgresql.conf in step 4.
# pg_upgrade also requires an identical WAL segment size, and the old cluster is not on the
# default: it was initdb'd with 1GB segments (the stock size is 16MB). That is the other
# half of the 50GB pg_wal story -- 1GB segments against max_wal_size = 64GB meant Postgres
# could sit on 64 of them. Read it off the old control file rather than hardcoding, so this
# stays correct if the old cluster is ever rebuilt differently.
wal_segsize_bytes="$("$OLD_BIN/pg_controldata" -D "$OLD_DATA" | awk -F': *' '/Bytes per WAL segment/ {print $2}')"
wal_segsize_mb=$(( wal_segsize_bytes / 1024 / 1024 ))
echo "    matching old cluster's WAL segment size: ${wal_segsize_mb}MB"

mkdir -p "$NEW_DATA"
chown -R postgres:postgres /var/lib/postgresql/17
chmod 700 "$NEW_DATA"
su postgres -c "$NEW_BIN/initdb -D $NEW_DATA \
  --username=postgres \
  --encoding=UTF8 \
  --lc-collate=en_US.UTF-8 \
  --lc-ctype=en_US.UTF-8 \
  --wal-segsize=$wal_segsize_mb"

# ---------------------------------------------------------------------------
# 4. Carry the old configuration over
# ---------------------------------------------------------------------------
say "Carrying postgresql.conf and pg_hba.conf over"

# Verified safe for this cluster: the old postgresql.conf sets only max_connections,
# shared_buffers, dynamic_shared_memory_type, max_wal_size, min_wal_size, log_timezone,
# datestyle, timezone, lc_*, default_text_search_config -- none of which were removed
# between 12 and 17. If you have since added settings, check them before trusting this.
cp "$OLD_DATA/postgresql.conf" "$NEW_DATA/postgresql.conf"

# Note this only governs the standalone starts in this script and pg_upgrade itself. At
# runtime the kartoza entrypoint ignores the config in the data directory entirely -- it
# generates /settings/postgresql.conf from its own template and starts postgres with
# `-c config_file=` pointing there, so WAL sizing and friends come from its MIN_WAL_SIZE /
# WAL_SIZE / WAL_SEGSIZE environment variables, not from anything copied here.
cp "$OLD_DATA/pg_hba.conf"     "$NEW_DATA/pg_hba.conf"
[ -f "$OLD_DATA/pg_ident.conf" ] && cp "$OLD_DATA/pg_ident.conf" "$NEW_DATA/pg_ident.conf"
chown postgres:postgres "$NEW_DATA"/*.conf

# ---------------------------------------------------------------------------
# 5. pg_upgrade
# ---------------------------------------------------------------------------
say "Running pg_upgrade --check"
su postgres -c "cd $WORKDIR && $NEW_BIN/pg_upgrade \
  -b $OLD_BIN -B $NEW_BIN -d $OLD_DATA -D $NEW_DATA \
  -o \"-c unix_socket_directories=/tmp\" -O \"-c unix_socket_directories=/tmp\" \
  --check" \
  || die "pg_upgrade --check failed. The old cluster is untouched -- 'docker compose start db'
       still works. Read the logs in $WORKDIR before retrying."

say "Running pg_upgrade $MODE (past this point the old cluster is not reusable if $MODE is --link)"
su postgres -c "cd $WORKDIR && $NEW_BIN/pg_upgrade \
  -b $OLD_BIN -B $NEW_BIN -d $OLD_DATA -D $NEW_DATA \
  -o \"-c unix_socket_directories=/tmp\" -O \"-c unix_socket_directories=/tmp\" \
  --jobs=$JOBS $MODE" \
  || die "pg_upgrade failed -- read the logs in $WORKDIR"

# ---------------------------------------------------------------------------
# 6. Normalise the WAL segment size
# ---------------------------------------------------------------------------
# The new cluster had to be initdb'd with the old cluster's 1GB WAL segments for pg_upgrade
# to accept it, but that size is unusable at runtime: the kartoza entrypoint generates its
# config with MIN_WAL_SIZE=1024MB, Postgres requires min_wal_size to be at least twice the
# segment size, and the server dies on startup with
#   FATAL: "min_wal_size" must be at least twice "wal_segment_size"
#
# 1GB segments are also half the reason the old data directory reached 57GB. pg_resetwal is
# the only way to change the size after initdb; it discards WAL, which is exactly what we
# want on a freshly upgraded, cleanly shut down cluster with nothing to replay. 32MB is the
# kartoza image's own WAL_SEGSIZE default, so this leaves the cluster identical to what a
# fresh container would have created.
say "Normalising WAL segment size to 32MB (was ${wal_segsize_mb}MB, matched only for pg_upgrade)"
su postgres -c "$NEW_BIN/pg_resetwal --wal-segsize=32 -D $NEW_DATA"

# ---------------------------------------------------------------------------
# 7. PostGIS soft upgrade on the new side, and post-upgrade hygiene
# ---------------------------------------------------------------------------
say "Starting the new PG17 cluster"
su postgres -c "$NEW_BIN/pg_ctl -D $NEW_DATA -l $WORKDIR/new-server.log \
  -o \"-c listen_addresses='' -c unix_socket_directories=/tmp\" -w start" \
  || { cat "$WORKDIR/new-server.log"; die "new cluster would not start"; }

psql_new() { su postgres -c "$NEW_BIN/psql -h /tmp -v ON_ERROR_STOP=1 $*"; }

say "Upgrading the PostGIS extension again (PG17 side, 3.3.4 -> whatever PG17 ships)"
for db in $databases; do
  has_postgis="$(psql_new "-d $db -tAc \"select 1 from pg_extension where extname='postgis'\"" | tr -d '\r')"
  if [ "$has_postgis" = "1" ]; then
    psql_new "-d $db -c 'ALTER EXTENSION postgis UPDATE'"
    echo "    $db: postgis now $(psql_new "-d $db -tAc \"select extversion from pg_extension where extname='postgis'\"" | tr -d '\r')"
  fi
done

# The data files were written by PG11 on buster (glibc 2.28) and are now served by
# bookworm (glibc 2.36). pg_upgrade carries index files over untouched, so any index whose
# ordering depends on the OS collation has to be rebuilt or it can silently return wrong
# results for text comparisons and range scans.
#
# Only collation-dependent indexes need this, which on a 57GB database is a very different
# proposition from reindexdb's rebuild-everything: the query below picks out indexes with a
# key column using a non-C collation and skips the rest. Nothing else is connected to this
# cluster right now, so plain REINDEX (which takes ACCESS EXCLUSIVE) is fine and is faster
# than REINDEX CONCURRENTLY.
COLLATION_INDEX_QUERY="
select quote_ident(n.nspname) || '.' || quote_ident(c.relname)
from pg_index i
join pg_class c on c.oid = i.indexrelid
join pg_namespace n on n.oid = c.relnamespace
where n.nspname not in ('pg_catalog', 'information_schema')
  and exists (
    select 1 from unnest(i.indcollation) as coll
    where coll <> 0
      and coll not in (select oid from pg_collation where collname in ('C', 'POSIX'))
  )
order by 1"

if [ "${PG_UPGRADE_SKIP_REINDEX:-}" = "1" ]; then
  say "Skipping REINDEX (PG_UPGRADE_SKIP_REINDEX=1)"
  echo "    Collation-dependent indexes are still built to glibc 2.28 ordering and may give"
  echo "    wrong answers for text comparisons. List them per database with:"
  echo "      psql -d DB -c \"\$COLLATION_INDEX_QUERY\""
else
  say "Reindexing collation-dependent indexes (glibc 2.28 -> 2.36)"
  for db in $databases; do
    indexes="$(psql_new "-d $db -tAc \"$COLLATION_INDEX_QUERY\"" | tr -d '\r')"
    count="$(printf '%s' "$indexes" | grep -c . || true)"
    echo "    $db: $count collation-dependent index(es)"
    for idx in $indexes; do
      su postgres -c "$NEW_BIN/psql -h /tmp -d $db -qc 'REINDEX INDEX $idx'" \
        || echo "      WARNING: REINDEX $idx failed -- rerun it by hand"
    done
  done
fi

# pg_upgrade leaves the new cluster with no statistics at all, so the first queries pick
# terrible plans. --analyze-in-stages gets usable estimates in place quickly, then refines.
say "Rebuilding planner statistics"
su postgres -c "$NEW_BIN/vacuumdb -h /tmp --all --analyze-in-stages" || true

say "Verifying"
psql_new "-tAc \"select version()\""
for db in $databases; do
  v="$(psql_new "-d $db -tAc \"select postgis_full_version()\" 2>/dev/null" | tr -d '\r' || true)"
  [ -n "$v" ] && echo "    $db: $v"
done

su postgres -c "$NEW_BIN/pg_ctl -D $NEW_DATA -m fast -w stop"

say "Done"
cat <<EOF

The PG17 cluster is at $NEW_DATA and the db service is already pointed at 17-3.5,
so:

    docker compose up -d db
    docker compose exec db psql -U postgres -d pp_development -c 'select postgis_version()'

Then, once you are satisfied everything works, reclaim the old cluster:

    docker compose --profile upgrade run --rm --entrypoint bash pg_upgrade \\
      -c 'rm -rf /var/lib/postgresql/11'

pg_upgrade also wrote a delete_old_cluster.sh into $WORKDIR that does the same thing.
That is where the disk comes back: ~50GB of it is the old cluster's pg_wal. With the
default --copy the old cluster is still startable, so there is no rush -- put the 11-vs-17
comparison to bed first, then delete it.
EOF
