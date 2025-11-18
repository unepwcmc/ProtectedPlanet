@ -1,381 +0,0 @@
# ProtectedPlanet ↔ Portal FDW Integration (macOS + Docker Desktop)

Goal
- Allow the PP database (in Docker) to read specific tables from the Portal database via PostgreSQL FDW.

Recommended topology
- Portal DB: runs on host macOS (Homebrew Postgres). Variation: Portal DB in Docker (see Variations).
- PP DB: runs in Docker, exposed on localhost:55432.

Prerequisites
- macOS with Docker Desktop installed.
- Portal DB (Postgres) running locally (Homebrew or Docker) with a read-only account:
  - CREATE ROLE portal_ro_user LOGIN PASSWORD '...';
  - Store the password in an environment variable, not inline.
- PP DB running in Docker and accessible on localhost:55432.
- Portal app DB name (for this repo): pp_data_management_backend_development.

Security notes
- Prefer scram-sha-256 for pg_hba.conf.
- Never paste secrets inline. Use environment variables like PORTAL_RO_PASSWORD and PP_DB_PASSWORD.
- In staging/prod, grant access to a specific application role, not PUBLIC.

1) Configure the Portal DB to accept connections from the PP container

1.1 Find key Postgres paths
```bash path=null start=null
# Shows exact files/paths on your machine
psql -U postgres -d postgres -Atc "SHOW hba_file; SHOW data_directory; SHOW listen_addresses;"
```

1.2 Back up pg_hba.conf
```bash path=null start=null
HBA=$(psql -U postgres -d postgres -Atc "SHOW hba_file;")
cp -a "$HBA" "${HBA}.bak-$(date +%Y%m%d-%H%M%S)"
```

1.3 Add auth rules for portal_ro_user
- Allow localhost and Docker Desktop’s bridge subnet (commonly 192.168.65.0/24 on macOS). Adjust the subnet if yours differs.
```conf path=null start=null
# Add near the top, before broader/less specific rules
host    all    portal_ro_user    127.0.0.1/32       scram-sha-256
host    all    portal_ro_user    192.168.65.0/24    scram-sha-256
```

1.4 Ensure Postgres listens on a reachable interface
- If listen_addresses is only localhost and host.docker.internal fails, set it to '*':
```bash path=null start=null
CONF=$(psql -U postgres -d postgres -Atc "SHOW config_file;")
# Edit $CONF and set: listen_addresses = '*'
```

1.5 Reload Postgres
```bash path=null start=null
# Homebrew (version may vary)
/opt/homebrew/opt/postgresql@14/bin/pg_ctl -D /opt/homebrew/var/postgresql@14 reload || \
pg_ctl -D "$(psql -U postgres -d postgres -Atc 'SHOW data_directory;')" reload

# Or via SQL
psql -U postgres -d postgres -c "SELECT pg_reload_conf();"
```

2) Create the FDW on the PP DB (Docker)

2.1 Set environment variables
```bash path=null start=null
# PP DB connection (example values)
export PP_DB_HOST=127.0.0.1
export PP_DB_PORT=55432
export PP_DB_NAME=pp_development
export PP_DB_USER=postgres
export PP_DB_PASSWORD={{PP_DB_PASSWORD}}     # e.g., 'postgres' in dev

# Portal DB connection details
export PORTAL_DB_HOST=host.docker.internal   # Portal DB on host macOS
export PORTAL_DB_PORT=5432
export PORTAL_DB_NAME=pp_data_management_backend_development
export PORTAL_RO_PASSWORD={{PORTAL_RO_PASSWORD}}
```

2.2 Create extension, server, mapping, and schema
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -X <<SQL
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

DROP SERVER IF EXISTS portal_srv CASCADE;

CREATE SERVER portal_srv
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (
    host '$PORTAL_DB_HOST',
    dbname '$PORTAL_DB_NAME',
    port '$PORTAL_DB_PORT',
    use_remote_estimate 'true',
    fetch_size '50000',
    sslmode 'prefer'                 -- change to 'require' if Portal enforces SSL
  );

