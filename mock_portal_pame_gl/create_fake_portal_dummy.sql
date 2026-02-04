-- Those dummy_portal tables are the mock of the materialized views in FDW_VIEWS.sql 
-- what we expect to be in materialized views after the FDW is set up

DROP TABLE IF EXISTS dummy_portal_pame_sources;

CREATE TABLE dummy_portal_pame_sources (
  id           serial PRIMARY KEY,
  eff_metaid   integer NOT NULL,
  data_title   text,
  resp_party   text,
  resp_email   text,
  resp_pers    text,
  year         integer,
  language     text
);

-- ---------- dummy_portal_pame (matches staging_portal_standard_pame in FDW_VIEWS.sql) ----------
DROP TABLE IF EXISTS dummy_portal_pame;

CREATE TABLE dummy_portal_pame (
  id          serial PRIMARY KEY,
  asmt_id     integer NOT NULL,
  eff_metaid  integer NOT NULL,
  site_id     bigint,
  site_pid    varchar(52),
  method      text,
  submityear  integer,
  asmt_year   integer,
  verif_eff   text,
  asmt_url    text,
  info_url    text,
  gov_act     text,
  gov_asmt    text,
  dp_bio      text,
  dp_other    text,
  mgmt_obset  text,
  mgmt_obman  text,
  mgmt_adapt  text,
  mgmt_staff  text,
  mgmt_budgt  text,
  mgmt_thrts  text,
  mgmt_mon    text,
  out_bio     text
);


DROP TABLE IF EXISTS dummy_gl_data;

CREATE TABLE dummy_gl_data (
  id          serial PRIMARY KEY,
  site_id     bigint NOT NULL,
  site_pid    varchar(52) NOT NULL,
  gl_status   varchar(100),
  gl_expiry   varchar(8),
  gl_link     text
);


-- Probably do this via pgAdmin, right click the dummy table and click import/export data
-- Import mock data
\copy dummy_portal_pame_sources (eff_metaid, data_title, resp_party, resp_email, resp_pers, year, language) FROM '/Users/yuelong/Documents/WCMC/ProtectedPlanet/mock_portal_pame_gl/pamesourcedummy.csv' WITH (FORMAT csv, HEADER true);

\copy dummy_portal_pame (asmt_id, eff_metaid, site_id, site_pid, method, submityear, asmt_year, verif_eff, asmt_url, info_url, gov_act, gov_asmt, dp_bio, dp_other, mgmt_obset, mgmt_obman, mgmt_adapt, mgmt_staff, mgmt_budgt, mgmt_thrts, mgmt_mon, out_bio) FROM '/Users/yuelong/Documents/WCMC/ProtectedPlanet/mock_portal_pame_gl/pamedummy.csv' WITH (FORMAT csv, HEADER true);

\copy dummy_gl_data (site_id, site_pid, gl_status, gl_expiry, gl_link) FROM '/Users/yuelong/Documents/WCMC/ProtectedPlanet/mock_portal_pame_gl/Dummy GL.csv' WITH (FORMAT csv, HEADER true);


-- Now check out mock_portal_pame_gl/update_dummy_site_ids_from_portal.sql 
-- to update the dummy_gl_data and dummy_portal_pame with the real site_id and site_pid 
-- from the portal_standard_points and portal_standard_polygons