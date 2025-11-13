-- ProtectedPlanet ↔ Portal FDW: Materialized Views and Indexes
--
-- Usage example (dev PP DB in Docker):
--   psql -h 127.0.0.1 -p 55432 -U postgres -d pp_development -f FDW_VIEWS.sql
--
-- Requirements:
-- - The FDW server (portal_srv) and foreign tables in schema portal_fdw already exist.
-- - This script only creates materialized views in the local DB (public schema) over portal_fdw tables.
-- - PostGIS should be installed (CREATE EXTENSION IF NOT EXISTS postgis;).
--
-- ⚠️  IMPORTANT: INDEX MAINTENANCE ⚠️
-- If you modify this file (add/remove JOINs, WHERE clauses, columns, or change query patterns):
--   1. Review and update Portal DB indexes (parent database)
--      - Add indexes for new JOIN columns (foreign keys)
--      - Add indexes for new WHERE clause columns
--      - Add composite indexes for new query patterns
--   2. Review and update materialized view indexes in this file
--      - Add indexes for new columns used in WHERE/ORDER BY/GROUP BY
--      - Ensure unique indexes exist for CONCURRENT refreshes
--      - Add spatial indexes if new geometry columns are added
--
-- Performance impact: Missing indexes on Portal DB will cause slow FDW queries.
-- Missing indexes on materialized views will cause slow refreshes and queries.

-- 0) Ensure PostGIS (safe if already present)
CREATE EXTENSION IF NOT EXISTS postgis;

-- remove all existing materialized views (in order)
-- Drop dependent objects first
-- TODO: Uncomment this if you want to drop the portal_downloads_protected_areas view
-- DROP VIEW IF EXISTS portal_downloads_protected_areas;
DROP MATERIALIZED VIEW IF EXISTS public.staging_portal_standard_sources;
DROP MATERIALIZED VIEW IF EXISTS public.staging_portal_standard_polygons;
DROP MATERIALIZED VIEW IF EXISTS public.staging_portal_standard_points;

-- Drop helper aggregate views last
DROP MATERIALIZED VIEW IF EXISTS public.staging_portal_int_crit_agg;
DROP MATERIALIZED VIEW IF EXISTS public.staging_portal_parent_iso3_agg;
DROP MATERIALIZED VIEW IF EXISTS public.staging_portal_iso3_agg;




-- 1) Helper aggregate materialized views (many-to-many → concatenated text)
--    Keyed by wdpa site_id (wdpa_id in outputs) and parcel_id, not the internal PK.
--    ⚠️  If you modify JOINs or GROUP BY here, check Portal DB indexes for:
--        - wdpa_iso3, wdpa_parent_iso3, wdpa_international_criteria junction tables
--        - wdpas.id and wdpas(site_id, parcel_id) indexes
CREATE MATERIALIZED VIEW staging_portal_iso3_agg AS
SELECT d.site_id AS wdpa_id,
       d.parcel_id AS parcel_id,
       string_agg(DISTINCT i.code, ';' ORDER BY i.code) AS iso3s
FROM portal_fdw.wdpa_iso3 w
JOIN portal_fdw.wdpas d ON d.id = w.wdpa_id
JOIN portal_fdw.iso3 i  ON i.id = w.iso3_id
GROUP BY d.site_id, d.parcel_id
WITH NO DATA;

CREATE MATERIALIZED VIEW staging_portal_parent_iso3_agg AS
SELECT d.site_id AS wdpa_id,
       d.parcel_id AS parcel_id,
       string_agg(DISTINCT i.code, ';' ORDER BY i.code) AS parent_iso3s
FROM portal_fdw.wdpa_parent_iso3 w
JOIN portal_fdw.wdpas d ON d.id = w.wdpa_id
JOIN portal_fdw.iso3 i  ON i.id = w.parent_iso3_id
GROUP BY d.site_id, d.parcel_id
WITH NO DATA;

