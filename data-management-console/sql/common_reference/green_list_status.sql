DELETE FROM staging_green_list_status
CREATE OR REPLACE FUNCTION staging_green_list_status_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = hashtext(NEW.description); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_staging_green_list_status ON staging_green_list_status
CREATE TRIGGER trig_staging_green_list_status BEFORE INSERT ON staging_green_list_status FOR EACH ROW EXECUTE procedure staging_green_list_status_id();

INSERT INTO staging_green_list_status(DESCRIPTION, ORIGINATOR_ID) VALUES('Candidate', 10000);
INSERT INTO staging_green_list_status(DESCRIPTION, ORIGINATOR_ID) VALUES('Green Listed', 10000);
INSERT INTO staging_green_list_status(DESCRIPTION, ORIGINATOR_ID) VALUES('Relisted', 10000);