-- For dev convenience; in staging/prod, use your app role instead of PUBLIC
GRANT USAGE ON FOREIGN SERVER portal_srv TO PUBLIC;

CREATE USER MAPPING IF NOT EXISTS FOR PUBLIC
  SERVER portal_srv
  OPTIONS (user 'portal_ro_user', password '$PORTAL_RO_PASSWORD');

CREATE SCHEMA IF NOT EXISTS portal_fdw;
GRANT USAGE ON SCHEMA portal_fdw TO PUBLIC;

-- Ensure future imports default to readable
ALTER DEFAULT PRIVILEGES IN SCHEMA portal_fdw GRANT SELECT ON TABLES TO PUBLIC;
SQL
```

3) Import only the tables required by Wdpa model associations
- From schema wdpa and reference.

3.1 Import wdpa schema tables
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -X <<'SQL'
IMPORT FOREIGN SCHEMA wdpa
  LIMIT TO (
    wdpas,
    spatial_data,
    character_set_cat,
    provider,
    designation_eng_cat,
    iucn_category_cat,
    designation_type_cat,
    governance_type_cat,
    realm_cat,
    no_take_cat,
    ownership_type_cat,
    site_type_cat,
    status_cat,
    verification_cat,
    data_restriction_levels,
    conservation_objective_cat,
    wdpa_governance_subtypes,
    governance_subtype_cat,
    wdpa_international_criteria,
    wdpa_iso3,
    wdpa_parent_iso3,
    wdpa_languages,
    language_cat,
    wdpa_ownership_subtypes,
    ownership_subtype_cat,
    wdpa_oecm_assessments,
    oecm_assessment_cat,
    inland_waters_cat,
    source
  )
  FROM SERVER portal_srv
  INTO portal_fdw;
SQL
```

3.2 Import reference schema tables
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -X <<'SQL'
IMPORT FOREIGN SCHEMA reference
  LIMIT TO (
    iso3,
    international_criteria_cat
  )
  FROM SERVER portal_srv
  INTO portal_fdw;

GRANT SELECT ON ALL TABLES IN SCHEMA portal_fdw TO PUBLIC;  -- dev only; restrict in prod
SQL
```

4) Verify

4.1 List imported foreign tables
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -Atc \
  "select foreign_table_schema||'.'||foreign_table_name from information_schema.foreign_tables where foreign_table_schema='portal_fdw' order by 1;"
```

4.2 Sanity counts
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -Atc \
  "SELECT 'wdpas', count(*) FROM portal_fdw.wdpas
   UNION ALL SELECT 'spatial_data', count(*) FROM portal_fdw.spatial_data
   UNION ALL SELECT 'provider', count(*) FROM portal_fdw.provider
   UNION ALL SELECT 'iso3', count(*) FROM portal_fdw.iso3;"
