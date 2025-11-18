# ProtectedPlanet ↔ Portal FDW Integration (Production)

Goal
- Allow the PP database to read specific tables from the Portal database via PostgreSQL FDW.

Prerequisites
- Portal DB (Postgres) running with a read-only account:
  - CREATE ROLE portal_ro_user LOGIN PASSWORD '...';
  - Store the password in an environment variable, not inline.
- PP DB accessible with appropriate permissions.
- Network connectivity between PP DB and Portal DB.

Security notes
- Prefer scram-sha-256 for pg_hba.conf.
- Never paste secrets inline. Use environment variables like PORTAL_RO_PASSWORD and PP_DB_PASSWORD.
- In staging/prod, grant access to a specific application role, not PUBLIC.
- Use sslmode='require' in production to enforce SSL.

1) Configure the Portal DB to accept connections from PP DB

1.1 Configure Portal DB authentication
- Ensure Portal DB's `pg_hba.conf` allows connections from PP DB network.
- Use specific network CIDR, NOT 0.0.0.0/0 in production.
- Use scram-sha-256 authentication method.

```conf path=null start=null
# Add appropriate host line for portal_ro_user from PP DB network
# Replace <pp_db_network_cidr> with the actual network CIDR of your PP DB
host    all    portal_ro_user    <pp_db_network_cidr>    scram-sha-256
```

1.2 Ensure Postgres listens on a reachable interface
- Configure `listen_addresses` in `postgresql.conf` to allow connections from PP DB.
- Reload PostgreSQL configuration after changes.

1.3 Grant Portal DB schema permissions (CRITICAL - must be done before FDW setup)
- **IMPORTANT**: Run these commands on Portal DB, not on PP Database.
- This must be completed before importing foreign tables, otherwise queries will fail with permission errors.

```bash path=null start=null
# Replace <portal_db_name> and <port> as needed
psql -U postgres -p <port> -d <portal_db_name> -X <<'SQL'
-- First, verify which schemas exist
SELECT schema_name FROM information_schema.schemata 
WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast') 
ORDER BY schema_name;

-- Then grant permissions (adjust schema names based on what exists - commonly 'wdpa' and 'reference')
GRANT USAGE ON SCHEMA wdpa TO portal_ro_user;
GRANT USAGE ON SCHEMA reference TO portal_ro_user;
GRANT SELECT ON ALL TABLES IN SCHEMA wdpa TO portal_ro_user;
GRANT SELECT ON ALL TABLES IN SCHEMA reference TO portal_ro_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA wdpa GRANT SELECT ON TABLES TO portal_ro_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA reference GRANT SELECT ON TABLES TO portal_ro_user;

-- Set connection limit for portal_ro_user (recommended for production)
ALTER ROLE portal_ro_user CONNECTION LIMIT 10;
SQL
```

2) Create the FDW on the PP DB

**Prerequisites:**
- Ensure `portal_srv_read` role exists in PP DB (create with `CREATE ROLE portal_srv_read LOGIN;` if needed)
- Ensure `portal_ro_user` role exists in Portal DB and permissions are granted (see step 1.3 above)

**Connection details:**
- Replace `<pp_db_host>`, `<pp_db_port>`, `<pp_db_name>`, `<pp_db_user>`, and `<pp_db_password>` with your PP DB connection details
- Replace `<portal_db_host>`, `<portal_db_port>`, and `<portal_db_name>` with your Portal DB connection details
- Replace `<portal_ro_password>` with the portal_ro_user password

**Complete FDW setup script:**
```bash path=null start=null
# Connect to PP DB and set up FDW extension, server, mappings, and import foreign tables
PGPASSWORD='<pp_db_password>' psql -h <pp_db_host> -p <pp_db_port> -U <pp_db_user> -d <pp_db_name> <<'SQL'
-- Enable PostgreSQL Foreign Data Wrapper extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create portal_srv_read role if not exists
CREATE ROLE portal_srv_read LOGIN;

-- Remove existing server if present (cleanup)
DROP SERVER IF EXISTS portal_srv CASCADE;

-- Create foreign server pointing to Portal DB
CREATE SERVER portal_srv
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (
    host '<portal_db_host>',
    dbname '<portal_db_name>',
    port '<portal_db_port>',
    use_remote_estimate 'true',
    fetch_size '50000',
    sslmode 'require'                 -- SECURITY: Use 'require' in production to enforce SSL
  );

-- Grant permission to use the foreign server
GRANT USAGE ON FOREIGN SERVER portal_srv TO portal_srv_read;

-- Map portal_srv_read role to portal_ro_user on Portal DB
CREATE USER MAPPING IF NOT EXISTS FOR portal_srv_read
  SERVER portal_srv
  OPTIONS (user 'portal_ro_user', password '<portal_ro_password>');

-- Create schema for foreign tables
CREATE SCHEMA IF NOT EXISTS portal_fdw;

-- Grant schema usage and create permissions
GRANT USAGE ON SCHEMA portal_fdw TO portal_srv_read;
GRANT CREATE ON SCHEMA portal_fdw TO portal_srv_read;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA portal_fdw GRANT SELECT ON TABLES TO portal_srv_read;

-- Switch to portal_srv_read role (required for IMPORT)
SET ROLE portal_srv_read;

-- Import wdpa schema tables
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

-- Import reference schema tables
IMPORT FOREIGN SCHEMA reference
  LIMIT TO (
    iso3,
    international_criteria_cat
  )
  FROM SERVER portal_srv
  INTO portal_fdw;

-- Grant SELECT permission on all imported foreign tables
GRANT SELECT ON ALL TABLES IN SCHEMA portal_fdw TO portal_srv_read;
SQL
```

