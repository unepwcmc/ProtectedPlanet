DELETE FROM stg_fpic_cat;
DROP SEQUENCE IF EXISTS stg_fpic_cat_seq;
CREATE SEQUENCE stg_fpic_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_fpic_category_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_fpic_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_fpic_category_id ON stg_fpic_cat;
CREATE TRIGGER trig_fpic_category_id BEFORE INSERT ON stg_fpic_cat FOR EACH ROW EXECUTE procedure stg_fpic_category_id();
INSERT INTO stg_fpic_cat(DESCRIPTION) SELECT DISTINCT fpic from icca_jun2023;

DELETE FROM stg_case_study_published_cat;
DROP SEQUENCE IF EXISTS stg_case_study_pub_cat_seq;
CREATE SEQUENCE stg_case_study_pub_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_case_study_pub_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_case_study_pub_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_case_study_pub_cat_id ON stg_case_study_published_cat;
CREATE TRIGGER trig_stg_case_study_pub_cat_id BEFORE INSERT ON stg_case_study_published_cat FOR EACH ROW EXECUTE procedure stg_case_study_pub_cat_id();
INSERT INTO stg_case_study_published_cat(DESCRIPTION) SELECT DISTINCT case_study_published from icca_jun2023;


DROP SEQUENCE IF EXISTS stg_verified_cat_seq;
CREATE SEQUENCE stg_verified_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_verified_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_verified_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_verified_cat_id ON stg_verified_cat;
CREATE TRIGGER trig_stg_verified_cat_id BEFORE INSERT ON stg_verified_cat FOR EACH ROW EXECUTE procedure stg_verified_cat_id();
DELETE FROM stg_verified_cat;
INSERT INTO stg_verified_cat(DESCRIPTION) SELECT DISTINCT verified from icca_jun2023;

DELETE FROM stg_no_take_permanency_cat;
DROP SEQUENCE IF EXISTS stg_no_take_perm_cat_seq;
CREATE SEQUENCE stg_no_take_perm_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_no_take_perm_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_no_take_perm_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_no_take_perm_cat_id ON stg_no_take_permanency_cat;
CREATE TRIGGER trig_stg_no_take_perm_cat_id BEFORE INSERT ON stg_no_take_permanency_cat FOR EACH ROW EXECUTE procedure stg_no_take_perm_cat_id();
INSERT INTO stg_no_take_permanency_cat(DESCRIPTION) SELECT DISTINCT no_take_permanency from icca_jun2023;

DELETE FROM stg_governance_council_cat;
DROP SEQUENCE IF EXISTS stg_gov_coun_cat_seq;
CREATE SEQUENCE stg_gov_coun_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_gov_coun_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_gov_coun_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_gov_coun_cat_id ON stg_governance_council_cat;
CREATE TRIGGER trig_stg_gov_coun_cat_id BEFORE INSERT ON stg_governance_council_cat FOR EACH ROW EXECUTE procedure stg_gov_coun_cat_id();
INSERT INTO stg_governance_council_cat(DESCRIPTION) SELECT DISTINCT governance_council from icca_jun2023;

DELETE FROM stg_governance_type_cat;
DROP SEQUENCE IF EXISTS stg_gov_type_cat_seq;
CREATE SEQUENCE stg_gov_type_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_gov_type_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_gov_type_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_gov_type_cat_id ON stg_governance_type_cat;
CREATE TRIGGER trig_stg_gov_type_cat_id BEFORE INSERT ON stg_governance_type_cat FOR EACH ROW EXECUTE procedure stg_gov_type_cat_id();
INSERT INTO stg_governance_type_cat(DESCRIPTION) SELECT DISTINCT governance_type from icca_jun2023;

DELETE FROM stg_internal_recognition_cat;
DROP SEQUENCE IF EXISTS stg_internal_recognition_cat_seq;
CREATE SEQUENCE stg_internal_recognition_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_internal_recognition_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_internal_recognition_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_internal_recognition_cat_id ON stg_internal_recognition_cat;
CREATE TRIGGER trig_stg_internal_recognition_cat_id BEFORE INSERT ON stg_internal_recognition_cat FOR EACH ROW EXECUTE procedure stg_internal_recognition_cat_id();
INSERT INTO stg_internal_recognition_cat(DESCRIPTION) SELECT DISTINCT internal_recognition from icca_jun2023;

