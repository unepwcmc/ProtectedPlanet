DELETE FROM staging_fpic_cat;
INSERT INTO staging_fpic_cat SELECT DISTINCT hashtext(fpic), fpic from icca_jun2023;

DELETE FROM staging_verification_cat;
INSERT INTO staging_verification_cat SELECT DISTINCT hashtext(verified), verified from icca_jun2023;

DELETE FROM staging_case_study_published_cat;
INSERT INTO staging_case_study_published_cat SELECT DISTINCT hashtext(case_study_published), case_study_published from icca_jun2023;

DELETE FROM staging_no_take_permanency_cat;
INSERT INTO staging_no_take_permanency_cat SELECT DISTINCT hashtext(no_take_permanency), no_take_permanency from icca_jun2023;

DELETE FROM staging_governance_council_cat;
INSERT INTO staging_governance_council_cat SELECT DISTINCT hashtext(governance_council), governance_council from icca_jun2023;

DELETE FROM staging_governance_type_cat;
INSERT INTO staging_governance_type_cat SELECT DISTINCT hashtext(governance_type), governance_type from icca_jun2023;

DELETE FROM staging_internal_recognition_cat;
INSERT INTO staging_internal_recognition_cat SELECT DISTINCT hashtext(internal_recognition), internal_recognition from icca_jun2023;

DELETE FROM staging_external_recognition_cat;
INSERT INTO staging_external_recognition_cat SELECT DISTINCT hashtext(external_recognition), external_recognition from icca_jun2023;

DELETE FROM staging_community_decisions_cat;
INSERT INTO staging_community_decisions_cat SELECT DISTINCT hashtext(community_decisions), community_decisions from icca_jun2023;

DELETE FROM staging_ownership_type_cat;
INSERT INTO staging_ownership_type_cat SELECT DISTINCT hashtext(ownership_type), ownership_type from icca_jun2023;

DELETE FROM staging_mgmt_authority_cat;
INSERT INTO staging_mgmt_authority_cat SELECT DISTINCT hashtext(management_authority), management_authority from icca_jun2023;

DELETE FROM staging_mgmt_plan_format_cat;
INSERT INTO staging_mgmt_plan_format_cat SELECT DISTINCT hashtext(management_plan), management_plan from icca_jun2023;

DELETE FROM staging_community_identity_cat;
INSERT INTO staging_community_identity_cat SELECT DISTINCT hashtext(community_identity), community_identity from icca_jun2023;

DELETE FROM staging_community_mobility_cat;
INSERT INTO staging_community_mobility_cat SELECT DISTINCT hashtext(community_mobility), community_mobility from icca_jun2023;

DELETE FROM staging_comm_mob_bey_icca_cat;
INSERT INTO staging_comm_mob_bey_icca_cat SELECT DISTINCT hashtext(community_mobility_beyond_icca), community_mobility_beyond_icca from icca_jun2023;

DELETE FROM staging_habitat_types_global_cat;
INSERT INTO staging_habitat_types_global_cat select DISTINCT hashtext(trim(e'\n ' from unnest(string_to_array(habitat_types_global, ';')))), trim(e'\n ' from unnest(string_to_array(habitat_types_global, ';'))) FROM icca_jun2023;

DELETE FROM staging_icca_objectives_cat;
INSERT INTO staging_icca_objectives_cat select DISTINCT hashtext(trim(e'\n ' from unnest(string_to_array(objectives, ';')))), trim(e'\n ' from unnest(string_to_array(objectives, ';'))) FROM icca_jun2023;

DELETE FROM staging_icca_resource_use_cat;
INSERT INTO staging_icca_resource_use_cat select DISTINCT hashtext(trim(e'\n ' from unnest(string_to_array(resource_use, ';')))), trim(e'\n ' from unnest(string_to_array(resource_use, ';'))) FROM icca_jun2023;

DELETE FROM staging_icca_res_use_comm_cat;
INSERT INTO staging_icca_res_use_comm_cat select DISTINCT hashtext(trim(e'\n ' from unnest(string_to_array(resource_use_within_comm, ';')))), trim(e'\n ' from unnest(string_to_array(resource_use_within_comm, ';'))) FROM icca_jun2023;

DELETE FROM staging_icca_comm_rights_cat;
INSERT INTO staging_icca_comm_rights_cat select DISTINCT hashtext(trim(e'\n ' from unnest(string_to_array(community_rights, ';')))), trim(e'\n ' from unnest(string_to_array(community_rights, ';'))) FROM icca_jun2023;

DELETE FROM staging_icca_equal_access_cat;
INSERT INTO staging_icca_equal_access_cat SELECT DISTINCT hashtext(equal_access), equal_access from icca_jun2023;

DELETE FROM staging_icca_providers_cat;
INSERT INTO staging_icca_providers_cat SELECT DISTINCT hashtext(responsible_party_category), responsible_party_category from icca_jun2023
