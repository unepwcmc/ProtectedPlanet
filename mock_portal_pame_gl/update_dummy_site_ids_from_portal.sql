-- Update site_id and site_pid in dummy_gl_data and dummy_portal_pame with real IDs
-- from portal_standard_points and portal_standard_polygons.
-- Prefer (site_id, site_pid) from sites that have parcels (multiple site_pids per site_id),
-- then use sites that have no parcels (single site_pid per site_id).
--
-- Prereqs: Run after create_fake_portal_dummy.sql and after refreshing the staging
-- portal views so portal_standard_points and portal_standard_polygons have data.
-- If the views are empty, these updates will affect no rows (no division-by-zero).
--
--   psql -h localhost -p 5441 -U postgres -d pp_development -f mock_portal_pame_gl/update_dummy_site_ids_from_portal.sql

-- Ordered list of real (site_id, site_pid): sites with parcels first (count > 1 per site_id), then rest
WITH real_sites AS (
  SELECT site_id, site_pid FROM portal_standard_points
  UNION
  SELECT site_id, site_pid FROM portal_standard_polygons
),
parcel_counts AS (
  SELECT site_id, COUNT(*) AS n
  FROM real_sites
  GROUP BY site_id
),
ordered_real AS (
  SELECT
    r.site_id,
    r.site_pid,
    ROW_NUMBER() OVER (
      ORDER BY (CASE WHEN p.n > 1 THEN 0 ELSE 1 END), r.site_id, r.site_pid
    ) AS rn
  FROM real_sites r
  JOIN parcel_counts p ON p.site_id = r.site_id
),
real_total AS (
  SELECT COUNT(*) AS n FROM ordered_real
),

-- Update dummy_gl_data: assign real (site_id, site_pid) by row order, cycle if fewer real than dummy
dummy_gl_numbered AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM dummy_gl_data
)
UPDATE dummy_gl_data d
SET
  site_id   = o.site_id::bigint,
  site_pid  = o.site_pid
FROM dummy_gl_numbered dn
JOIN ordered_real o ON o.rn = ((dn.rn - 1) % NULLIF((SELECT n FROM real_total), 0) + 1)
WHERE d.id = dn.id;

-- Update dummy_portal_pame: same rule (cycle through ordered real sites)
WITH ordered_real AS (
  SELECT
    r.site_id,
    r.site_pid,
    ROW_NUMBER() OVER (
      ORDER BY (CASE WHEN p.n > 1 THEN 0 ELSE 1 END), r.site_id, r.site_pid
    ) AS rn
  FROM (
    SELECT site_id, site_pid FROM portal_standard_points
    UNION
    SELECT site_id, site_pid FROM portal_standard_polygons
  ) r
  JOIN (
    SELECT site_id, COUNT(*) AS n
    FROM (
      SELECT site_id, site_pid FROM portal_standard_points
      UNION
      SELECT site_id, site_pid FROM portal_standard_polygons
    ) x
    GROUP BY site_id
  ) p ON p.site_id = r.site_id
),
real_total AS (
  SELECT COUNT(*) AS n FROM ordered_real
),
dummy_pame_numbered AS (
  SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM dummy_portal_pame
)
UPDATE dummy_portal_pame d
SET
  site_id   = o.site_id::bigint,
  site_pid  = o.site_pid
FROM dummy_pame_numbered dn
JOIN ordered_real o ON o.rn = ((dn.rn - 1) % NULLIF((SELECT n FROM real_total), 0) + 1)
WHERE d.id = dn.id;