DELETE FROM stg_external_recognition_cat;
DROP SEQUENCE IF EXISTS stg_external_recognition_cat_seq;
CREATE SEQUENCE stg_external_recognition_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_external_recognition_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_external_recognition_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_external_recognition_cat_id ON stg_external_recognition_cat;
CREATE TRIGGER trig_stg_external_recognition_cat_id BEFORE INSERT ON stg_external_recognition_cat FOR EACH ROW EXECUTE procedure stg_external_recognition_cat_id();
INSERT INTO stg_external_recognition_cat(DESCRIPTION) SELECT DISTINCT external_recognition from icca_jun2023;

DELETE FROM stg_community_decisions_cat;
DROP SEQUENCE IF EXISTS stg_comm_decisions_cat_seq;
CREATE SEQUENCE stg_comm_decisions_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_comm_decisions_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_comm_decisions_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_comm_decisions_cat_id ON stg_community_decisions_cat;
CREATE TRIGGER trig_stg_comm_decisions_cat_id BEFORE INSERT ON stg_community_decisions_cat FOR EACH ROW EXECUTE procedure stg_comm_decisions_cat_id();
INSERT INTO stg_community_decisions_cat(DESCRIPTION) SELECT DISTINCT community_decisions from icca_jun2023;

DELETE FROM stg_ownership_type_cat;
DROP SEQUENCE IF EXISTS stg_ownership_type_cat_seq;
CREATE SEQUENCE stg_ownership_type_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_ownership_type_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_ownership_type_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_ownership_type_cat_id ON stg_ownership_type_cat;
CREATE TRIGGER trig_stg_ownership_type_cat_id BEFORE INSERT ON stg_ownership_type_cat FOR EACH ROW EXECUTE procedure stg_ownership_type_cat_id();
INSERT INTO stg_ownership_type_cat(DESCRIPTION) SELECT DISTINCT ownership_type from icca_jun2023;

DELETE FROM stg_mgmt_authority_cat;
DROP SEQUENCE IF EXISTS stg_mgmt_authority_cat_seq;
CREATE SEQUENCE stg_mgmt_authority_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_mgmt_authority_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_mgmt_authority_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_mgmt_authority_cat_id ON stg_mgmt_authority_cat;
CREATE TRIGGER trig_stg_mgmt_authority_cat_id BEFORE INSERT ON stg_mgmt_authority_cat FOR EACH ROW EXECUTE procedure stg_mgmt_authority_cat_id();
INSERT INTO stg_mgmt_authority_cat(DESCRIPTION) SELECT DISTINCT management_authority from icca_jun2023;

DELETE FROM stg_mgmt_plan_format_cat;
DROP SEQUENCE IF EXISTS stg_mgmt_plan_format_cat_seq;
CREATE SEQUENCE stg_mgmt_plan_format_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_mgmt_plan_format_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_mgmt_plan_format_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_mgmt_plan_format_cat_id ON stg_mgmt_plan_format_cat;
CREATE TRIGGER trig_stg_mgmt_plan_format_cat_id BEFORE INSERT ON stg_mgmt_plan_format_cat FOR EACH ROW EXECUTE procedure stg_mgmt_plan_format_cat_id();
INSERT INTO stg_mgmt_plan_format_cat(DESCRIPTION) SELECT DISTINCT management_plan from icca_jun2023;

DELETE FROM stg_community_identity_cat;
DROP SEQUENCE IF EXISTS stg_community_identity_cat_seq;
CREATE SEQUENCE stg_community_identity_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_community_identity_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_community_identity_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_community_identity_cat_id ON stg_community_identity_cat;
CREATE TRIGGER trig_stg_community_identity_cat_id BEFORE INSERT ON stg_community_identity_cat FOR EACH ROW EXECUTE procedure stg_community_identity_cat_id();
INSERT INTO stg_community_identity_cat(DESCRIPTION) SELECT DISTINCT community_identity from icca_jun2023;

DELETE FROM stg_community_mobility_cat;
DROP SEQUENCE IF EXISTS stg_community_mobility_cat_seq;
CREATE SEQUENCE stg_community_mobility_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_community_mobility_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_community_mobility_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_community_mobility_cat_id ON stg_community_mobility_cat;
CREATE TRIGGER trig_stg_community_mobility_cat_id BEFORE INSERT ON stg_community_mobility_cat FOR EACH ROW EXECUTE procedure stg_community_mobility_cat_id();
INSERT INTO stg_community_mobility_cat(DESCRIPTION) SELECT DISTINCT community_mobility from icca_jun2023;

