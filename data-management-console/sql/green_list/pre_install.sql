DELETE FROM stg_green_list_status

DROP SEQUENCE IF EXISTS green_list_status_seq
CREATE SEQUENCE green_list_status_seq AS INT START WITH 1

CREATE OR REPLACE FUNCTION stg_green_list_status_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('green_list_status_seq'); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_stg_green_list_status ON stg_green_list_status
CREATE TRIGGER trig_stg_green_list_status BEFORE INSERT ON stg_green_list_status FOR EACH ROW EXECUTE procedure stg_green_list_status_id();

INSERT INTO stg_green_list_status(DESCRIPTION, ORIGINATOR_ID) VALUES('Candidate', 10000);
INSERT INTO stg_green_list_status(DESCRIPTION, ORIGINATOR_ID) VALUES('Green Listed', 10000);
INSERT INTO stg_green_list_status(DESCRIPTION, ORIGINATOR_ID) VALUES('Relisted', 10000);