CREATE MATERIALIZED VIEW staging_portal_int_crit_agg AS
SELECT d.site_id AS wdpa_id,
       d.parcel_id AS parcel_id,
string_agg(DISTINCT COALESCE(c.description->>'en', c.code), ';' ORDER BY COALESCE(c.description->>'en', c.code)) AS int_crit
FROM portal_fdw.wdpa_international_criteria w
JOIN portal_fdw.wdpas d ON d.id = w.wdpa_id
JOIN portal_fdw.international_criteria_cat c ON c.id = w.international_criteria_cat_id
GROUP BY d.site_id, d.parcel_id
WITH NO DATA;

-- Unique indexes required for CONCURRENT refreshes
-- ⚠️  If you change GROUP BY columns, update these indexes to match
CREATE UNIQUE INDEX IF NOT EXISTS staging_idx_iso3_agg_pk        ON staging_portal_iso3_agg(wdpa_id, parcel_id);
CREATE UNIQUE INDEX IF NOT EXISTS staging_idx_parent_iso3_agg_pk ON staging_portal_parent_iso3_agg(wdpa_id, parcel_id);
CREATE UNIQUE INDEX IF NOT EXISTS staging_idx_intcrit_agg_pk     ON staging_portal_int_crit_agg(wdpa_id, parcel_id);

-- 2) Standardized views (Points)
--    Points are spatial_data rows where is_polygon = 0
--    ⚠️  If you modify JOINs, WHERE clauses, or add columns here, check:
--        - Portal DB: wdpas.archived_at, spatial_data(wdpa_id, is_polygon), data_restriction_levels.code indexes
--        - This file: Ensure unique index on (site_id, site_pid) and spatial index on wkb_geometry exist

CREATE MATERIALIZED VIEW public.staging_portal_standard_points AS
WITH site AS (
  SELECT
    w.id                           AS wdpa_pk,
    w.site_id                      AS wdpa_id,
    w.parcel_id                    AS parcel_id,
    s.originator_id                AS metadataid,
    -- Names
    w.english_name                 AS name_eng,
    w.original_name                AS orig_name,
    -- Areas
    w.reported_area                AS rep_area,
    w.reported_marine_area         AS rep_m_area,
    w.no_take_area                 AS no_tk_area,
    w.supplemental_info            AS supp_info,
    w.management_authority         AS mang_auth,
    w.management_plan              AS mang_plan,
    -- Year
    w.status_year                  AS status_yr,
    -- Associations (FK ids)
    w.site_type_id,
    w.english_designation_id,
    w.english_designation_text,
    w.designation_type_id,
    w.iucn_category_id,
    w.no_take_id,
    w.governance_type_id,
    w.ownership_type_id,
    w.realm_id,
    w.status_id,
    w.verification_id,
    w.data_restriction_level_id,
    w.conservation_objective_id,
    w.inland_waters_id,
    w.archived_at,
    w.original_designation         AS original_designation
  FROM portal_fdw.wdpas w
  LEFT JOIN portal_fdw.source s ON s.id = w.source_id
),

