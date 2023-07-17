DELETE FROM staging_no_take
CREATE OR REPLACE FUNCTION staging_no_take_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = hashtext(NEW.description); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_staging_no_take ON staging_no_take
CREATE TRIGGER trig_staging_no_take BEFORE INSERT ON staging_no_take FOR EACH ROW EXECUTE procedure staging_no_take_id();

INSERT INTO staging_no_take(DESCRIPTION, ORIGINATOR_ID ) VALUES('Part', 10000 );
INSERT INTO staging_no_take(DESCRIPTION, ORIGINATOR_ID ) VALUES('Not Reported', 10000 );
INSERT INTO staging_no_take(DESCRIPTION, ORIGINATOR_ID ) VALUES('Not Applicable', 10000 );
INSERT INTO staging_no_take(DESCRIPTION, ORIGINATOR_ID ) VALUES('All', 10000 );
INSERT INTO staging_no_take(DESCRIPTION, ORIGINATOR_ID ) VALUES('All or Part', 10000 );
INSERT INTO staging_no_take(DESCRIPTION, ORIGINATOR_ID ) VALUES('None', 10000 );


