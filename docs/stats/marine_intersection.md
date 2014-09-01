# Marine Protected Areas Geometry Operations

## 1. Introduction

Marine Protected Areas can be located inside the Territorial Seas or the
Economic Exclusive Zone of a country. To calculate the percentage of
these areas that is protected we need to intersect the flat Protected
Areas dataset with the EEZ and TS geometries. Intersections are one of
the most common operations in Spatial Analysis, but in this case there
are some extras that have to occur.

## 2. Base Query

The basic PostGIS query for intersection could be used in this case, but
due to the number and complexity of the geometries it was proven to take
too long.

```SQL
  SELECT ST_Intersection(marine_pas_geom,  #{type_geom})
  FROM countries
  WHERE ST_Intersects(marine_pas_geom,  #{type_geom})
```

## 3. Increasing Speed

We tried two different strategies to improve the performance of the
query.

### ST_Within

The first, that increased the speed but led to failures in several
geometries was the utilising `ST_Within` methodology explained
[here](http://gis.stackexchange.com/questions/31310/acquiring-arcgis-like-speed-in-postgis).
Due to the nature of these calculations, the number of failures here was
unacceptable.

### Country Intersection

The second was breaking the intersection by countries which, once
more, proved to be very effective.

Finally, the original TS and EEZ datasets had some geometry collections
with lines and polygons, so we buffered with length of 0.0 to avoid any
failures.

```SQL
UPDATE countries
  SET marine_#{type_geom}_pas_geom = (
    SELECT ST_Intersection(marine_pas_geom,ST_Buffer(#{marine_type}_geom,0.0))
    FROM countries
    WHERE iso_3 = '#{iso3}' AND ST_Intersects(marine_pas_geom,  ST_Buffer(#{marine_geometry_attributes(marine_type)},0.0)) LIMIT 1
  ) WHERE iso_3 = '#{iso3}'
```

## 4. Inside the Application

As in the [Dissolving Geometries](dissolving_geometries.md) query, the
example in this documentation is plain SQL with Ruby interpolation. In
order to embed in a rails project we have created a [ERB
template](../../lib/modules/geospatial/templates/marine_geometry.erb)
with the full query that is run by a
[class](../../lib/modules/geospatial/country_geometry_populator/marine_geometries_intersector.rb).

[Previous Step](dissolving_geometries.md) | [Home](../stats.md) | [Next Step](stats_calculator.md)