```

5) Final materialized views schema (contract)

portal_standard_points (public)
Filters applied:
- wdpas.archived_at IS NULL
- data_restriction_level = 'not restricted'
- ogc_fid: integer, row_number() over (site_id, site_pid)
- site_id: integer (wdpa site_id)
- site_pid: varchar(52) (parcel identifier)
- site_type: 'pa' | 'oecm'
- name_eng: varchar(254) (english_name)
- name: varchar(254) (original_name)
- desig: varchar(254) (original_designation)
- desig_eng: varchar(254) (English designation; code if catalogued, else free text)
- desig_type: varchar(20) (designation_type code)
- iucn_cat: varchar(20) (iucn_category code)
- int_crit: varchar(100) (aggregated international criteria codes)
- realm: Terrestrial | Coastal | Marine
- inlnd_wtrs: varchar(100) (inland waters code; first letter capitalized)
- rep_m_area: double precision
- rep_area: double precision
- no_take: varchar(50)
- no_tk_area: double precision
- status: varchar(100)
- status_yr: integer
- gov_type: varchar(254)
- own_type: varchar(254)
- mang_auth: varchar(254)
- mang_plan: varchar(254)
- cons_obj: varchar(100)
- supp_info: varchar(254)
- verif: varchar(20)
- metadataid: integer
- prnt_iso3: varchar(50) (aggregated parent ISO3 codes)
- iso3: varchar(50) (aggregated ISO3 codes)
- govsubtype: varchar(254) (aggregated governance_subtype codes)
- ownsubtype: varchar(254) (aggregated ownership_subtype codes)
- oecm_asmt: varchar(254) (aggregated oecm_assessment codes)
- wkb_geometry: geometry(POINT, 4326)

portal_standard_polygons (public)
Filters applied:
- wdpas.archived_at IS NULL
- data_restriction_level = 'not restricted'
- All the columns from portal_standard_points plus:
- gis_m_area: double precision (ha, conditional example)
- gis_area: double precision (ha)
- shape_length: double precision (meters)
- shape_area: double precision (m^2)
- wkb_geometry: geometry(POLYGON/MULTIPOLYGON, 4326)

6) Variations: if the Portal DB runs in Docker

Option A — Expose Portal DB to host and keep FDW host=host.docker.internal
- In the Portal docker-compose, publish a port (e.g., 5432:5432).
- Ensure in the Portal DB container:
  - listen_addresses = '*'.
  - pg_hba.conf allows the source (0.0.0.0/0 for dev or specific Docker network), using scram-sha-256.
```conf path=null start=null
host    all    portal_ro_user    0.0.0.0/0    scram-sha-256
```
- Reload inside the container:
```bash path=null start=null
docker exec -u postgres <portal_db_container> psql -U postgres -d postgres -c "SELECT pg_reload_conf();"
```

Option B — Put PP DB and Portal DB on the same Docker network
- Use a shared external network in both compose files.
- In FDW, set host to the Portal DB service name (e.g., portal-db) and port 5432.
- Update Portal DB’s pg_hba.conf to allow that network’s CIDR; reload.

Staging/Production adjustments
- Replace host.docker.internal with the real Portal DB hostname.
- Use sslmode='require' if enforced.
- Replace PUBLIC with your app role (example: pp_app):
```sql path=null start=null
GRANT USAGE ON FOREIGN SERVER portal_srv TO pp_app;
CREATE USER MAPPING IF NOT EXISTS FOR pp_app
  SERVER portal_srv
  OPTIONS (user 'portal_ro_user', password :'portal_ro_password');
GRANT USAGE ON SCHEMA portal_fdw TO pp_app;
GRANT SELECT ON ALL TABLES IN SCHEMA portal_fdw TO pp_app;
```

Maintenance: importing new tables later
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -X <<'SQL'
IMPORT FOREIGN SCHEMA wdpa
  LIMIT TO (new_table_1, new_table_2)
  FROM SERVER portal_srv
  INTO portal_fdw;

GRANT SELECT ON ALL TABLES IN SCHEMA portal_fdw TO PUBLIC;  -- or app role
SQL
```

Operations: routine update (re-import and apply updated FDW views)
- Use this when the Portal schema changes (e.g., new reference tables/columns like inland_waters_cat / inland_waters_id) or when FDW_VIEWS.sql (located in the ProtectedPlanet folder) is updated.

0) Portal DB privileges (run once, on the Portal DB)
- Ensure the read-only role can access the wdpa schema and new tables.
```bash path=null start=null
# Replace <portal_db_name> and run on the Portal DB host or container
psql -U postgres -d <portal_db_name> -X <<'SQL'
GRANT USAGE ON SCHEMA wdpa TO portal_ro_user;
GRANT SELECT ON wdpa.inland_waters_cat TO portal_ro_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA wdpa GRANT SELECT ON TABLES TO portal_ro_user;
SQL
```