DELETE FROM stg_comm_mob_bey_cat;
DROP SEQUENCE IF EXISTS stg_comm_mob_bey_cat_seq;
CREATE SEQUENCE stg_comm_mob_bey_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_comm_mob_bey_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_comm_mob_bey_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_comm_mob_bey_cat_id ON stg_comm_mob_bey_cat;
CREATE TRIGGER trig_stg_comm_mob_bey_cat_id BEFORE INSERT ON stg_comm_mob_bey_cat FOR EACH ROW EXECUTE procedure stg_comm_mob_bey_cat_id();
INSERT INTO stg_comm_mob_bey_cat(DESCRIPTION) SELECT DISTINCT community_mobility_beyond_icca from icca_jun2023;

DELETE FROM stg_habitat_types_glb_cat;
DROP SEQUENCE IF EXISTS stg_habitat_types_glb_cat_seq;
CREATE SEQUENCE stg_habitat_types_glb_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_habitat_types_glb_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_habitat_types_glb_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_habitat_types_glb_cat_id ON stg_habitat_types_glb_cat;
CREATE TRIGGER trig_stg_habitat_types_glb_cat_id BEFORE INSERT ON stg_habitat_types_glb_cat FOR EACH ROW EXECUTE procedure stg_habitat_types_glb_cat_id();
INSERT INTO stg_habitat_types_glb_cat(DESCRIPTION) select DISTINCT trim(e'\n ' from unnest(string_to_array(habitat_types_global, ';'))) FROM icca_jun2023;

DELETE FROM stg_objectives_cat;
DROP SEQUENCE IF EXISTS stg_objectives_cat_seq;
CREATE SEQUENCE stg_objectives_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_objectives_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_objectives_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_objectives_cat_id ON stg_objectives_cat;
CREATE TRIGGER trig_stg_objectives_cat_id BEFORE INSERT ON stg_objectives_cat FOR EACH ROW EXECUTE procedure stg_objectives_cat_id();
INSERT INTO stg_objectives_cat(DESCRIPTION) select DISTINCT trim(e'\n ' from unnest(string_to_array(objectives, ';'))) FROM icca_jun2023;

DELETE FROM stg_resource_use_cat;
DROP SEQUENCE IF EXISTS stg_resource_use_cat_seq;
CREATE SEQUENCE stg_resource_use_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_resource_use_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_resource_use_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_resource_use_cat_id ON stg_resource_use_cat;
CREATE TRIGGER trig_stg_resource_use_cat_id BEFORE INSERT ON stg_resource_use_cat FOR EACH ROW EXECUTE procedure stg_resource_use_cat_id();
INSERT INTO stg_resource_use_cat(DESCRIPTION) select DISTINCT trim(e'\n ' from unnest(string_to_array(resource_use, ';'))) FROM icca_jun2023;

DELETE FROM stg_res_use_comm_cat;
DROP SEQUENCE IF EXISTS stg_res_use_comm_cat_seq;
CREATE SEQUENCE stg_res_use_comm_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_res_use_comm_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_res_use_comm_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_res_use_comm_cat_id ON stg_res_use_comm_cat;
CREATE TRIGGER trig_stg_res_use_comm_cat_id BEFORE INSERT ON stg_res_use_comm_cat FOR EACH ROW EXECUTE procedure stg_res_use_comm_cat_id();
INSERT INTO stg_res_use_comm_cat(DESCRIPTION) select DISTINCT trim(e'\n ' from unnest(string_to_array(resource_use_within_comm, ';'))) FROM icca_jun2023;

DELETE FROM stg_comm_rights_cat;
DROP SEQUENCE IF EXISTS stg_comm_rights_cat_seq;
CREATE SEQUENCE stg_comm_rights_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_comm_rights_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_comm_rights_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_comm_rights_cat_id ON stg_comm_rights_cat;
CREATE TRIGGER trig_stg_comm_rights_cat_id BEFORE INSERT ON stg_comm_rights_cat FOR EACH ROW EXECUTE procedure stg_comm_rights_cat_id();
INSERT INTO stg_comm_rights_cat(DESCRIPTION) select DISTINCT trim(e'\n ' from unnest(string_to_array(community_rights, ';'))) FROM icca_jun2023;

DELETE FROM stg_equal_access_cat;
DROP SEQUENCE IF EXISTS stg_equal_access_cat_seq;
CREATE SEQUENCE stg_equal_access_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_equal_access_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_equal_access_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_equal_access_cat_id ON stg_equal_access_cat;
CREATE TRIGGER trig_stg_equal_access_cat_id BEFORE INSERT ON stg_equal_access_cat FOR EACH ROW EXECUTE procedure stg_equal_access_cat_id();
INSERT INTO stg_equal_access_cat(DESCRIPTION) SELECT DISTINCT equal_access from icca_jun2023;

