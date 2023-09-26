DROP TABLE IF EXISTS wdpa_geoms;
DROP TABLE IF EXISTS geometry_validation;
DROP PROCEDURE IF EXISTS geometry_validation_proc;

CREATE TABLE wdpa_geoms(
	draft_id	bigint,
	request_id	int,
	iso3		varchar(40),
	shape		geometry
);

CREATE INDEX wdpa_geoms_index on wdpa_geoms gist(shape);

CREATE TABLE geometry_validation(
	draft_id			bigint,
	request_id			int,
	iso3				varchar(40),
	base_layer_iso3		varchar(40),
	misassigned_ratio 	double precision,
	misassigned_geom	geometry
);


CREATE OR REPLACE FUNCTION geometry_validation_proc(misassigned_ratio_threshold double precision)
RETURNS INTEGER
LANGUAGE SQL
AS $$ DECLARE rc integer; BEGIN
INSERT INTO geometry_validation
with overlapping_geoms as (
		-- gather the overlapping geometries by ISO3
		select draft_id, request_id, wdpa_iso3, base_layer_iso3, ST_union(geom) as misassigned_geom, shape from (
			-- intersect input geometry with the base layer
		    select wdpa_geoms.draft_id as draft_id, wdpa_geoms.request_id as request_id, wdpa_geoms.iso3 as wdpa_iso3, base_geoms.iso3 as base_layer_iso3,
		   		ST_Intersection(wdpa_geoms.shape, base_geoms.shape) as geom, wdpa_geoms.shape as shape from wdpa_geoms
		      join
		      -- join the base layer
		      (SELECT iso3, shape FROM base_layer bl) as base_geoms
		      on wdpa_geoms.shape && base_geoms.shape
		  ) as intersected_geoms
		  where
		  -- check if wdpa iso3 equals country iso3
		  (intersected_geoms.base_layer_iso3 not in (select unnest(string_to_array(intersected_geoms.wdpa_iso3, ';')))
		  -- and explicitly check for disputed areas
		  or intersected_geoms.base_layer_iso3 like '%/%')
		  and not st_isempty(intersected_geoms.geom)
		  group by intersected_geoms.draft_id, intersected_geoms.request_id, intersected_geoms.wdpa_iso3, intersected_geoms.base_layer_iso3, intersected_geoms.shape
	)
	select draft_id, request_id, wdpa_iso3, base_layer_iso3, misassigned_ratio, misassigned_geom from (
		-- calculate the percentage of a PA that is misassigned for polygon geometries
		select draft_id, request_id, wdpa_iso3, base_layer_iso3,
			ST_Area(ST_Transform(overlapping_geoms.misassigned_geom, 54009)) / ST_Area(ST_Transform(shape, 54009)) as misassigned_ratio,
			misassigned_geom from overlapping_geoms
		where st_geometrytype(shape) = 'ST_MultiPolygon'
	) as geoms_with_percentage
	-- apply the threshold
	where misassigned_ratio > misassigned_ratio_threshold
	union
    -- all point geometries in a foreign territory are misassigned
	(select draft_id, request_id, wdpa_iso3, base_layer_iso3, 1, misassigned_geom from overlapping_geoms where st_geometrytype(shape) = 'ST_MultiPoint'); GET DIAGNOSTICS rc = row_count; RETURN rc;
$$;