1) Drop dependent MVs on PP DB (safe if absent)
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -v ON_ERROR_STOP=1 \
  -c "DROP MATERIALIZED VIEW IF EXISTS public.portal_standard_points; DROP MATERIALIZED VIEW IF EXISTS public.portal_standard_polygons; DROP MATERIALIZED VIEW IF EXISTS public.portal_standard_sources;"
```

2) Re-import updated foreign tables on PP DB
- Optionally ensure the foreign column exists before re-import (no-op if already present).
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -X <<'SQL'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'portal_fdw' AND table_name = 'wdpas' AND column_name = 'inland_waters_id'
  ) THEN
    EXECUTE 'ALTER FOREIGN TABLE portal_fdw.wdpas ADD COLUMN inland_waters_id integer';
  END IF;
END $$;

DROP FOREIGN TABLE IF EXISTS portal_fdw.wdpas CASCADE;
IMPORT FOREIGN SCHEMA wdpa LIMIT TO (wdpas) FROM SERVER portal_srv INTO portal_fdw;

DROP FOREIGN TABLE IF EXISTS portal_fdw.inland_waters_cat CASCADE;
IMPORT FOREIGN SCHEMA wdpa LIMIT TO (inland_waters_cat) FROM SERVER portal_srv INTO portal_fdw;
SQL
```

3) Apply updated materialized views (FDW_VIEWS.sql from ProtectedPlanet folder) on PP DB
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -v ON_ERROR_STOP=1 -f ../ProtectedPlanet/FDW_VIEWS.sql
```

- Docker alternative (if you prefer executing inside the DB container):
```bash path=null start=null
# Replace <pp_db_container> with your DB container name (e.g., protectedplanet-db)
docker cp ../ProtectedPlanet/FDW_VIEWS.sql <pp_db_container>:/FDW_VIEWS.sql
docker exec <pp_db_container> psql -U postgres -d pp_development -v ON_ERROR_STOP=1 -f /FDW_VIEWS.sql
```

4) Verify views and counts
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -Atc \
  "SELECT 'points', count(*) FROM portal_standard_points UNION ALL SELECT 'polys', count(*) FROM portal_standard_polygons;"
```

5) Optional: contract check from app container
```bash path=null start=null
# Replace <app_container> with your web app container (e.g., protectedplanet-web)
docker exec <app_container> bash -lc "RAILS_ENV=development ruby script/check_portal_views_contract.rb"
```

Troubleshooting
- No pg_hba.conf entry: Add appropriate host line for portal_ro_user and reload.
- Connection refused: Ensure listen_addresses includes '*', and correct host/port.
- Password authentication failed: Confirm portal_ro_user password and mapping.
- Identify Docker Desktop subnet (macOS often 192.168.65.0/24). If different, adjust pg_hba.

Cleanup (optional)
```bash path=null start=null
# Remove FDW from PP DB
PGPASSWORD="$PP_DB_PASSWORD" psql -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -X <<'SQL'
DROP SERVER IF EXISTS portal_srv CASCADE;
DROP SCHEMA IF EXISTS portal_fdw CASCADE;
SQL
```
```bash path=null start=null
# Restore original pg_hba.conf (replace the timestamp accordingly)
cp /opt/homebrew/var/postgresql@14/pg_hba.conf.bak-YYYYMMDD-HHMMSS /opt/homebrew/var/postgresql@14/pg_hba.conf
/opt/homebrew/opt/postgresql@14/bin/pg_ctl -D /opt/homebrew/var/postgresql@14 reload
```

Appendix: known-good values from this repo (dev)
- Portal DB name: pp_data_management_backend_development
- PP DB connection: 127.0.0.1:55432, db=pp_development, user=postgres
- Example Postgres (Homebrew) reload: /opt/homebrew/opt/postgresql@14/bin/pg_ctl -D /opt/homebrew/var/postgresql@14 reload
