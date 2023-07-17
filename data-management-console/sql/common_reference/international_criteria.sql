DELETE FROM staging_international_criteria
CREATE OR REPLACE FUNCTION staging_international_criteria_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = hashtext(NEW.description); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_staging_international_criteria_id ON staging_international_criteria
CREATE TRIGGER trig_staging_international_criteria_id BEFORE INSERT ON staging_international_criteria FOR EACH ROW EXECUTE procedure staging_international_criteria_id();

INSERT INTO STAGING_INTERNATIONAL_CRITERIA(DESCRIPTION, ORIGINATOR_ID) SELECT DISTINCT int_crit, 10000 FROM WDPADATA_POLY_MAY2023 UNION SELECT DISTINCT int_crit, 10000 FROM WDPADATA_POLY_MAY2023 UNION SELECT DISTINCT int_crit, 10000 FROM WDPADATA_POLY_MAY2023