dim AS (
  SELECT
    s.wdpa_id,
    s.parcel_id,
    COALESCE(st.description->>'en', st.code) AS site_type,
    -- English designation: use catalog description (en) when id present; otherwise use free text
    CASE WHEN s.english_designation_id IS NULL THEN s.english_designation_text
         ELSE COALESCE(de.description->>'en', de.code) END            AS desig_eng,
    COALESCE(dt.description->>'en', dt.code)                          AS desig_type,
    COALESCE(ic.description->>'en', ic.code)                          AS iucn_cat,
    COALESCE(nt.description->>'en', nt.code)                           AS no_take,
    COALESCE(gt.description->>'en', gt.code)                           AS gov_type,
    COALESCE(ot.description->>'en', ot.code)                           AS own_type,
    COALESCE(stt.description->>'en', stt.code)                         AS status,
    COALESCE(vf.description->>'en', vf.code)                           AS verif,
    COALESCE(re.description->>'en', re.code)                           AS realm,
    COALESCE(iw.description->>'en', iw.code)                           AS inlnd_wtrs,
    COALESCE(coo.description->>'en', coo.code)                         AS cons_obj
  FROM (
    SELECT DISTINCT ON (wdpa_id, parcel_id) *
    FROM site
    WHERE archived_at IS NULL
    ORDER BY wdpa_id, parcel_id, status_yr DESC, wdpa_pk DESC
  ) s
  LEFT JOIN portal_fdw.site_type_cat        st  ON st.id  = s.site_type_id
  LEFT JOIN portal_fdw.designation_eng_cat  de  ON de.id  = s.english_designation_id
  LEFT JOIN portal_fdw.designation_type_cat dt  ON dt.id  = s.designation_type_id
  LEFT JOIN portal_fdw.iucn_category_cat    ic  ON ic.id  = s.iucn_category_id
  LEFT JOIN portal_fdw.no_take_cat          nt  ON nt.id  = s.no_take_id
  LEFT JOIN portal_fdw.governance_type_cat  gt  ON gt.id  = s.governance_type_id
  LEFT JOIN portal_fdw.ownership_type_cat   ot  ON ot.id  = s.ownership_type_id
  LEFT JOIN portal_fdw.status_cat           stt ON stt.id = s.status_id
  LEFT JOIN portal_fdw.verification_cat     vf  ON vf.id  = s.verification_id
  LEFT JOIN portal_fdw.realm_cat            re  ON re.id  = s.realm_id
  LEFT JOIN portal_fdw.inland_waters_cat    iw  ON iw.id  = s.inland_waters_id
  LEFT JOIN portal_fdw.conservation_objective_cat coo ON coo.id = s.conservation_objective_id
),

