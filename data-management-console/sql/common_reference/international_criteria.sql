DELETE FROM stg_international_criteria
DROP SEQUENCE IF EXISTS stg_int_crit_seq
CREATE SEQUENCE stg_int_crit_seq AS INT START WITH 1

CREATE OR REPLACE FUNCTION stg_international_criteria_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_int_crit_seq'); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_stg_international_criteria_id ON stg_international_criteria
CREATE TRIGGER trig_stg_international_criteria_id BEFORE INSERT ON stg_international_criteria FOR EACH ROW EXECUTE procedure stg_international_criteria_id();

INSERT INTO stg_INTERNATIONAL_CRITERIA(DESCRIPTION, ORIGINATOR_ID) SELECT DISTINCT int_crit, 10000 FROM WDPADATA_POLY_MAY2023 UNION SELECT DISTINCT int_crit, 10000 FROM WDPADATA_POLY_MAY2023 UNION SELECT DISTINCT int_crit, 10000 FROM WDPADATA_POLY_MAY2023