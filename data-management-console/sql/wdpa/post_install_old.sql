DROP INDEX IF EXISTS ORIG_1;
DROP INDEX IF EXISTS ORIG_2;
DROP INDEX IF EXISTS ORIG_3;
CREATE INDEX ORIG_1 ON WDPA(ToZ, isdeleted);
CREATE INDEX ORIG_2 ON SPATIAL_DATA(ToZ, isdeleted);

CREATE INDEX ON stg_WDPA(ORIGINATOR_ID);
CREATE INDEX ON stg_SPATIAL_DATA(ORIGINATOR_ID);

DROP SEQUENCE IF EXISTS wdpa_providers_seq
CREATE SEQUENCE wdpa_providers_seq AS INT START WITH 1

CREATE OR REPLACE FUNCTION stg_wdpa_providers_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('wdpa_providers_seq'); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_stg_wdpa_providers ON stg_wdpa_providers
CREATE TRIGGER trig_stg_wdpa_providers BEFORE INSERT ON stg_wdpa_providers FOR EACH ROW EXECUTE procedure stg_wdpa_providers_id();

CREATE OR REPLACE FUNCTION get_iso3_string(wdpa bigint, parcel varchar) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare iso3_string varchar(255); begin SELECT array_to_string(array_agg(distinct code), ';') into iso3_string from wdpa_iso3_a a, iso3 b where a.id = b.id and a.wdpa_id = wdpa and a.parcel_id = parcel; return iso3_string; end; $$
CREATE OR REPLACE FUNCTION get_parent_iso3_string(wdpa bigint, parcel varchar) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare iso3_string varchar(255); begin SELECT array_to_string(array_agg(distinct code), ';') into iso3_string from wdpa_iso3_a a, iso3 b where a.id = b.id and a.wdpa_id = wdpa and a.parcel_id = parcel; return iso3_string; end; $$
CREATE OR REPLACE FUNCTION get_designation_status(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from designation_status a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_international_criteria(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from international_criteria a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_iucn_cat(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from iucn_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_no_take(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from no_take a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_orig_designation_status(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from orig_designation_status a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_international_criteria(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from international_criteria a where a.id = code_in; return description; end; $$

DELETE FROM stg_wdpa_providers;
INSERT INTO stg_wdpa_providers(id, responsible_party, originator_id) VALUES(99999999, 'WCMC Internal Provider', 10000);
DELETE FROM stg_wdpa_sources;
INSERT INTO stg_wdpa_sources(responsible_party_id,verifier, year, originator_id) VALUES(99999999, 'Internal record only', 2023, 10000)

DELETE FROM stg_designation_type_cat;
DROP SEQUENCE IF EXISTS stg_designation_type_cat_seq;
CREATE SEQUENCE stg_designation_type_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_designation_type_category_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_designation_type_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_designation_type_id ON stg_designation_type_cat;
CREATE TRIGGER trig_designation_type_id BEFORE INSERT ON stg_designation_type_cat FOR EACH ROW EXECUTE procedure stg_designation_type_category_id();
INSERT INTO stg_designation_type_cat(DESCRIPTION) SELECT DISTINCT desig_type from wdpadata_poly_may2023;

DELETE FROM stg_status_cat;
DROP SEQUENCE IF EXISTS stg_status_cat_seq;
CREATE SEQUENCE stg_status_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_status_category_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_status_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_status_id ON stg_status_cat;
CREATE TRIGGER trig_status_id BEFORE INSERT ON stg_status_cat FOR EACH ROW EXECUTE procedure stg_status_category_id();
INSERT INTO stg_status_cat(DESCRIPTION) SELECT DISTINCT status from wdpadata_poly_may2023;

DELETE FROM stg_governance_ty_cat;
DROP SEQUENCE IF EXISTS stg_governance_ty_cat_seq;
CREATE SEQUENCE stg_governance_ty_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_governance_ty_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_governance_ty_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_governance_ty_cat_id ON stg_governance_ty_cat;
CREATE TRIGGER trig_governance_ty_cat_id BEFORE INSERT ON stg_governance_ty_cat FOR EACH ROW EXECUTE procedure stg_governance_ty_cat_id();
INSERT INTO stg_governance_ty_cat(DESCRIPTION) SELECT DISTINCT gov_type from wdpadata_poly_may2023;

DELETE FROM stg_ownership_type_cat;
DROP SEQUENCE IF EXISTS stg_ownership_type_cat_seq;
CREATE SEQUENCE stg_ownership_type_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_ownership_type_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_ownership_type_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_ownership_type_cat_id ON stg_ownership_type_cat;
CREATE TRIGGER trig_ownership_type_cat_id BEFORE INSERT ON stg_ownership_type_cat FOR EACH ROW EXECUTE procedure stg_ownership_type_cat_id();
INSERT INTO stg_ownership_type_cat(DESCRIPTION) SELECT DISTINCT own_type from wdpadata_poly_may2023;

DELETE FROM stg_cons_obj_cat;
DROP SEQUENCE IF EXISTS stg_cons_obj_cat_seq;
CREATE SEQUENCE stg_cons_obj_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_cons_obj_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_cons_obj_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_cons_obj_cat_id ON stg_cons_obj_cat;
CREATE TRIGGER trig_cons_obj_cat_id BEFORE INSERT ON stg_cons_obj_cat FOR EACH ROW EXECUTE procedure stg_cons_obj_cat_id();
INSERT INTO stg_cons_obj_cat(DESCRIPTION) SELECT DISTINCT cons_obj from wdpadata_poly_may2023;

DELETE FROM stg_verif_cat;
DROP SEQUENCE IF EXISTS stg_verif_cat_seq;
CREATE SEQUENCE stg_verif_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_verif_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_verif_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_verif_cat_id ON stg_verif_cat;
CREATE TRIGGER trig_verif_cat_id BEFORE INSERT ON stg_verif_cat FOR EACH ROW EXECUTE procedure stg_verif_cat_id();
INSERT INTO stg_verif_cat(DESCRIPTION) SELECT DISTINCT verif from wdpadata_poly_may2023;;

CREATE OR REPLACE FUNCTION get_wdpa_designation_type(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from designation_type_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_wdpa_governance_type(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from governance_type_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_wdpa_ownership_type(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from ownership_type_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_wdpa_status(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from status_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_wdpa_conservation_objective(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from cons_obj_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_wdpa_verification(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from verif_cat a where a.id = code_in; return description; end; $$
