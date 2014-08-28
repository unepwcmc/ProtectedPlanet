# Calculating statistics

## Values that we need.

To calculate protected areas coverage statistics we need to get both the Protected Areas'areas and the administrative boundaries' areas. These are:

* Land Area (Country)
* EEZ Area (Country)
* TS Area (Country)
* Protected Areas Land Area
* Protected Areas Marine Area
* Protected Areas EEZ Area
* Protected Areas TS Area

## 

As we have stored the geometries in the countries table we will need only to get the areas from there.

UPDATE <%= @table_name %>
SET <%= @column_name %> = ST_Makevalid(ST_Multi(ST_Buffer(<%= @column_name %>,0.0)))
WHERE NOT ST_IsValid(<%= @column_name %>)


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
  <%= from_query %>
) areas