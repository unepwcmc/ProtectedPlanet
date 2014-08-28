# Marine Protected Areas geometry operations

## 1. Introduction

Marine Protected Areas can be located inside the Territorial Seas or the Economic Exclusive Zone. To calculate the percentage of these areas that is protected we need to intersect the flat Protected Areas dataset with the EEZ and TS geometries. Intersections are on of the most common operations when you do Spatial Analysis, but in this case there are some add ons to the usual intersection.

## 2. Base query

The basic PostGIS query for intersection could be use in this case, but due to the number and complexity of the geometries it was proven to take too long.

```SQL
  SELECT ST_Intersection(marine_pas_geom,  #{type_geom})
  FROM countries
  WHERE ST_Intersects(marine_pas_geom,  #{type_geom}) 
```

## 3. Increasing Speed

We have tried two different strategies (combined and alone) to improve the performance of the above query.

The first one, that has increased the speed but led to failures in several geometries was the ST_Within methodology explained [here](http://gis.stackexchange.com/questions/31310/acquiring-arcgis-like-speed-in-postgis). Due to these failures we did not use the methodology.

The second one was breaking the intersection by countries which, once more, proved to be very effective. 

Finally, the original TS and EEZ datasets had some not geometry collections with lines and polygons, so we had to do a buffer with 0.0 length to avoid any failure.


```SQL
UPDATE countries
  SET marine_#{type_geom}_pas_geom = (
    SELECT ST_Intersection(marine_pas_geom,ST_Buffer(#{marine_type}_geom,0.0))
    FROM countries
    WHERE iso_3 = '#{iso3}' AND ST_Intersects(marine_pas_geom,  ST_Buffer(<%= marine_geometry_attributes(marine_type) %>,0.0)) LIMIT 1
  ) WHERE iso_3 = '#{iso3}'
```

## 4. Inside a rails project

As in the [Dissolving Geometries](dissolving_geometries.md) query, the example in this documentation is plain SQL with ruby injections. In order to embed in a rails project we have created a [ERB template](../../lib/modules/geospatial/templates/marine_geometry.erb) with the full query that is run by a [class](../../lib/modules/geospatial/country_geometry_populator/marine_geometry_intersector.rb).