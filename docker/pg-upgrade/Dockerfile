# One-off image for the in-place PostgreSQL 11 -> 17 upgrade of the dev database.
#
# Based on the SAME image that serves the database afterwards (postgis/postgis:17-3.5), so
# the new cluster is initdb'd by exactly the binaries and glibc that will read it from then
# on -- no second collation hop after the upgrade.
#
# That base is the official PostGIS image, which ships **PostgreSQL 17.5 + PostGIS 3.5.2 --
# staging's exact versions**. The dev stack used kartoza/postgis before; its `17-3.5` tag is
# mistagged and actually installs PostGIS 3.6.1, which put dev a minor ahead of both staging
# and CI. It also has awkward habits: it never forwards SIGTERM (so `docker compose stop db`
# leaves the cluster dirty), it ignores the data directory's postgresql.conf in favour of one
# it generates into /settings, and it defaults to 1GB WAL segments.
#
# The PG11 server binaries come from bullseye-pgdg, whose apt source this base already
# configures. postgresql-11-postgis-3 is the load-bearing package: it provides PostGIS 3.3.4
# *for PostgreSQL 11*, including postgis--2.5.4--3.3.4.sql. That lets the PostGIS soft upgrade
# happen while still on PG11, which is what makes the whole thing possible -- see upgrade.sh.
FROM postgis/postgis:17-3.5

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      postgresql-11 \
      postgresql-11-postgis-3 \
 && rm -rf /var/lib/apt/lists/*

COPY upgrade.sh /usr/local/bin/pg-upgrade
RUN chmod +x /usr/local/bin/pg-upgrade

ENTRYPOINT ["/usr/local/bin/pg-upgrade"]