agg AS (
  SELECT
    s.wdpa_id,
    s.parcel_id,
    i.iso3s,
    p.parent_iso3s,
    c.int_crit,
    gs.govsubtype,
    os.ownsubtype,
    oa.oecm_asmt
  FROM (
    SELECT DISTINCT wdpa_id, parcel_id
    FROM site
    WHERE archived_at IS NULL
  ) s
  LEFT JOIN staging_portal_iso3_agg        i ON i.wdpa_id = s.wdpa_id AND i.parcel_id = s.parcel_id
  LEFT JOIN staging_portal_parent_iso3_agg p ON p.wdpa_id = s.wdpa_id AND p.parcel_id = s.parcel_id
  LEFT JOIN staging_portal_int_crit_agg    c ON c.wdpa_id = s.wdpa_id AND c.parcel_id = s.parcel_id
  LEFT JOIN (
    SELECT d.site_id AS wdpa_id,
           d.parcel_id AS parcel_id,
string_agg(DISTINCT COALESCE(gst.description->>'en', gst.code), ';' ORDER BY COALESCE(gst.description->>'en', gst.code)) AS govsubtype
    FROM portal_fdw.wdpa_governance_subtypes wgs
    JOIN portal_fdw.wdpas d ON d.id = wgs.wdpa_id
    JOIN portal_fdw.governance_subtype_cat gst ON gst.id = wgs.governance_subtype_cat_id
    GROUP BY d.site_id, d.parcel_id
  ) gs ON gs.wdpa_id = s.wdpa_id AND gs.parcel_id = s.parcel_id
  LEFT JOIN (
    SELECT d.site_id AS wdpa_id,
           d.parcel_id AS parcel_id,
string_agg(DISTINCT COALESCE(ost.description->>'en', ost.code), ';' ORDER BY COALESCE(ost.description->>'en', ost.code)) AS ownsubtype
    FROM portal_fdw.wdpa_ownership_subtypes wos
    JOIN portal_fdw.wdpas d ON d.id = wos.wdpa_id
    JOIN portal_fdw.ownership_subtype_cat ost ON ost.id = wos.ownership_subtype_cat_id
    GROUP BY d.site_id, d.parcel_id
  ) os ON os.wdpa_id = s.wdpa_id AND os.parcel_id = s.parcel_id
  LEFT JOIN (
    SELECT d.site_id AS wdpa_id,
           d.parcel_id AS parcel_id,
string_agg(DISTINCT COALESCE(oc.description->>'en', oc.code), ';' ORDER BY COALESCE(oc.description->>'en', oc.code)) AS oecm_asmt
    FROM portal_fdw.wdpa_oecm_assessments woa
    JOIN portal_fdw.wdpas d ON d.id = woa.wdpa_id
    JOIN portal_fdw.oecm_assessment_cat oc ON oc.id = woa.oecm_assessment_cat_id
    GROUP BY d.site_id, d.parcel_id
  ) oa ON oa.wdpa_id = s.wdpa_id AND oa.parcel_id = s.parcel_id
)
SELECT
  (row_number() OVER (ORDER BY site.wdpa_id, site.parcel_id))::integer AS ogc_fid,
  (site.wdpa_id)::integer                                    AS site_id,
  (site.parcel_id)::varchar(52)                              AS site_pid,

  LEFT(dim.site_type::varchar, 20)                           AS site_type,
  LEFT(site.name_eng::varchar, 254)                          AS name_eng,
  LEFT(site.orig_name::varchar, 254)                         AS name,
  LEFT(site.original_designation::varchar, 254)              AS desig,
  LEFT(dim.desig_eng::varchar, 254)                          AS desig_eng,
  LEFT(dim.desig_type::varchar, 20)                          AS desig_type,
  LEFT(dim.iucn_cat::varchar, 20)                            AS iucn_cat,
  LEFT(agg.int_crit::varchar, 100)                           AS int_crit,
  (dim.realm)::varchar(20)                                   AS realm,
  (site.rep_m_area)::double precision                        AS rep_m_area,
  (site.rep_area)::double precision                          AS rep_area,
  LEFT(dim.no_take::varchar, 50)                             AS no_take,
  (site.no_tk_area)::double precision                        AS no_tk_area,
  LEFT(dim.status::varchar, 100)                             AS status,
  (site.status_yr)::integer                                  AS status_yr,
  LEFT(dim.gov_type::varchar, 254)                           AS gov_type,
  LEFT(dim.own_type::varchar, 254)                           AS own_type,
  LEFT(site.mang_auth::varchar, 254)                         AS mang_auth,
  LEFT(site.mang_plan::varchar, 254)                         AS mang_plan,
  LEFT(dim.cons_obj::varchar, 100)                           AS cons_obj,
  LEFT(site.supp_info::varchar, 254)                         AS supp_info,
  LEFT(dim.verif::varchar, 20)                               AS verif,
  LEFT(dim.inlnd_wtrs::varchar, 100)                         AS inlnd_wtrs,

  (site.metadataid)::integer                                 AS metadataid,
  LEFT(agg.parent_iso3s::varchar, 50)                        AS prnt_iso3,
  LEFT(agg.iso3s::varchar, 50)                               AS iso3,
  LEFT(agg.govsubtype::varchar, 254)                         AS govsubtype,
  LEFT(agg.ownsubtype::varchar, 254)                         AS ownsubtype,
  LEFT(agg.oecm_asmt::varchar, 254)                          AS oecm_asmt,

  par.geom AS wkb_geometry

FROM site
JOIN portal_fdw.spatial_data par ON par.wdpa_id = site.wdpa_pk
JOIN portal_fdw.data_restriction_levels dr ON dr.id = site.data_restriction_level_id
LEFT JOIN dim               ON dim.wdpa_id = site.wdpa_id AND dim.parcel_id = site.parcel_id
LEFT JOIN agg               ON agg.wdpa_id = site.wdpa_id AND agg.parcel_id = site.parcel_id
LEFT JOIN portal_fdw.conservation_objective_cat coo ON coo.id = site.conservation_objective_id
WHERE par.is_polygon = 0
  AND site.archived_at IS NULL
  AND dr.code IN ('not restricted', 'commercial restriction')
