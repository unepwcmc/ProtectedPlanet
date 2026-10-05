-- Minimum portal data for the release integration tests: ONE polygon protected
-- area in GBR. Deliberately tiny — the tests exercise the release pipeline
-- (import -> staging -> swap -> cleanup), not data coverage.
--
-- Every row below is load-bearing. Found by running the importer and reading its
-- SOFT errors, which the test failure message does not show:
--
--   data_restriction_levels  staging_portal_standard_polygons INNER JOINs this and
--                            keeps only 'not restricted' / 'commercial restriction'.
--   spatial_data             INNER JOINed on wdpa_id = wdpas.id; only is_polygon = 1
--                            rows reach the polygons view.
--   wdpa_iso3 + iso3         feed staging_portal_iso3_agg. The importer matches the
--                            ISO3 to a Country (seeded by seed_reference_data), so
--                            'GBR' must exist in lib/data/seeds/countries.csv.
--   site_type_cat            LEFT JOINed, but NOT optional in practice: the column
--                            mapper passes site_type to TypeConverter :oecm_string,
--                            which calls .match on it and raises on nil
--                            ("undefined method 'match' for nil"). The importer
--                            swallows that as a soft error and imports 0 rows.
--   realm_cat                genuinely optional (a nil realm logs and defaults to
--                            terrestrial), set anyway so the row is realistic.
--   source                   feeds staging_portal_standard_sources.
--
-- TRUNCATE first so loading is idempotent.

TRUNCATE portal_fdw.wdpas, portal_fdw.spatial_data, portal_fdw.data_restriction_levels,
         portal_fdw.source, portal_fdw.wdpa_iso3, portal_fdw.iso3,
         portal_fdw.site_type_cat, portal_fdw.realm_cat RESTART IDENTITY;

INSERT INTO portal_fdw.data_restriction_levels (id, code, description, is_standard)
VALUES (1, 'not restricted', '{"en":"Not restricted"}', 1);

INSERT INTO portal_fdw.site_type_cat (id, code, description, is_standard)
VALUES (1, 'PA', '{"en":"PA"}', 1);

INSERT INTO portal_fdw.realm_cat (id, code, description, is_standard)
VALUES (1, 'Terrestrial', '{"en":"Terrestrial"}', 1);

INSERT INTO portal_fdw.iso3 (id, code, description, is_standard)
VALUES (1, 'GBR', 'United Kingdom', 1);

INSERT INTO portal_fdw.source (id, originator_id, data_title, update_year, year)
VALUES (1, 900001, 'Test source', 2026, 2026);

INSERT INTO portal_fdw.wdpas (id, site_id, parcel_id, english_name, original_name,
  reported_area, gis_area, reported_marine_area, gis_marine_area, status_year,
  data_restriction_level_id, source_id, originator_id, site_type_id, realm_id,
  created_at, updated_at)
VALUES (1, 900001, '900001', 'Test Park', 'Test Park',
  10, 10, 0, 0, 2000,
  1, 1, 900001, 1, 1,
  now(), now());

INSERT INTO portal_fdw.wdpa_iso3 (id, wdpa_id, iso3_id, created_at, updated_at)
VALUES (1, 1, 1, now(), now());

INSERT INTO portal_fdw.spatial_data (id, wdpa_id, site_id, geom, is_polygon, created_at, updated_at)
VALUES (1, 1, 900001,
  ST_SetSRID(ST_GeomFromText('MULTIPOLYGON(((-1 51,-1 51.1,-0.9 51.1,-0.9 51,-1 51)))'), 4326),
  1, now(), now());