DELETE FROM stg_icca_providers_cat;
DROP SEQUENCE IF EXISTS stg_icca_providers_cat_seq;
CREATE SEQUENCE stg_icca_providers_cat_seq AS INT START WITH 1;
CREATE OR REPLACE FUNCTION stg_icca_providers_cat_id() RETURNS TRIGGER LANGUAGE PLPGSQL AS $$ BEGIN IF NEW.id is NULL THEN NEW.id = nextval('stg_icca_providers_cat_seq'); END IF; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trig_stg_icca_providers_cat_id ON stg_icca_providers_cat;
CREATE TRIGGER trig_stg_icca_providers_cat_id BEFORE INSERT ON stg_icca_providers_cat FOR EACH ROW EXECUTE procedure stg_icca_providers_cat_id();
INSERT INTO stg_icca_providers_cat(DESCRIPTION) SELECT DISTINCT responsible_party_category from icca_jun2023


CREATE OR REPLACE FUNCTION get_icca_fpic(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from fpic_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_icca_verified(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from verified_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_icca_case_study_published(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from case_study_published_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_no_take_permanency(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from no_take_permanency_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_internal_recognition(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from internal_recognition_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_external_recognition(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from external_recognition_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_governance_council(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from governance_council_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_governance_type(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description varchar(10000); begin SELECT a.description into description from governance_type_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_community_decisions(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description text; begin SELECT a.description into description from community_decisions_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_ownership_type(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description text; begin SELECT a.description into description from ownership_type_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_management_authority(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description text; begin SELECT a.description into description from mgmt_authority_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_management_plan_format(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description text; begin SELECT a.description into description from mgmt_plan_format_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_community_identity(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description text; begin SELECT a.description into description from community_identity_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_community_mobility(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description text; begin SELECT a.description into description from community_mobility_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_community_mob_bey_icca(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description text; begin SELECT a.description into description from comm_mob_bey_cat a where a.id = code_in; return description; end; $$
CREATE OR REPLACE FUNCTION get_equal_access(code_in int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare description text; begin SELECT a.description into description from equal_access_cat a where a.id = code_in; return description; end; $$

DROP FUNCTION get_icca_objectives_string;
DROP FUNCTION get_icca_habitat_types_string;
DROP FUNCTION get_icca_resource_use_string;
DROP FUNCTION get_icca_comm_rights_string;
DROP FUNCTION get_icca_res_use_comm_string;
DROP FUNCTION get_icca_iso3_string;
CREATE OR REPLACE FUNCTION get_icca_iso3_string(in_id int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare iso3_string varchar(255); begin SELECT array_to_string(array_agg(distinct code), ';') into iso3_string from icca_iso3_a a, iso3 b where a.id = b.id and a.icca_id = in_id; return iso3_string; end; $$
CREATE OR REPLACE FUNCTION get_icca_objectives_string(in_id int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare objectives_string text; begin SELECT array_to_string(array_agg(distinct description), ';') into objectives_string from icca_objectives_cat_a a, objectives_cat b where a.id = b.id and a.icca_id = in_id; return objectives_string; end; $$
CREATE OR REPLACE FUNCTION get_icca_habitat_types_string(in_id int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare habitat_types_string text; begin SELECT array_to_string(array_agg(distinct description), ';') into habitat_types_string from icca_habitat_types_glb_cat_a a, habitat_types_glb_cat b where a.id = b.id and a.icca_id = in_id; return habitat_types_string; end; $$
CREATE OR REPLACE FUNCTION get_icca_resource_use_string(in_id int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare resource_use_string text; begin SELECT array_to_string(array_agg(distinct description), ';') into resource_use_string from icca_resource_use_cat_a a, resource_use_cat b where a.id = b.id and a.icca_id = in_id; return resource_use_string; end; $$
CREATE OR REPLACE FUNCTION get_icca_comm_rights_string(in_id int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare comm_rights_string text; begin SELECT array_to_string(array_agg(distinct description), ';') into comm_rights_string from icca_comm_rights_cat_a a, comm_rights_cat b where a.id = b.id and a.icca_id = in_id; return comm_rights_string; end; $$
CREATE OR REPLACE FUNCTION get_icca_res_use_comm_string(in_id int) RETURNS TEXT LANGUAGE PLPGSQL AS $$ declare res_use_comm_string text; begin SELECT array_to_string(array_agg(distinct description), ';') into res_use_comm_string from icca_res_use_comm_cat_a a, res_use_comm_cat b where a.id = b.id and a.icca_id = in_id; return res_use_comm_string; end; $$