WITH NO DATA;

-- Unique index required for CONCURRENT refreshes (natural key: site_id + site_pid)
-- ⚠️  If you change the natural key columns, update this index
CREATE UNIQUE INDEX IF NOT EXISTS staging_idx_portal_points_pk ON staging_portal_standard_points (site_id, site_pid);
-- Spatial index for efficient geometry queries (ST_DWithin, ST_Intersects, etc.)
-- ⚠️  If you add/modify geometry columns, ensure spatial indexes exist for all geometry columns
CREATE INDEX IF NOT EXISTS staging_idx_portal_points_geom ON staging_portal_standard_points USING GIST (wkb_geometry);

-- 3) Standardized views (Polygons)
--    Polygons are spatial_data rows where is_polygon = 1
--    ⚠️  If you modify JOINs, WHERE clauses, or add columns here, check:
--        - Portal DB: wdpas.archived_at, spatial_data(wdpa_id, is_polygon), data_restriction_levels.code indexes
--        - This file: Ensure unique index on (site_id, site_pid) and spatial index on wkb_geometry exist

CREATE MATERIALIZED VIEW public.staging_portal_standard_polygons AS
WITH site AS (
  SELECT
    w.id                           AS wdpa_pk,
    w.site_id                      AS wdpa_id,
    w.parcel_id                    AS parcel_id,
    s.originator_id                AS metadataid,
    -- Names
    w.english_name                 AS name_eng,
    w.original_name                AS orig_name,
    -- Areas
    w.reported_area                AS rep_area,
    w.reported_marine_area         AS rep_m_area,
    w.no_take_area                 AS no_tk_area,
    w.gis_area                     AS gis_area,
    w.gis_marine_area              AS gis_marine_area,
    w.supplemental_info            AS supp_info,
    w.management_authority         AS mang_auth,
    w.management_plan              AS mang_plan,
    -- Year
    w.status_year                  AS status_yr,
    -- Associations (FK ids)
    w.site_type_id,
    w.english_designation_id,
    w.english_designation_text,
    w.designation_type_id,
    w.iucn_category_id,
    w.no_take_id,
    w.governance_type_id,
    w.ownership_type_id,
    w.realm_id,
    w.status_id,
    w.verification_id,
    w.data_restriction_level_id,
    w.conservation_objective_id,
    w.inland_waters_id,
    w.archived_at,
    w.original_designation         AS original_designation
  FROM portal_fdw.wdpas w
  LEFT JOIN portal_fdw.source s ON s.id = w.source_id
),

dim AS (
  SELECT
    s.wdpa_id,
    s.parcel_id,
    COALESCE(st.description->>'en', st.code) AS site_type,
    CASE WHEN s.english_designation_id IS NULL THEN s.english_designation_text
         ELSE COALESCE(de.description->>'en', de.code) END            AS desig_eng,
    COALESCE(dt.description->>'en', dt.code)                          AS desig_type,
    COALESCE(ic.description->>'en', ic.code)                          AS iucn_cat,
    COALESCE(nt.description->>'en', nt.code)                           AS no_take,
    COALESCE(gt.description->>'en', gt.code)                           AS gov_type,
    COALESCE(ot.description->>'en', ot.code)                           AS own_type,
    COALESCE(stt.description->>'en', stt.code)                         AS status,
    COALESCE(vf.description->>'en', vf.code)                           AS verif,
    COALESCE(re.description->>'en', re.code)                           AS realm,
    COALESCE(iw.description->>'en', iw.code)                           AS inlnd_wtrs,
    COALESCE(coo.description->>'en', coo.code)                         AS cons_obj
  FROM (
    SELECT DISTINCT ON (wdpa_id, parcel_id) *
    FROM site
    WHERE archived_at IS NULL
    ORDER BY wdpa_id, parcel_id, status_yr DESC, wdpa_pk DESC
  ) s
  LEFT JOIN portal_fdw.site_type_cat        st  ON st.id  = s.site_type_id
  LEFT JOIN portal_fdw.designation_eng_cat  de  ON de.id  = s.english_designation_id
  LEFT JOIN portal_fdw.designation_type_cat dt  ON dt.id  = s.designation_type_id
  LEFT JOIN portal_fdw.iucn_category_cat    ic  ON ic.id  = s.iucn_category_id
  LEFT JOIN portal_fdw.no_take_cat          nt  ON nt.id  = s.no_take_id
  LEFT JOIN portal_fdw.governance_type_cat  gt  ON gt.id  = s.governance_type_id
  LEFT JOIN portal_fdw.ownership_type_cat   ot  ON ot.id  = s.ownership_type_id
  LEFT JOIN portal_fdw.status_cat           stt ON stt.id = s.status_id
  LEFT JOIN portal_fdw.verification_cat     vf  ON vf.id  = s.verification_id
  LEFT JOIN portal_fdw.realm_cat            re  ON re.id  = s.realm_id
  LEFT JOIN portal_fdw.inland_waters_cat    iw  ON iw.id  = s.inland_waters_id
  LEFT JOIN portal_fdw.conservation_objective_cat coo ON coo.id = s.conservation_objective_id
),

