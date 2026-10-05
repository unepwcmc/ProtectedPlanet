-- Local stand-in for the portal FDW schema, for the test database only.
--
-- In staging and production portal_fdw is a postgres_fdw FOREIGN schema reading
-- the Data Management Portal database. The test database has no portal database
-- to point at, so this recreates the same 50 tables as ordinary local tables.
-- FDW_VIEWS.sql and the importers only ever SELECT from portal_fdw.*, and SQL does
-- not care whether a relation is foreign or local, so the release path runs
-- unchanged against them.
--
-- GENERATED — do not hand-edit. Regenerate when the portal schema changes:
--   bin/rails pp:test:regenerate_portal_fdw_schema
-- which runs `pg_dump --schema-only -n portal_fdw` against a database that has
-- the real foreign schema (a dev database set up per docs/fdw_setup/local.md),
-- converts CREATE FOREIGN TABLE to CREATE TABLE IF NOT EXISTS, and drops the
-- SERVER/OPTIONS clauses and the ALTER FOREIGN TABLE column/owner statements,
-- none of which mean anything without a foreign server.
--
-- IF NOT EXISTS keeps loading idempotent: the tests load this inside their own
-- transaction, and a developer database may already have it.

CREATE SCHEMA IF NOT EXISTS portal_fdw;

CREATE TABLE IF NOT EXISTS portal_fdw.character_set_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.conservation_objective_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.data_restriction_levels (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.designation_eng_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer,
    sub_group character varying
);

CREATE TABLE IF NOT EXISTS portal_fdw.designation_purpose_biodiversity_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.designation_purpose_other_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.designation_type_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.governance_action_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.governance_assessment_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.governance_subtype_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer,
    sub_group character varying
);

CREATE TABLE IF NOT EXISTS portal_fdw.governance_type_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.greenlist_status_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.greenlists (
    id bigint NOT NULL,
    site_id bigint NOT NULL,
    parcel_id character varying(20) NOT NULL,
    gl_status_id bigint NOT NULL,
    gl_expiry integer NOT NULL,
    gl_link text NOT NULL,
    archived_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    wdpa_id bigint
);

CREATE TABLE IF NOT EXISTS portal_fdw.inland_waters_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.international_criteria_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer,
    sub_group character varying
);

CREATE TABLE IF NOT EXISTS portal_fdw.iso3 (
    id integer NOT NULL,
    code character varying(2047) NOT NULL,
    description character varying(2047),
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.iucn_category_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.language_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.management_adaptation_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.management_budget_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.management_monitoring_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.management_objectives_managed_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.management_objectives_set_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.management_staff_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.management_threats_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.method_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.no_take_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer,
    sub_group character varying
);

CREATE TABLE IF NOT EXISTS portal_fdw.oecm_assessment_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer,
    sub_group character varying
);

CREATE TABLE IF NOT EXISTS portal_fdw.outcomes_biodiversity_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.ownership_subtype_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer,
    sub_group character varying
);

CREATE TABLE IF NOT EXISTS portal_fdw.ownership_type_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer,
    sub_group character varying
);

