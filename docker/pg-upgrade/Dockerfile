# One-off image for the in-place PostgreSQL 11 -> 17 upgrade of the dev database.
#
# Based on the SAME image that serves the database afterwards (kartoza/postgis:17-3.5),
# so the new cluster is initdb'd by exactly the binaries and glibc that will read it
# from then on -- no second collation hop after the upgrade.
#
# The PG11 server binaries come from bookworm-pgdg, whose apt source the kartoza image
# already configures. postgresql-11-postgis-3 is the load-bearing package: it provides
# PostGIS 3.3.4 *for PostgreSQL 11*, including postgis--2.5.4--3.3.4.sql. That lets the
# PostGIS soft upgrade happen while still on PG11, which is what makes the whole thing
# possible -- see upgrade.sh for why.
FROM kartoza/postgis:17-3.5

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      postgresql-11 \
      postgresql-11-postgis-3 \
 && rm -rf /var/lib/apt/lists/*

COPY upgrade.sh /usr/local/bin/pg-upgrade
RUN chmod +x /usr/local/bin/pg-upgrade

ENTRYPOINT ["/usr/local/bin/pg-upgrade"]