agg AS (
  SELECT
    s.wdpa_id,
    s.parcel_id,
    i.iso3s,
    p.parent_iso3s,
    c.int_crit,
    gs.govsubtype,
    os.ownsubtype,
    oa.oecm_asmt
  FROM (
    SELECT DISTINCT wdpa_id, parcel_id
    FROM site
    WHERE archived_at IS NULL
  ) s
  LEFT JOIN staging_portal_iso3_agg        i ON i.wdpa_id = s.wdpa_id AND i.parcel_id = s.parcel_id
  LEFT JOIN staging_portal_parent_iso3_agg p ON p.wdpa_id = s.wdpa_id AND p.parcel_id = s.parcel_id
  LEFT JOIN staging_portal_int_crit_agg    c ON c.wdpa_id = s.wdpa_id AND c.parcel_id = s.parcel_id
  LEFT JOIN (
    SELECT d.site_id AS wdpa_id,
           d.parcel_id AS parcel_id,
string_agg(DISTINCT COALESCE(gst.description->>'en', gst.code), ';' ORDER BY COALESCE(gst.description->>'en', gst.code)) AS govsubtype
    FROM portal_fdw.wdpa_governance_subtypes wgs
    JOIN portal_fdw.wdpas d ON d.id = wgs.wdpa_id
    JOIN portal_fdw.governance_subtype_cat gst ON gst.id = wgs.governance_subtype_cat_id
    GROUP BY d.site_id, d.parcel_id
  ) gs ON gs.wdpa_id = s.wdpa_id AND gs.parcel_id = s.parcel_id
  LEFT JOIN (
    SELECT d.site_id AS wdpa_id,
           d.parcel_id AS parcel_id,
string_agg(DISTINCT COALESCE(ost.description->>'en', ost.code), ';' ORDER BY COALESCE(ost.description->>'en', ost.code)) AS ownsubtype
    FROM portal_fdw.wdpa_ownership_subtypes wos
    JOIN portal_fdw.wdpas d ON d.id = wos.wdpa_id
    JOIN portal_fdw.ownership_subtype_cat ost ON ost.id = wos.ownership_subtype_cat_id
    GROUP BY d.site_id, d.parcel_id
  ) os ON os.wdpa_id = s.wdpa_id AND os.parcel_id = s.parcel_id
  LEFT JOIN (
    SELECT d.site_id AS wdpa_id,
           d.parcel_id AS parcel_id,
string_agg(DISTINCT COALESCE(oc.description->>'en', oc.code), ';' ORDER BY COALESCE(oc.description->>'en', oc.code)) AS oecm_asmt
    FROM portal_fdw.wdpa_oecm_assessments woa
    JOIN portal_fdw.wdpas d ON d.id = woa.wdpa_id
    JOIN portal_fdw.oecm_assessment_cat oc ON oc.id = woa.oecm_assessment_cat_id
    GROUP BY d.site_id, d.parcel_id
  ) oa ON oa.wdpa_id = s.wdpa_id AND oa.parcel_id = s.parcel_id
)
SELECT
  (row_number() OVER (ORDER BY site.wdpa_id, site.parcel_id))::integer AS ogc_fid,
  (site.wdpa_id)::integer                                    AS site_id,
  (site.parcel_id)::varchar(52)                              AS site_pid,

  LEFT(dim.site_type::varchar, 20)                           AS site_type,
  LEFT(site.name_eng::varchar, 254)                          AS name_eng,
  LEFT(site.orig_name::varchar, 254)                         AS name,
  LEFT(site.original_designation::varchar, 254)              AS desig,
  LEFT(dim.desig_eng::varchar, 254)                          AS desig_eng,
  LEFT(dim.desig_type::varchar, 20)                          AS desig_type,
  LEFT(dim.iucn_cat::varchar, 20)                            AS iucn_cat,
  LEFT(agg.int_crit::varchar, 100)                           AS int_crit,
  (dim.realm)::varchar(20)                                   AS realm,
  (site.rep_m_area)::double precision                        AS rep_m_area,
  (site.gis_marine_area)::double precision                   AS gis_m_area,
  (site.rep_area)::double precision                          AS rep_area,
  (site.gis_area)::double precision                          AS gis_area,
  LEFT(dim.no_take::varchar, 50)                             AS no_take,
  (site.no_tk_area)::double precision                        AS no_tk_area,
  LEFT(dim.status::varchar, 100)                             AS status,
  (site.status_yr)::integer                                  AS status_yr,
  LEFT(dim.gov_type::varchar, 254)                           AS gov_type,
  LEFT(dim.verif::varchar, 20)                                 AS verif,
  LEFT(dim.inlnd_wtrs::varchar, 100)                            AS inlnd_wtrs,
  LEFT(dim.own_type::varchar, 254)                           AS own_type,
  LEFT(site.mang_auth::varchar, 254)                         AS mang_auth,
  LEFT(site.mang_plan::varchar, 254)                         AS mang_plan,
  LEFT(dim.cons_obj::varchar, 100)                           AS cons_obj,
  LEFT(site.supp_info::varchar, 254)                         AS supp_info,

  (site.metadataid)::integer                                 AS metadataid,
  LEFT(agg.parent_iso3s::varchar, 50)                        AS prnt_iso3,
  LEFT(agg.iso3s::varchar, 50)                               AS iso3,
  LEFT(agg.govsubtype::varchar, 254)                         AS govsubtype,
  LEFT(agg.ownsubtype::varchar, 254)                         AS ownsubtype,
  LEFT(agg.oecm_asmt::varchar, 254)                          AS oecm_asmt,

  NULL::double precision AS shape_length,
  NULL::double precision AS shape_area,

  par.geom AS wkb_geometry

