# Calculating statistics

## 1. Introduction

After creating a flat Protected Area dataset and splitting marine protected areas by Exclusive Economic Zones (EEZ) and Territorial Seas (TS) the last step is to calculate the statistics for countries, regions (continents) and global.
We have created two tables to store the statistics: _country_statistics_ and _regional_statistics_. We have included the global statistics in the last one as it did not make sense to create a table just with a row as all the statistics needed are the ones stored in regional_statisitics.
As all the statistics may change every month, we delete all the values before inserting the new ones on the fly.

## 2. Values that we need.

To calculate protected areas coverage statistics we need to get both the Protected Areas'areas and the administrative boundaries' areas. These are:

### Areas:

* Land Area (territory)
* EEZ Area (territory)
* TS Area (territory)
* Protected Areas Land Area
* Protected Areas Marine Area
* Protected Areas EEZ Area
* Protected Areas TS Area

### Statistics:

* Percentage of total territory's area covered by Protected Areas
* Percentage of territory's land area covered by Protected Areas
* Percentage of territory's EEZ area covered by Protected Areas
* Percentage of territory's TS area covered by Protected Areas
* Percentage of territory's EEZ area covered by Protected Areas

We have one column in country_statistics per value calculated.

## 3. Countries' Statistics

### Calculating the areas

As we have stored the geometries in the countries table we will need only to get the areas from there and then calculate the statistics on the fly.
The base query is:

SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area,
  ST_Area((marine_pas_geom,954009) pa_marine_area,
  ST_Area(marine_eez_pas_geom,954009) pa_eez_area,
  ST_Area(marine_ts_pas_geom,954009) pa_ts_area,
  ST_Area(land_geom,954009) land_area,
  ST_Area(eez_geom,954009) eez_area,
  ST_Area(ts_geom,954009) ts_Area
FROM countries

### Reprojecting

As you may have detected, as we are using WGS 84 the query above gives us areas in square degrees, not a very common unit. To calculate the area in square meters we need to reproject the base layer to an equal area projection. In this case from WGS 84 to Mollweide.

```SQL
SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area,
  ST_Area(ST_Transform(marine_pas_geom,954009)) pa_marine_area,
  ST_Area(ST_Transform(marine_eez_pas_geom,954009)) pa_eez_area,
  ST_Area(ST_Transform(marine_ts_pas_geom,954009)) pa_ts_area,
  ST_Area(ST_Transform(land_geom,954009)) land_area,
  ST_Area(ST_Transform(eez_geom,954009)) eez_area,
  ST_Area(ST_Transform(ts_geom,954009)) ts_Area
FROM countries
```

### Calculating

We need to get all the values in the query above plus the coverage percentages to insert on the statistics table. We nned to creat a new query with the caltulations using the query above as a subquery.

```SQL
SELECT land_area,
       eez_area,
       ts_area,
       pa_land_area + pa_marine_area,
       pa_land_area,
       pa_marine_area,
       pa_eez_area,
       pa_ts_area,
       (pa_land_area + pa_marine_area) / (land_area + eez_area + ts_area)*100,
       pa_land_area / land_area * 100,
       pa_eez_area / eez_area * 100,
       pa_ts_area,0) / ts_area * 100,
  FROM (
        SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area,
          ST_Area(ST_Transform(marine_pas_geom,954009)) pa_marine_area,
          ST_Area(ST_Transform(marine_eez_pas_geom,954009)) pa_eez_area,
          ST_Area(ST_Transform(marine_ts_pas_geom,954009)) pa_ts_area,
          ST_Area(ST_Transform(land_geom,954009)) land_area,
          ST_Area(ST_Transform(eez_geom,954009)) eez_area,
          ST_Area(ST_Transform(ts_geom,954009)) ts_Area
        FROM countries
        ) areas
```

### Handling null values

We have countries without seafront and we have countries without protected areas. These values are set as null when calculating with Postgis. Postgres does not consider null values as zero so we need to change them in order to calculate the values. As the eez_area and ts_area area can be null, we must avoid a division by zero when calculating their Protected Area coverage.

```SQL
SELECT land_area, eez_area, ts_area,
  COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0),
  pa_land_area, pa_marine_area, pa_eez_area, pa_ts_area,
  (COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0)) /
    (land_area + COALESCE(eez_area, 0) + COALESCE(ts_area,0))*100,
  COALESCE(pa_land_area,0) / land_area * 100,
  CASE
    WHEN eez_area = 0 THEN
    0
    ELSE
    COALESCE(pa_eez_area,0) / eez_area * 100
  END,
  CASE
    WHEN ts_area = 0 THEN
    0
    ELSE
    COALESCE(pa_ts_area,0) / ts_area * 100
  END
FROM (
  SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area,
          ST_Area(ST_Transform(marine_pas_geom,954009)) pa_marine_area,
          ST_Area(ST_Transform(marine_eez_pas_geom,954009)) pa_eez_area,
          ST_Area(ST_Transform(marine_ts_pas_geom,954009)) pa_ts_area,
          ST_Area(ST_Transform(land_geom,954009)) land_area,
          ST_Area(ST_Transform(eez_geom,954009)) eez_area,
          ST_Area(ST_Transform(ts_geom,954009)) ts_Area
        FROM countries
) areas
```

### Updating the statistics table

As mentioned above, we delete all the values from the country_statistics table before inserting the new ones. This is the fastest way to update. We add timestamps to know when was the last change.

```SQL
INSERT INTO country_statistics (
  country_id, land_area, eez_area, ts_area, pa_area,
  pa_land_area, pa_marine_area, pa_eez_area, pa_ts_area, percentage_pa_cover,
  percentage_pa_land_cover, percentage_pa_eez_cover,
  percentage_pa_ts_cover, created_at, updated_at
)
SELECT id, land_area, eez_area, ts_area,
  COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0),
  pa_land_area, pa_marine_area, pa_eez_area, pa_ts_area,
  (COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0)) /
    (land_area + COALESCE(eez_area, 0) + COALESCE(ts_area,0))*100,
  COALESCE(pa_land_area,0) / land_area * 100,
  CASE
    WHEN eez_area = 0 THEN
    0
    ELSE
    COALESCE(pa_eez_area,0) / eez_area * 100
  END,
  CASE
    WHEN ts_area = 0 THEN
    0
    ELSE
    COALESCE(pa_ts_area,0) / ts_area * 100
  END,
  LOCALTIMESTAMP,
  LOCALTIMESTAMP
  FROM (
    SELECT id, ST_Area(ST_Transform(land_pas_geom,954009)) pa_land_area,
            ST_Area(ST_Transform(marine_pas_geom,954009)) pa_marine_area,
            ST_Area(ST_Transform(marine_eez_pas_geom,954009)) pa_eez_area,
            ST_Area(ST_Transform(marine_ts_pas_geom,954009)) pa_ts_area,
            ST_Area(ST_Transform(land_geom,954009)) land_area,
            ST_Area(ST_Transform(eez_geom,954009)) eez_area,
            ST_Area(ST_Transform(ts_geom,954009)) ts_Area
          FROM countries
  ) areas
```

## 4. Regions Statistics

### Calculating areas

In this case we do not need to do any geospatial operation, only to sum all the areas for each country in a continent. We consider Russia and Turkey as Asian territories as the majority of their territory is in Asia. The regions table as a one to many relationship with the countries table.

The base query is:

```SQL
SELECT r.id,
  sum(pa_land_area) pa_land_area,
  sum(pa_marine_area) pa_marine_area,
  sum(pa_eez_area) pa_eez_area,
  sum(pa_ts_area) pa_ts_area,
  sum(land_area) land_area,
  sum(eez_area) eez_area,
  sum(ts_area) ts_area
  FROM country_statistics cs
JOIN countries c ON cs.country_id = c.id
JOIN regions r on r.id = c.region_id
GROUP BY r.id
```

### Updating the statistics table

The regional statistics calculation has the same structure as what we have done for countries. The query is very similar.

```SQL
INSERT INTO regional_statistics (
  region_id, land_area, eez_area, ts_area, pa_area,
  pa_land_area, pa_marine_area, pa_eez_area, pa_ts_area, percentage_pa_cover,
  percentage_pa_land_cover, percentage_pa_eez_cover,
  percentage_pa_ts_cover, created_at, updated_at
)
SELECT id, land_area, eez_area, ts_area,
  COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0),
  pa_land_area, pa_marine_area, pa_eez_area, pa_ts_area,
  (COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0)) /
    (land_area + COALESCE(eez_area, 0) + COALESCE(ts_area,0))*100,
  COALESCE(pa_land_area,0) / land_area * 100,
  CASE
    WHEN eez_area = 0 THEN
    0
    ELSE
    COALESCE(pa_eez_area,0) / eez_area * 100
  END,
  CASE
    WHEN ts_area = 0 THEN
    0
    ELSE
    COALESCE(pa_ts_area,0) / ts_area * 100
  END,
  LOCALTIMESTAMP,
  LOCALTIMESTAMP
  FROM (
    SELECT r.id,
    sum(pa_land_area) pa_land_area,
    sum(pa_marine_area) pa_marine_area,
    sum(pa_eez_area) pa_eez_area,
    sum(pa_ts_area) pa_ts_area,
    sum(land_area) land_area,
    sum(eez_area) eez_area,
    sum(ts_area) ts_area
    FROM country_statistics cs
  JOIN countries c ON cs.country_id = c.id
  JOIN regions r on r.id = c.region_id
  GROUP BY r.id) areas
```

## 5. Global Statistics

The statistics calculation for global statistics is very similar to what we have done with regional statistics. The only difference is that we restrict the operation to the global region (with its geometries).

```SQL
INSERT INTO regional_statistics (
  region_id, land_area, eez_area, ts_area, pa_area,
  pa_land_area, pa_marine_area, pa_eez_area, pa_ts_area, percentage_pa_cover,
  percentage_pa_land_cover, percentage_pa_eez_cover,
  percentage_pa_ts_cover, created_at, updated_at
)
SELECT id, land_area, eez_area, ts_area,
  COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0),
  pa_land_area, pa_marine_area, pa_eez_area, pa_ts_area,
  (COALESCE(pa_land_area,0) + COALESCE(pa_marine_area,0)) /
    (land_area + COALESCE(eez_area, 0) + COALESCE(ts_area,0))*100,
  COALESCE(pa_land_area,0) / land_area * 100,
  CASE
    WHEN eez_area = 0 THEN
    0
    ELSE
    COALESCE(pa_eez_area,0) / eez_area * 100
  END,
  CASE
    WHEN ts_area = 0 THEN
    0
    ELSE
    COALESCE(pa_ts_area,0) / ts_area * 100
  END,
  LOCALTIMESTAMP,
  LOCALTIMESTAMP
  FROM (
    SELECT r.id,
      sum(pa_land_area) pa_land_area,
      sum(pa_marine_area) pa_marine_area,
      sum(pa_eez_area) pa_eez_area,
      sum(pa_ts_area) pa_ts_area,
      sum(land_area) land_area,
      sum(eez_area) eez_area,
      sum(ts_area) ts_area
      FROM country_statistics cs
    JOIN countries c ON cs.country_id = c.id,
    regions r
    WHERE r.iso = 'GL'
    GROUP BY r.id) areas
```

## 6. Inside a rails project

As in the [Dissolving Geometries](dissolving_geometries.md) and the [Marine Intersection](dissolving_geometries.md), the example in this documentation is plain SQL . In order to embed in a rails project we have created ERB Templates for  [countries](../../lib/modules/geospatial/templates/countries_statistics_query.erb), [regions](../../lib/modules/geospatial/templates/regional_statistics_query.erb), [planet](../../lib/modules/geospatial/templates/global_statistics_query.erb) and the [common parts](../../lib/modules/geospatial/templates/base_calculation.erb). In the end we get a DRY solution that should be run by a [class](../../lib/modules/geospatial/calculator.rb).