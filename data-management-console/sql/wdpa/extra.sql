DROP INDEX IF EXISTS ORIG_1;
DROP INDEX IF EXISTS ORIG_2;
DROP INDEX IF EXISTS ORIG_3;
CREATE INDEX ORIG_1 ON WDPA(ToZ, isdeleted);
CREATE INDEX ORIG_2 ON SPATIAL_DATA(ToZ, isdeleted);
CREATE INDEX ORIG_3 ON WDPA_ISO3_ASSOC(ToZ, isdeleted);

CREATE INDEX ON STAGING_WDPA(ORIGINATOR_ID);
CREATE INDEX ON STAGING_SPATIAL_DATA(ORIGINATOR_ID);
CREATE INDEX ON STAGING_WDPA_ISO3_ASSOC(ORIGINATOR_ID);

CREATE OR REPLACE FUNCTION staging_data_providers_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = hashtext(NEW.responsible_party); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_staging_data_providers ON staging_data_providers
CREATE TRIGGER trig_staging_data_providers BEFORE INSERT ON staging_data_providers FOR EACH ROW EXECUTE procedure staging_data_providers_id();

CREATE OR REPLACE FUNCTION get_iso3_string(wdpa bigint, parcel varchar) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare iso3_string varchar(255); begin SELECT array_to_string(array_agg(distinct code), ';') into iso3_string from wdpa_iso3_assoc a, iso3 b where a.iso3_id = b.id and a.wdpa_id = wdpa and a.parcel_id = parcel; return iso3_string; end; $$
CREATE OR REPLACE FUNCTION get_designation_status(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from designation_status a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_international_criteria(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from international_criteria a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_iucn_cat(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from iucn_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_no_take(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from no_take a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_orig_designation_status(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from orig_designation_status a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_international_criteria(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(255); begin SELECT a.description into description from international_criteria a where a.id = code_in; return description; end; $$