FROM site
JOIN portal_fdw.spatial_data par ON par.wdpa_id = site.wdpa_pk
JOIN portal_fdw.data_restriction_levels dr ON dr.id = site.data_restriction_level_id
LEFT JOIN dim               ON dim.wdpa_id = site.wdpa_id AND dim.parcel_id = site.parcel_id
LEFT JOIN agg               ON agg.wdpa_id = site.wdpa_id AND agg.parcel_id = site.parcel_id
LEFT JOIN portal_fdw.conservation_objective_cat coo ON coo.id = site.conservation_objective_id
WHERE par.is_polygon = 1
  AND site.archived_at IS NULL
  AND dr.code IN ('not restricted', 'commercial restriction')
WITH NO DATA;

-- Unique index required for CONCURRENT refreshes (natural key: site_id + site_pid)
-- ⚠️  If you change the natural key columns, update this index
CREATE UNIQUE INDEX IF NOT EXISTS staging_idx_portal_polygons_pk ON staging_portal_standard_polygons (site_id, site_pid);
-- Spatial index for efficient geometry queries (ST_DWithin, ST_Intersects, etc.)
-- ⚠️  If you add/modify geometry columns, ensure spatial indexes exist for all geometry columns
CREATE INDEX IF NOT EXISTS staging_idx_portal_polygons_geom ON staging_portal_standard_polygons USING GIST (wkb_geometry);

