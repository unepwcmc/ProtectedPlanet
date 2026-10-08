-- Local stand-in for the `stats` schema, which the stats server owns and manages in
-- real environments (PP only reads it, so no migration creates it and CI's
-- db:create db:migrate test database has no trace of it). Table definitions are
-- copied verbatim from db/structure.sql.
--
-- Idempotent, and loaded on the test's own connection inside its transaction, so it
-- rolls back with the test and is a no-op where the real schema already exists.

CREATE SCHEMA IF NOT EXISTS stats;

CREATE TABLE IF NOT EXISTS stats.global_stats (
    metadata_gs_uuid text NOT NULL,
    metadata_ns_uuid text NOT NULL,
    metadata_basemap text NOT NULL,
    metadata_grid text NOT NULL,
    metadata_vintage text NOT NULL,
    metadata_version text NOT NULL,
    metadata_universe text,
    metadata_author text,
    metadata_server text,
    metadata_run_timestamp timestamp with time zone NOT NULL,
    metadata jsonb,
    stat_type text NOT NULL,
    stat_description text,
    stat_value double precision
);

CREATE TABLE IF NOT EXISTS stats.national_stats (
    metadata_ns_uuid text NOT NULL,
    metadata_basemap text NOT NULL,
    metadata_grid text NOT NULL,
    metadata_vintage text NOT NULL,
    metadata_version text NOT NULL,
    metadata_universe text,
    metadata_author text,
    metadata_server text,
    metadata_run_timestamp timestamp with time zone NOT NULL,
    iso3 text NOT NULL,
    pa_marine numeric,
    pa_terrestrial numeric,
    oecm_marine numeric,
    oecm_terrestrial numeric,
    pa_oecm_marine numeric,
    pa_oecm_terrestrial numeric,
    total_marine numeric,
    total_terrestrial numeric,
    pa_marine_pct double precision,
    pa_terrestrial_pct double precision,
    oecm_marine_pct double precision,
    oecm_terrestrial_pct double precision,
    pa_oecm_marine_pct double precision,
    pa_oecm_terrestrial_pct double precision,
    metadata jsonb
);

CREATE TABLE IF NOT EXISTS stats.pame_stats (
    metadata_pame_uuid text NOT NULL,
    iso3 text NOT NULL,
    metadata jsonb,
    pame_pa_marine numeric,
    pame_pa_terrestrial numeric,
    pame_oecm_marine numeric,
    pame_oecm_terrestrial numeric,
    pame_pa_oecm_marine numeric,
    pame_pa_oecm_terrestrial numeric,
    total_marine numeric,
    total_terrestrial numeric,
    pame_pa_marine_pct double precision,
    pame_pa_terrestrial_pct double precision,
    pame_oecm_marine_pct double precision,
    pame_oecm_terrestrial_pct double precision,
    pame_pa_oecm_marine_pct double precision,
    pame_pa_oecm_terrestrial_pct double precision,
    ns_pa_marine numeric,
    ns_pa_terrestrial numeric,
    ns_oecm_marine numeric,
    ns_oecm_terrestrial numeric,
    ns_pa_oecm_marine numeric,
    ns_pa_oecm_terrestrial numeric,
    pame_pa_marine_pct_of_ns double precision,
    pame_pa_terrestrial_pct_of_ns double precision,
    pame_oecm_marine_pct_of_ns double precision,
    pame_oecm_terrestrial_pct_of_ns double precision,
    pame_pa_oecm_marine_pct_of_ns double precision,
    pame_pa_oecm_terrestrial_pct_of_ns double precision,
    metadata_basemap text NOT NULL,
    metadata_grid text NOT NULL,
    metadata_vintage text NOT NULL,
    metadata_version text NOT NULL,
    metadata_universe text,
    metadata_author text,
    metadata_server text,
    metadata_run_timestamp timestamp with time zone NOT NULL
);