3) Verify

3.1 List imported foreign tables
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -Atc \
  "select foreign_table_schema||'.'||foreign_table_name from information_schema.foreign_tables where foreign_table_schema='portal_fdw' order by 1;"
```

3.2 Sanity counts
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -Atc \
  "SELECT 'wdpas', count(*) FROM portal_fdw.wdpas
   UNION ALL SELECT 'spatial_data', count(*) FROM portal_fdw.spatial_data
   UNION ALL SELECT 'provider', count(*) FROM portal_fdw.provider
   UNION ALL SELECT 'iso3', count(*) FROM portal_fdw.iso3;"
```

4) Materialized views schema (contract)

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

5) Production configuration

5.1 Network configuration
- Ensure Portal DB and PP DB are on the same network or have proper network routing configured.
- Use specific network CIDRs in pg_hba.conf, not 0.0.0.0/0.
- Configure firewall rules to allow connections between databases.

5.2 SSL/TLS configuration
- Use `sslmode='require'` in the foreign server OPTIONS to enforce SSL.
- Ensure SSL certificates are properly configured on both databases.

5.3 Role and permissions
- Grant access to a specific application role (portal_srv_read), not PUBLIC:
```sql path=null start=null
GRANT USAGE ON FOREIGN SERVER portal_srv TO portal_srv_read;
CREATE USER MAPPING IF NOT EXISTS FOR portal_srv_read
  SERVER portal_srv
  OPTIONS (user 'portal_ro_user', password :'portal_ro_password');
GRANT USAGE ON SCHEMA portal_fdw TO portal_srv_read;
GRANT SELECT ON ALL TABLES IN SCHEMA portal_fdw TO portal_srv_read;
```

6) Operations: routine update (re-import and apply updated FDW views)
- Use this when the Portal schema changes (e.g., new reference tables/columns like inland_waters_cat / inland_waters_id) or when FDW_VIEWS.sql is updated.

6.1 Portal DB privileges (run once, on the Portal DB)
- Ensure the read-only role can access the wdpa and reference schemas and all tables.
```bash path=null start=null
# Replace <portal_db_name> and run on the Portal DB host
psql -U postgres -d <portal_db_name> -X <<'SQL'
-- Grant schema usage
GRANT USAGE ON SCHEMA wdpa TO portal_ro_user;
GRANT USAGE ON SCHEMA reference TO portal_ro_user;

-- Grant SELECT on ALL existing tables in wdpa schema
GRANT SELECT ON ALL TABLES IN SCHEMA wdpa TO portal_ro_user;

-- Grant SELECT on ALL existing tables in reference schema
GRANT SELECT ON ALL TABLES IN SCHEMA reference TO portal_ro_user;

-- Ensure future tables are also accessible
ALTER DEFAULT PRIVILEGES IN SCHEMA wdpa GRANT SELECT ON TABLES TO portal_ro_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA reference GRANT SELECT ON TABLES TO portal_ro_user;
SQL
```

6.2 Drop dependent MVs on PP DB (safe if absent)
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -v ON_ERROR_STOP=1 \
  -c "DROP MATERIALIZED VIEW IF EXISTS public.portal_standard_points; DROP MATERIALIZED VIEW IF EXISTS public.portal_standard_polygons; DROP MATERIALIZED VIEW IF EXISTS public.portal_standard_sources;"
```

6.3 Re-import updated foreign tables on PP DB
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

6.4 Apply updated materialized views (FDW_VIEWS.sql) on PP DB
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -v ON_ERROR_STOP=1 -f FDW_VIEWS.sql
```

6.5 Verify views and counts
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql --no-psqlrc \
  -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -Atc \
  "SELECT 'points', count(*) FROM portal_standard_points UNION ALL SELECT 'polys', count(*) FROM portal_standard_polygons;"
```

7) Maintenance: importing new tables later
```bash path=null start=null
PGPASSWORD="$PP_DB_PASSWORD" psql -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -X <<'SQL'
IMPORT FOREIGN SCHEMA wdpa
  LIMIT TO (new_table_1, new_table_2)
  FROM SERVER portal_srv
  INTO portal_fdw;

GRANT SELECT ON ALL TABLES IN SCHEMA portal_fdw TO portal_srv_read;
SQL
```

Troubleshooting
- No pg_hba.conf entry: Add appropriate host line for portal_ro_user from PP DB network and reload.
- Connection refused: Ensure listen_addresses is configured correctly, and correct host/port are used.
- Password authentication failed: Confirm portal_ro_user password and mapping. Ensure Portal DB uses password authentication (scram-sha-256), not trust, for non-superuser FDW connections.
- SSL connection errors: Verify SSL certificates and sslmode configuration.
- Permission denied: Ensure portal_ro_user has been granted USAGE and SELECT permissions on Portal DB schemas and tables.

Cleanup (optional)
```bash path=null start=null
# Remove FDW from PP DB
PGPASSWORD="$PP_DB_PASSWORD" psql -h "$PP_DB_HOST" -p "$PP_DB_PORT" -U "$PP_DB_USER" -d "$PP_DB_NAME" -X <<'SQL'
DROP SERVER IF EXISTS portal_srv CASCADE;
DROP SCHEMA IF EXISTS portal_fdw CASCADE;
SQL
```