-- 4) Standardized view (Sources)
--    Only includes sources used by non-archived wdpas with allowed restriction levels
--    ⚠️  If you modify JOINs or WHERE clauses here, check Portal DB indexes for:
--        - source.id, wdpas.source_id, wdpas.archived_at, data_restriction_levels.code
--        - This file: Ensure unique index on index_id and index on metadataid exist

CREATE MATERIALIZED VIEW public.staging_portal_standard_sources AS
WITH allowed_sources AS (
  SELECT DISTINCT s.id AS source_id
  FROM portal_fdw.source s
  JOIN portal_fdw.wdpas w ON w.source_id = s.id
  JOIN portal_fdw.data_restriction_levels dr ON dr.id = w.data_restriction_level_id
  WHERE w.archived_at IS NULL
    AND dr.code IN ('not restricted', 'commercial restriction')
)
SELECT
  (row_number() OVER (ORDER BY s.originator_id, s.data_title)::text || '_' || s.originator_id::text) AS index_id,
  (s.originator_id)::integer                           AS metadataid,
  LEFT(s.data_title::varchar, 255)                     AS data_title,
  LEFT(p.responsible_party::varchar, 255)              AS resp_party,
  LEFT(s.verifier::varchar, 259)                       AS verifier,
  LEFT(s.year::varchar, 255)                           AS year,
  LEFT(s.update_year::varchar, 255)                    AS update_yr,
  LEFT(COALESCE(lang.code, s.language::text)::varchar, 255)       AS language,
  LEFT(COALESCE(cs.code,   s.character_set::text)::varchar, 255)  AS char_set,
  LEFT(s.reference_system::varchar, 255)               AS ref_system,
  LEFT(s.scale::varchar, 255)                          AS scale,
  LEFT(s.lineage::varchar, 264)                        AS lineage,
  LEFT(s.citation::varchar, 261)                       AS citation,
  LEFT(s.disclaimer::varchar, 264)                     AS disclaimer
FROM portal_fdw.source s
JOIN allowed_sources a ON a.source_id = s.id
LEFT JOIN portal_fdw.provider          p   ON p.id  = s.provider_id
LEFT JOIN portal_fdw.character_set_cat cs  ON lower(cs.code)  = lower(s.character_set::text)
LEFT JOIN portal_fdw.language_cat      lang ON lower(lang.code)= lower(s.language::text)
WITH NO DATA;

-- Non-unique index (metadataid has duplicates in dev data)
-- ⚠️  If you add columns used in WHERE/ORDER BY, consider adding indexes
CREATE INDEX IF NOT EXISTS staging_idx_portal_sources_metadataid ON staging_portal_standard_sources(metadataid);
-- Unique index required for CONCURRENT refreshes
-- ⚠️  If you change how index_id is generated, update this index
CREATE UNIQUE INDEX IF NOT EXISTS staging_idx_portal_sources_pk ON staging_portal_standard_sources(index_id);

-- 5) refreshes (make sure to run this after creating the views)
-- YOU PROBABLY DON"T NEED TO RUN IT CONCURRENTLY THEN REMOVE 'CONCURRENTLY'
REFRESH MATERIALIZED VIEW staging_portal_iso3_agg;
REFRESH MATERIALIZED VIEW staging_portal_parent_iso3_agg;
REFRESH MATERIALIZED VIEW staging_portal_int_crit_agg;
REFRESH MATERIALIZED VIEW staging_portal_standard_points;
REFRESH MATERIALIZED VIEW staging_portal_standard_polygons;
REFRESH MATERIALIZED VIEW staging_portal_standard_sources;