CREATE TABLE IF NOT EXISTS portal_fdw.pame (
    id bigint NOT NULL,
    asmt_id bigint,
    site_id bigint NOT NULL,
    parcel_id text NOT NULL,
    pame_source_id bigint NOT NULL,
    method_id bigint,
    method_text character varying(500),
    asmt_year integer NOT NULL,
    verification_effectiveness_id bigint NOT NULL,
    asmt_url character varying(254),
    info_url character varying(254),
    governance_action_id bigint,
    governance_assessment_id bigint,
    designation_purpose_other_id bigint,
    management_objectives_set_id bigint,
    management_objectives_managed_id bigint,
    management_adaptation_id bigint,
    management_staff_id bigint,
    management_budget_id bigint,
    management_threats_id bigint,
    management_monitoring_id bigint,
    outcomes_biodiversity_id bigint,
    archived_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    submit_year integer,
    wdpa_id bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.pame_designation_purpose_biodiversity_cats (
    id bigint NOT NULL,
    pame_id bigint NOT NULL,
    designation_purpose_biodiversity_cat_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.pame_sources (
    id bigint NOT NULL,
    eff_metaid bigint,
    data_title character varying(254),
    resp_party character varying(254),
    resp_email character varying(254),
    year integer,
    language character varying(254),
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    resp_pers character varying(254)
);

CREATE TABLE IF NOT EXISTS portal_fdw.provider (
    id bigint NOT NULL,
    uuid uuid,
    responsible_party character varying(254)
);

CREATE TABLE IF NOT EXISTS portal_fdw.realm_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.site_type_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.source (
    id bigint NOT NULL,
    originator_id integer,
    data_title text,
    verifier character varying(510),
    update_year integer,
    language character varying(254),
    character_set character varying(254),
    provider_id bigint,
    reference_system text,
    lineage text,
    citation text,
    disclaimer text,
    scale character varying(510),
    year integer,
    resp_pers character varying(510),
    resp_email character varying(510),
    v_pers character varying(510),
    v_email character varying(510)
);

CREATE TABLE IF NOT EXISTS portal_fdw.spatial_data (
    id bigint NOT NULL,
    wdpa_id bigint,
    site_id bigint NOT NULL,
    geom public.geometry(Geometry,4326),
    shape_area double precision,
    shape_length double precision,
    latitude double precision,
    longitude double precision,
    is_polygon integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.status_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer,
    sub_group character varying
);

CREATE TABLE IF NOT EXISTS portal_fdw.verification_cat (
    id bigint NOT NULL,
    code character varying,
    description json,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.verification_effectiveness_cat (
    id bigint NOT NULL,
    code character varying,
    description jsonb,
    is_standard integer
);

CREATE TABLE IF NOT EXISTS portal_fdw.wdpa_governance_subtypes (
    id bigint NOT NULL,
    wdpa_id integer,
    governance_subtype_cat_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.wdpa_international_criteria (
    id bigint NOT NULL,
    wdpa_id integer,
    international_criteria_cat_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.wdpa_iso3 (
    id bigint NOT NULL,
    wdpa_id integer,
    iso3_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.wdpa_languages (
    id bigint NOT NULL,
    wdpa_id integer,
    language_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.wdpa_oecm_assessments (
    id bigint NOT NULL,
    wdpa_id integer,
    oecm_assessment_cat_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.wdpa_ownership_subtypes (
    id bigint NOT NULL,
    wdpa_id integer,
    ownership_subtype_cat_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.wdpa_parent_iso3 (
    id bigint NOT NULL,
    wdpa_id integer,
    parent_iso3_id integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE IF NOT EXISTS portal_fdw.wdpas (
    id bigint NOT NULL,
    site_id bigint,
    parcel_id text,
    latin_name character varying(254),
    original_name character varying(254),
    pa_def character varying(20),
    designation character varying(254),
    designation_english character varying(254),
    scale character varying,
    year integer,
    reported_marine_area double precision,
    gis_marine_area double precision,
    original_designation character varying,
    reported_area double precision,
    gis_area double precision,
    english_name character varying,
    no_take_area double precision,
    status_year integer,
    management_authority character varying(254),
    management_plan character varying(254),
    supplemental_info character varying(254),
    data_contributor_agreement_signed boolean,
    gdpr_agreed date,
    data_restriction_level_id integer,
    originator_id integer,
    english_designation_id bigint,
    source_id bigint,
    realm_id bigint,
    no_take_id bigint,
    iucn_category_id bigint,
    designation_type_id bigint,
    status_id bigint,
    governance_type_id bigint,
    ownership_type_id bigint,
    site_type_id bigint,
    verification_id bigint,
    language_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    character_set_id bigint,
    provider_id bigint,
    archived_at timestamp(6) without time zone,
    english_designation_text character varying,
    conservation_objective_id bigint,
    inland_waters_id integer
);
