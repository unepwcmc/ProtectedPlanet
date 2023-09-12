DROP SEQUENCE IF EXISTS stg_wdpa_providers_seq
CREATE SEQUENCE stg_wdpa_providers_seq AS INT START WITH 1

CREATE OR REPLACE FUNCTION stg_wdpa_providers_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_wdpa_providers_seq'); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_stg_wdpa_providers_id ON stg_wdpa_providers
CREATE TRIGGER trig_stg_wdpa_providers_id BEFORE INSERT ON stg_wdpa_providers FOR EACH ROW EXECUTE procedure stg_wdpa_providers_id();

DROP INDEX IF EXISTS ORIG_1;
DROP INDEX IF EXISTS ORIG_2;
DROP INDEX IF EXISTS ORIG_3;
CREATE INDEX ORIG_1 ON wdpa(ToZ, isdeleted);
CREATE INDEX ORIG_2 ON spatial_data(ToZ, isdeleted);

CREATE INDEX ON stg_WDPA(ORIGINATOR_ID);
CREATE INDEX ON stg_SPATIAL_DATA(ORIGINATOR_ID);
CREATE INDEX on wdpa(ORIGINATOR_ID)
CREATE INDEX ON wdpa_sources(originator_id)
CREATE INDEX ON wdpa_sources(responsible_party_id)
CREATE INDEX on wdpa_providers(id)

DELETE FROM stg_wdpa_providers;
DELETE FROM stg_wdpa_sources;
DELETE FROM stg_designation_type_cat;
DELETE FROM stg_wdpa_status_cat;
DELETE FROM stg_wdpa_governance_type_cat;
DELETE FROM stg_conservation_objective_cat
DELETE FROM stg_wdpa_verification_cat

INSERT INTO stg_wdpa_providers(id, responsible_party, originator_id) VALUES(99999999, 'WCMC Internal Provider', 10000);
INSERT INTO stg_wdpa_sources(responsible_party_id,verifier, year, originator_id) VALUES(99999999, 'Internal record only', 2023, 10000)
INSERT INTO stg_designation_type_cat(code, description, originator_id) SELECT DISTINCT desig_type, desig_type, 10000 from wdpadata_poly_may2023;
INSERT INTO stg_wdpa_status_cat(code, description, originator_id) SELECT DISTINCT status, status, 10000 from wdpadata_poly_may2023;
INSERT INTO stg_wdpa_governance_type_cat(code, description, originator_id) SELECT DISTINCT gov_type, gov_type, 10000 from wdpadata_poly_may2023;
INSERT INTO stg_conservation_objective_cat(code, description, originator_id) SELECT DISTINCT cons_obj, cons_obj, 10000 from wdpadata_poly_may2023;
INSERT INTO stg_wdpa_verification_cat(code, description, originator_id) SELECT DISTINCT verif, verif, 10000 from wdpadata_poly_may2023;;


INSERT INTO stg_sub_location_cat(code, description, originator_id) select DISTINCT trim(e'\n ' from unnest(string_to_array(sub_loc, ';'))), 'No description known', 10000 FROM wdpadata_poly_may2023;


