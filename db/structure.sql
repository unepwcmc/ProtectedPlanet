--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


SET search_path = public, pg_catalog;

--
-- Name: first_agg(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION first_agg(anyelement, anyelement) RETURNS anyelement
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
            SELECT $1;
          $_$;


--
-- Name: first(anyelement); Type: AGGREGATE; Schema: public; Owner: -
--

CREATE AGGREGATE first(anyelement) (
    SFUNC = first_agg,
    STYPE = anyelement
);


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries (
    id integer NOT NULL,
    name text,
    iso character varying(255),
    iso_3 character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    language character varying(255),
    region_id integer,
    bounding_box geometry,
    marine_pas_geom geometry,
    land_pas_geom geometry,
    land_geom geometry,
    eez_geom geometry,
    ts_geom geometry,
    marine_ts_pas_geom geometry,
    marine_eez_pas_geom geometry
);


--
-- Name: countries_geometries_temp; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries_geometries_temp (
    the_geom geometry,
    iso_3 text,
    type character varying
);


--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE countries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE countries_id_seq OWNED BY countries.id;


--
-- Name: countries_protected_areas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE countries_protected_areas (
    protected_area_id integer,
    country_id integer
);


--
-- Name: country_statistics; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE country_statistics (
    id integer NOT NULL,
    country_id integer,
    pa_area double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    eez_area double precision,
    ts_area double precision,
    pa_land_area double precision,
    pa_marine_area double precision,
    percentage_pa_land_cover double precision,
    percentage_pa_eez_cover double precision,
    percentage_pa_ts_cover double precision,
    land_area double precision,
    percentage_pa_cover double precision,
    pa_eez_area double precision,
    pa_ts_area double precision
);


--
-- Name: country_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE country_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: country_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE country_statistics_id_seq OWNED BY country_statistics.id;


--
-- Name: designations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE designations (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    jurisdiction_id integer
);


--
-- Name: designations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE designations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: designations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE designations_id_seq OWNED BY designations.id;


--
-- Name: governances; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE governances (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: governances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE governances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: governances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE governances_id_seq OWNED BY governances.id;


--
-- Name: images; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE images (
    id integer NOT NULL,
    url text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    title text,
    lonlat geography(Point,4326),
    protected_area_id integer,
    details_url text
);


--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE images_id_seq OWNED BY images.id;


--
-- Name: standard_points; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE standard_points (
    ogc_fid integer NOT NULL,
    wkb_geometry geometry(MultiPoint,4326),
    wdpaid integer,
    wdpa_pid integer,
    name character varying,
    orig_name character varying,
    sub_loc character varying,
    desig character varying,
    desig_eng character varying,
    desig_type character varying,
    iucn_cat character varying,
    int_crit character varying,
    marine character varying,
    rep_m_area double precision,
    rep_area double precision,
    status character varying,
    status_yr integer,
    gov_type character varying,
    mang_auth character varying,
    mang_plan character varying,
    no_take character varying,
    no_tk_area double precision,
    metadataid integer,
    iso3 character varying,
    parent_iso3 character varying,
    buffer_geom geometry
);


--
-- Name: standard_polygons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE standard_polygons (
    ogc_fid integer NOT NULL,
    wkb_geometry geometry(MultiPolygon,4326),
    wdpaid integer,
    wdpa_pid integer,
    name character varying,
    orig_name character varying,
    sub_loc character varying,
    desig character varying,
    desig_eng character varying,
    desig_type character varying,
    iucn_cat character varying,
    int_crit character varying,
    marine character varying,
    rep_m_area double precision,
    gis_m_area double precision,
    rep_area double precision,
    gis_area double precision,
    status character varying,
    status_yr integer,
    gov_type character varying,
    mang_auth character varying,
    mang_plan character varying,
    no_take character varying,
    no_tk_area double precision,
    metadataid integer,
    parent_iso3 character varying,
    iso3 character varying,
    shape_length double precision,
    shape_area double precision
);


--
-- Name: imported_protected_areas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW imported_protected_areas AS
         SELECT standard_polygons.wdpaid,
            standard_polygons.wdpa_pid,
            standard_polygons.name,
            standard_polygons.orig_name,
            standard_polygons.marine,
            standard_polygons.rep_m_area,
            standard_polygons.rep_area,
            standard_polygons.iso3,
            standard_polygons.sub_loc,
            standard_polygons.status,
            standard_polygons.status_yr,
            standard_polygons.iucn_cat,
            standard_polygons.gov_type,
            standard_polygons.mang_auth,
            standard_polygons.mang_plan,
            standard_polygons.int_crit,
            standard_polygons.no_take,
            standard_polygons.no_tk_area,
            standard_polygons.desig,
            standard_polygons.desig_type,
            standard_polygons.wkb_geometry
           FROM standard_polygons
UNION ALL
         SELECT standard_points.wdpaid,
            standard_points.wdpa_pid,
            standard_points.name,
            standard_points.orig_name,
            standard_points.marine,
            standard_points.rep_m_area,
            standard_points.rep_area,
            standard_points.iso3,
            standard_points.sub_loc,
            standard_points.status,
            standard_points.status_yr,
            standard_points.iucn_cat,
            standard_points.gov_type,
            standard_points.mang_auth,
            standard_points.mang_plan,
            standard_points.int_crit,
            standard_points.no_take,
            standard_points.no_tk_area,
            standard_points.desig,
            standard_points.desig_type,
            standard_points.wkb_geometry
           FROM standard_points;


--
-- Name: iucn_categories; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE iucn_categories (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: iucn_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE iucn_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: iucn_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE iucn_categories_id_seq OWNED BY iucn_categories.id;


--
-- Name: jurisdictions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE jurisdictions (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: jurisdictions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE jurisdictions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jurisdictions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE jurisdictions_id_seq OWNED BY jurisdictions.id;


--
-- Name: legacy_protected_areas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE legacy_protected_areas (
    id integer NOT NULL,
    wdpa_id integer,
    slug text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: legacy_protected_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE legacy_protected_areas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legacy_protected_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE legacy_protected_areas_id_seq OWNED BY legacy_protected_areas.id;


--
-- Name: legal_statuses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE legal_statuses (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: legal_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE legal_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legal_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE legal_statuses_id_seq OWNED BY legal_statuses.id;


--
-- Name: management_authorities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE management_authorities (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: management_authorities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE management_authorities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: management_authorities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE management_authorities_id_seq OWNED BY management_authorities.id;


--
-- Name: no_take_statuses; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE no_take_statuses (
    id integer NOT NULL,
    name character varying(255),
    area numeric,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: no_take_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE no_take_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: no_take_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE no_take_statuses_id_seq OWNED BY no_take_statuses.id;


--
-- Name: protected_areas; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE protected_areas (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    the_geom geometry,
    wdpa_id integer,
    wdpa_parent_id integer,
    name text,
    original_name text,
    marine boolean,
    reported_marine_area numeric,
    reported_area numeric,
    gis_area numeric,
    gis_marine_area numeric,
    legal_status_id integer,
    legal_status_updated_at timestamp without time zone,
    iucn_category_id integer,
    governance_id integer,
    management_plan text,
    management_authority_id integer,
    international_criteria character varying(255),
    no_take_status_id integer,
    designation_id integer,
    slug text,
    wikipedia_article_id integer
);


--
-- Name: protected_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE protected_areas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: protected_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE protected_areas_id_seq OWNED BY protected_areas.id;


--
-- Name: protected_areas_sub_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE protected_areas_sub_locations (
    protected_area_id integer,
    sub_location_id integer
);


--
-- Name: regional_statistics; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE regional_statistics (
    id integer NOT NULL,
    region_id integer,
    area double precision,
    pa_area double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    eez_area double precision,
    ts_area double precision,
    pa_land_area double precision,
    pa_marine_area double precision,
    percentage_land double precision,
    percentage_pa_land_cover double precision,
    percentage_pa_eez_cover double precision,
    percentage_pa_ts_cover double precision,
    land_area double precision,
    percentage_pa_cover double precision,
    pa_eez_area double precision,
    pa_ts_area double precision
);


--
-- Name: regional_statistics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE regional_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regional_statistics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE regional_statistics_id_seq OWNED BY regional_statistics.id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE regions (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    iso character varying(255),
    bounding_box geometry
);


--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE regions_id_seq OWNED BY regions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: search_lexemes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE search_lexemes (
    word text
);


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sources (
    id integer NOT NULL,
    title character varying(255),
    responsible_party character varying(255),
    responsible_email character varying(255),
    year date,
    language character varying(255),
    character_set character varying(255),
    reference_system character varying(255),
    scale character varying(255),
    lineage text,
    citation text,
    disclaimer text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sources_id_seq OWNED BY sources.id;


--
-- Name: standard_points_ogc_fid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE standard_points_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: standard_points_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE standard_points_ogc_fid_seq OWNED BY standard_points.ogc_fid;


--
-- Name: standard_polygons_ogc_fid_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE standard_polygons_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: standard_polygons_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE standard_polygons_ogc_fid_seq OWNED BY standard_polygons.ogc_fid;


--
-- Name: sub_locations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sub_locations (
    id integer NOT NULL,
    english_name character varying(255),
    local_name character varying(255),
    alternate_name character varying(255),
    iso character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    country_id integer
);


--
-- Name: sub_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sub_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE sub_locations_id_seq OWNED BY sub_locations.id;


--
-- Name: tsvector_search_documents; Type: MATERIALIZED VIEW; Schema: public; Owner: -; Tablespace: 
--

CREATE MATERIALIZED VIEW tsvector_search_documents AS
 SELECT pa.wdpa_id,
    (((setweight(to_tsvector('english'::regconfig, COALESCE(first(pa.name), ''::text)), 'A'::"char") || setweight(to_tsvector(COALESCE((first(c.language))::regconfig, 'simple'::regconfig), COALESCE(unaccent(first(pa.original_name)), ''::text)), 'B'::"char")) || setweight(to_tsvector('english'::regconfig, COALESCE(string_agg(c.name, ' '::text), ''::text)), 'C'::"char")) || setweight(to_tsvector('english'::regconfig, COALESCE(string_agg((sl.english_name)::text, ' '::text), ''::text)), 'D'::"char")) AS document
   FROM (((protected_areas pa
   LEFT JOIN countries_protected_areas cpa ON ((cpa.protected_area_id = pa.id)))
   LEFT JOIN countries c ON ((cpa.country_id = c.id)))
   LEFT JOIN sub_locations sl ON ((c.id = sl.country_id)))
  GROUP BY pa.wdpa_id
  WITH NO DATA;


--
-- Name: wikipedia_articles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE wikipedia_articles (
    id integer NOT NULL,
    summary text,
    url character varying(255),
    image_url character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: wikipedia_articles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE wikipedia_articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wikipedia_articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE wikipedia_articles_id_seq OWNED BY wikipedia_articles.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY countries ALTER COLUMN id SET DEFAULT nextval('countries_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY country_statistics ALTER COLUMN id SET DEFAULT nextval('country_statistics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY designations ALTER COLUMN id SET DEFAULT nextval('designations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY governances ALTER COLUMN id SET DEFAULT nextval('governances_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY images ALTER COLUMN id SET DEFAULT nextval('images_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY iucn_categories ALTER COLUMN id SET DEFAULT nextval('iucn_categories_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY jurisdictions ALTER COLUMN id SET DEFAULT nextval('jurisdictions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY legacy_protected_areas ALTER COLUMN id SET DEFAULT nextval('legacy_protected_areas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY legal_statuses ALTER COLUMN id SET DEFAULT nextval('legal_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY management_authorities ALTER COLUMN id SET DEFAULT nextval('management_authorities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY no_take_statuses ALTER COLUMN id SET DEFAULT nextval('no_take_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY protected_areas ALTER COLUMN id SET DEFAULT nextval('protected_areas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY regional_statistics ALTER COLUMN id SET DEFAULT nextval('regional_statistics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY regions ALTER COLUMN id SET DEFAULT nextval('regions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sources ALTER COLUMN id SET DEFAULT nextval('sources_id_seq'::regclass);


--
-- Name: ogc_fid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY standard_points ALTER COLUMN ogc_fid SET DEFAULT nextval('standard_points_ogc_fid_seq'::regclass);


--
-- Name: ogc_fid; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY standard_polygons ALTER COLUMN ogc_fid SET DEFAULT nextval('standard_polygons_ogc_fid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY sub_locations ALTER COLUMN id SET DEFAULT nextval('sub_locations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY wikipedia_articles ALTER COLUMN id SET DEFAULT nextval('wikipedia_articles_id_seq'::regclass);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: country_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY country_statistics
    ADD CONSTRAINT country_statistics_pkey PRIMARY KEY (id);


--
-- Name: designations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY designations
    ADD CONSTRAINT designations_pkey PRIMARY KEY (id);


--
-- Name: governances_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY governances
    ADD CONSTRAINT governances_pkey PRIMARY KEY (id);


--
-- Name: images_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: iucn_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY iucn_categories
    ADD CONSTRAINT iucn_categories_pkey PRIMARY KEY (id);


--
-- Name: jurisdictions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY jurisdictions
    ADD CONSTRAINT jurisdictions_pkey PRIMARY KEY (id);


--
-- Name: legacy_protected_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY legacy_protected_areas
    ADD CONSTRAINT legacy_protected_areas_pkey PRIMARY KEY (id);


--
-- Name: legal_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY legal_statuses
    ADD CONSTRAINT legal_statuses_pkey PRIMARY KEY (id);


--
-- Name: management_authorities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY management_authorities
    ADD CONSTRAINT management_authorities_pkey PRIMARY KEY (id);


--
-- Name: no_take_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY no_take_statuses
    ADD CONSTRAINT no_take_statuses_pkey PRIMARY KEY (id);


--
-- Name: protected_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY protected_areas
    ADD CONSTRAINT protected_areas_pkey PRIMARY KEY (id);


--
-- Name: regional_statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY regional_statistics
    ADD CONSTRAINT regional_statistics_pkey PRIMARY KEY (id);


--
-- Name: regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- Name: standard_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY standard_points
    ADD CONSTRAINT standard_points_pkey PRIMARY KEY (ogc_fid);


--
-- Name: standard_polygons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY standard_polygons
    ADD CONSTRAINT standard_polygons_pkey PRIMARY KEY (ogc_fid);


--
-- Name: sub_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sub_locations
    ADD CONSTRAINT sub_locations_pkey PRIMARY KEY (id);


--
-- Name: wikipedia_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY wikipedia_articles
    ADD CONSTRAINT wikipedia_articles_pkey PRIMARY KEY (id);


--
-- Name: index_countries_on_eez_geom; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_on_eez_geom ON countries USING gist (eez_geom);


--
-- Name: index_countries_on_land_geom; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_on_land_geom ON countries USING gist (land_geom);


--
-- Name: index_countries_on_land_pas_geom; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_on_land_pas_geom ON countries USING gist (land_pas_geom);


--
-- Name: index_countries_on_marine_eez_pas_geom; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_on_marine_eez_pas_geom ON countries USING gist (marine_eez_pas_geom);


--
-- Name: index_countries_on_marine_pas_geom; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_on_marine_pas_geom ON countries USING gist (marine_pas_geom);


--
-- Name: index_countries_on_marine_ts_pas_geom; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_on_marine_ts_pas_geom ON countries USING gist (marine_ts_pas_geom);


--
-- Name: index_countries_on_ts_geom; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_on_ts_geom ON countries USING gist (ts_geom);


--
-- Name: index_countries_protected_areas_composite; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_protected_areas_composite ON countries_protected_areas USING btree (protected_area_id, country_id);


--
-- Name: index_countries_protected_areas_on_country_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_countries_protected_areas_on_country_id ON countries_protected_areas USING btree (country_id);


--
-- Name: index_designations_on_jurisdiction_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_designations_on_jurisdiction_id ON designations USING btree (jurisdiction_id);


--
-- Name: index_images_on_protected_area_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_images_on_protected_area_id ON images USING btree (protected_area_id);


--
-- Name: index_protected_areas_on_designation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_on_designation_id ON protected_areas USING btree (designation_id);


--
-- Name: index_protected_areas_on_governance_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_on_governance_id ON protected_areas USING btree (governance_id);


--
-- Name: index_protected_areas_on_iucn_category_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_on_iucn_category_id ON protected_areas USING btree (iucn_category_id);


--
-- Name: index_protected_areas_on_legal_status_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_on_legal_status_id ON protected_areas USING btree (legal_status_id);


--
-- Name: index_protected_areas_on_management_authority_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_on_management_authority_id ON protected_areas USING btree (management_authority_id);


--
-- Name: index_protected_areas_on_no_take_status_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_on_no_take_status_id ON protected_areas USING btree (no_take_status_id);


--
-- Name: index_protected_areas_on_wdpa_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_protected_areas_on_wdpa_id ON protected_areas USING btree (wdpa_id);


--
-- Name: index_protected_areas_on_wdpa_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_on_wdpa_parent_id ON protected_areas USING btree (wdpa_parent_id);


--
-- Name: index_protected_areas_on_wikipedia_article_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_on_wikipedia_article_id ON protected_areas USING btree (wikipedia_article_id);


--
-- Name: index_protected_areas_sub_locations_composite; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_sub_locations_composite ON protected_areas_sub_locations USING btree (protected_area_id, sub_location_id);


--
-- Name: index_protected_areas_sub_locations_on_sub_location_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_protected_areas_sub_locations_on_sub_location_id ON protected_areas_sub_locations USING btree (sub_location_id);


--
-- Name: index_sub_locations_on_country_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sub_locations_on_country_id ON sub_locations USING btree (country_id);


--
-- Name: index_tsvector_search_documents_on_document; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_tsvector_search_documents_on_document ON tsvector_search_documents USING gin (document);


--
-- Name: search_lexemes_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX search_lexemes_idx ON search_lexemes USING gin (word gin_trgm_ops);


--
-- Name: standard_points_wkb_geometry_geom_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX standard_points_wkb_geometry_geom_idx ON standard_points USING gist (wkb_geometry);


--
-- Name: standard_polygons_wkb_geometry_geom_idx; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX standard_polygons_wkb_geometry_geom_idx ON standard_polygons USING gist (wkb_geometry);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user",public;

INSERT INTO schema_migrations (version) VALUES ('20140429140622');

INSERT INTO schema_migrations (version) VALUES ('20140527095736');

INSERT INTO schema_migrations (version) VALUES ('20140527125150');

INSERT INTO schema_migrations (version) VALUES ('20140527135808');

INSERT INTO schema_migrations (version) VALUES ('20140527150153');

INSERT INTO schema_migrations (version) VALUES ('20140527151457');

INSERT INTO schema_migrations (version) VALUES ('20140527152932');

INSERT INTO schema_migrations (version) VALUES ('20140528072204');

INSERT INTO schema_migrations (version) VALUES ('20140528072657');

INSERT INTO schema_migrations (version) VALUES ('20140528073943');

INSERT INTO schema_migrations (version) VALUES ('20140529072242');

INSERT INTO schema_migrations (version) VALUES ('20140601191435');

INSERT INTO schema_migrations (version) VALUES ('20140601193709');

INSERT INTO schema_migrations (version) VALUES ('20140601193923');

INSERT INTO schema_migrations (version) VALUES ('20140601195215');

INSERT INTO schema_migrations (version) VALUES ('20140601195405');

INSERT INTO schema_migrations (version) VALUES ('20140601195445');

INSERT INTO schema_migrations (version) VALUES ('20140601195642');

INSERT INTO schema_migrations (version) VALUES ('20140601195715');

INSERT INTO schema_migrations (version) VALUES ('20140601195757');

INSERT INTO schema_migrations (version) VALUES ('20140601195843');

INSERT INTO schema_migrations (version) VALUES ('20140601200419');

INSERT INTO schema_migrations (version) VALUES ('20140601203016');

INSERT INTO schema_migrations (version) VALUES ('20140601203550');

INSERT INTO schema_migrations (version) VALUES ('20140601204147');

INSERT INTO schema_migrations (version) VALUES ('20140601205045');

INSERT INTO schema_migrations (version) VALUES ('20140601205500');

INSERT INTO schema_migrations (version) VALUES ('20140601210111');

INSERT INTO schema_migrations (version) VALUES ('20140601210622');

INSERT INTO schema_migrations (version) VALUES ('20140601210739');

INSERT INTO schema_migrations (version) VALUES ('20140601210855');

INSERT INTO schema_migrations (version) VALUES ('20140601211052');

INSERT INTO schema_migrations (version) VALUES ('20140601211314');

INSERT INTO schema_migrations (version) VALUES ('20140602092716');

INSERT INTO schema_migrations (version) VALUES ('20140602103846');

INSERT INTO schema_migrations (version) VALUES ('20140602104104');

INSERT INTO schema_migrations (version) VALUES ('20140602104158');

INSERT INTO schema_migrations (version) VALUES ('20140602104243');

INSERT INTO schema_migrations (version) VALUES ('20140602104354');

INSERT INTO schema_migrations (version) VALUES ('20140602104439');

INSERT INTO schema_migrations (version) VALUES ('20140605105549');

INSERT INTO schema_migrations (version) VALUES ('20140612090110');

INSERT INTO schema_migrations (version) VALUES ('20140612092941');

INSERT INTO schema_migrations (version) VALUES ('20140612133146');

INSERT INTO schema_migrations (version) VALUES ('20140613125148');

INSERT INTO schema_migrations (version) VALUES ('20140616142743');

INSERT INTO schema_migrations (version) VALUES ('20140617090445');

INSERT INTO schema_migrations (version) VALUES ('20140617090531');

INSERT INTO schema_migrations (version) VALUES ('20140617091236');

INSERT INTO schema_migrations (version) VALUES ('20140617091255');

INSERT INTO schema_migrations (version) VALUES ('20140617091326');

INSERT INTO schema_migrations (version) VALUES ('20140617091620');

INSERT INTO schema_migrations (version) VALUES ('20140617093647');

INSERT INTO schema_migrations (version) VALUES ('20140617095318');

INSERT INTO schema_migrations (version) VALUES ('20140617113201');

INSERT INTO schema_migrations (version) VALUES ('20140617133557');

INSERT INTO schema_migrations (version) VALUES ('20140617133708');

INSERT INTO schema_migrations (version) VALUES ('20140617133943');

INSERT INTO schema_migrations (version) VALUES ('20140617161632');

INSERT INTO schema_migrations (version) VALUES ('20140617170024');

INSERT INTO schema_migrations (version) VALUES ('20140617170938');

INSERT INTO schema_migrations (version) VALUES ('20140625101751');

INSERT INTO schema_migrations (version) VALUES ('20140625154316');

INSERT INTO schema_migrations (version) VALUES ('20140703130946');

INSERT INTO schema_migrations (version) VALUES ('20140704105917');

INSERT INTO schema_migrations (version) VALUES ('20140704154012');

INSERT INTO schema_migrations (version) VALUES ('20140704154428');

INSERT INTO schema_migrations (version) VALUES ('20140707111454');

INSERT INTO schema_migrations (version) VALUES ('20140708193519');

INSERT INTO schema_migrations (version) VALUES ('20140709181758');

INSERT INTO schema_migrations (version) VALUES ('20140710124303');

INSERT INTO schema_migrations (version) VALUES ('20140710144417');

INSERT INTO schema_migrations (version) VALUES ('20140710144513');

INSERT INTO schema_migrations (version) VALUES ('20140714105648');

INSERT INTO schema_migrations (version) VALUES ('20140714110350');

INSERT INTO schema_migrations (version) VALUES ('20140714231111');

INSERT INTO schema_migrations (version) VALUES ('20140715151517');

INSERT INTO schema_migrations (version) VALUES ('20140715155911');

INSERT INTO schema_migrations (version) VALUES ('20140715160555');

INSERT INTO schema_migrations (version) VALUES ('20140715160624');

INSERT INTO schema_migrations (version) VALUES ('20140716103827');

INSERT INTO schema_migrations (version) VALUES ('20140716103848');

INSERT INTO schema_migrations (version) VALUES ('20140717133702');

INSERT INTO schema_migrations (version) VALUES ('20140718131656');

INSERT INTO schema_migrations (version) VALUES ('20140718134127');

INSERT INTO schema_migrations (version) VALUES ('20140721122630');

INSERT INTO schema_migrations (version) VALUES ('20140721122852');
