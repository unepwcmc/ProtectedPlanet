DROP SEQUENCE IF EXISTS pame_providers_seq
CREATE SEQUENCE pame_providers_seq AS INT START WITH 1

CREATE OR REPLACE FUNCTION stg_pame_providers_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('pame_providers_seq'); END IF; RETURN NEW; END; $$
DROP TRIGGER IF EXISTS trig_stg_pame_providers ON stg_pame_providers
CREATE TRIGGER trig_stg_pame_providers BEFORE INSERT ON stg_pame_providers FOR EACH ROW EXECUTE procedure stg_pame_providers_id();