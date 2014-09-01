# Creating a flat dataset

As we have written [before](../stats.md#what-do-we-have), a location can
be inside two or more protected areas, and so there are many overlapping
polygons -- to calculate the correct values for coverage we need to
dissolve these.  This is an expensive operation considering the 200,000+
polygons around the world (some of them very complex) -- this operation
took more than 3 days before we stopped it. We had to design a better
process.

This is the base query that was too expensive to run:

```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  GROUP BY iso3
```

## 1. Split by Countries

Instead of creating a single query to dissolve everything, as we need
the statistics per country, we do one dissolve query per country,
using Ruby to loop through all the countries.

```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  WHERE iso3 = #{iso3}
  GROUP BY iso3
```

## 2. Split by Type

Each country can have two different types of protected areas: Marine and
Terrestrial. In order to calculate coverage statistics for land,
Exclusive Economic Zone (EEZ) and Territorial Seas (TS) we also need to
split the protected areas by type, determined by the `is_marine` boolean
attribute.

```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  WHERE iso3 = #{iso3} AND is_marine = #{type}
  GROUP BY iso3
```

## 3. Buffer Protected Areas Represented as Points

About [10% of the Data](../stats.md#what-do-we-have) is made up of
points. In order to have the most accurate representation, we buffer the
points according to the given area. If the areas were not supplied we
simply ignore those points. All the new polygons created by this method
are dissolved at the same time as the other polygons and according to
their country and type.

```SQL
SELECT ST_UNION(the_geom) as the_geom
  FROM (
    SELECT iso3, the_geom the_geom
      FROM standard_polygons
      WHERE iso3 = #{iso3}
        AND is_marine = #{type}
      GROUP BY iso3

    UNION

    SELECT iso3, ST_Buffer(the_geom::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
     FROM standard_points
     WHERE iso3 = #{iso3}
       AND is_marine = #{type}
  ) a
```

## 4. Simplifying Polygons

The only way of doing this process in an reasonable time is by
simplifying the geometries so there are fewer nodes per polygon.

This can cause problems: as statistics are being calculated per country,
we have a wide range of territories and protected areas, from the Holy
See to Russia. So, a simplification of 100 yards in Russia should not
have any effect on the final result, while the same simplification level
would affect the results of dozens of small countries. As such, we use
an iterative method to get the most accurate statistics in the fastest
way.

Many countries have a set of protected areas that can be dissolved in a
couple of seconds due to their size, number and/or geometric
complexity and thus do not need any simplification.

On other hand, countries with many complicated protected areas, such as
Germany or USA, can take many hours to simplify them. Through trial and
error, we determined a list of countries with protected areas complex
enough to be worth simplifying.

But, how much should we simplify? As we have all the data in a
Geographical Coordinate System (WGS 84), it does not make sense to
transform it in a projected coordinate system, as we need to speed up
the process. Through experimentation comparing speed and results. we
found that simplifying by 0.005 degrees would allow having accurate
results in a reasonable amount of time.

At this point we are simplifying the land protected areas of 18
countries and the marine protected areas of 6 countries.

```Ruby
  COMPLEX_COUNTRIES = {
    'marine' => ['GBR','USA','CAN','MYT','CIV','AUS'],
    'land'   => ['DEU','USA','FRA','GBR','AUS','FIN','BGR','CAN',
                 'ESP','SWE','BEL','EST','IRL','ITA','LTU',
                 'NZL','POL','CHE']
  }

  def geometry_attribute country, area_type
    if COMPLEX_COUNTRIES[area_type].include? country.iso_3
      'ST_Makevalid(ST_Buffer(ST_Simplify(the_geom,0.005),0.0))'
    else
      'the_geom'
    end
  end
```

```SQL
SELECT ST_UNION(the_geom) as the_geom
  FROM (
  SELECT iso3, ST_Union(#{geometry_attribute(country, area_type)}) the_geom
    FROM standard_polygons
    WHERE iso3 = #{iso3}
      AND is_marine = #{type}

  UNION

  SELECT iso3, ST_Buffer(the_geom::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
   FROM standard_points
   WHERE iso3 = #{iso3}
      AND is_marine = #{type}
  ) a
```

## 5. Dealing with Transnational Protected Areas

Transnational protected areas are a minority of protected areas that
span multiple countries, thus having more than one defined ISO3 code.
In this case, the protected area is intersected with the geometries of
the related countries to split it before dissolving with the other
protected areas of each country.

```SQL
SELECT ST_UNION(the_geom) as the_geom
  FROM (
  SELECT iso3, #{geometry_attribute(country, area_type)} the_geom
    FROM standard_polygons
    WHERE iso3 = #{iso3}
      AND is_marine = #{type}

  UNION

  SELECT iso3, ST_Buffer(the_geom::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
   FROM standard_points
   WHERE iso3 = #{iso3}
    AND is_marine = #{type}

  UNION

  SELECT country.iso_3, ST_Intersection(country.land_geom, polygon.the_geom) the_geom
    FROM standard_polygons polygon
    INNER JOIN countries country ON ST_Intersects(country.land_geom, polygon.the_geom)
    WHERE polygon.iso3 LIKE '%,%'
      AND iso3 = #{iso3}
      AND is_marine = #{type}
  ) a
```

## 6. Excluding Unwanted Protected Areas

Some of the protected areas should not be used to calculate statistics.
This includes protected areas with the following statuses: _Proposed_,
_Not_ _Reported_ and _UNESCO_ _Biosphere_ _Reserves_.

```SQL
SELECT ST_UNION(the_geom) as the_geom
  FROM (
  SELECT iso3, #{geometry_attribute(country, area_type)} the_geom
    FROM standard_polygons
    WHERE iso3 = #{iso3}
      AND is_marine = #{type}
      AND status NOT IN ('Proposed', 'Not Reported')
      AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
  UNION

  SELECT iso3, ST_Buffer(the_geom::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
   FROM standard_points
   WHERE iso3 = #{iso3}
    AND is_marine = #{type}
    AND status NOT IN ('Proposed', 'Not Reported')
    AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')

  UNION

  SELECT country.iso_3, ST_Intersection(country.land_geom, polygon.the_geom) the_geom
    FROM standard_polygons polygon
    INNER JOIN countries country ON ST_Intersects(country.land_geom, polygon.the_geom)
    WHERE polygon.iso3 LIKE '%,%'
      AND iso3 = #{iso3}
      AND is_marine = #{type}
      AND status NOT IN ('Proposed', 'Not Reported')
      AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
  ) a
```

## 7. Making Geometries Valid

In some cases we create invalid geometries when simplifying polygons, or
buffering points. As such, we have to individually make features
topologically valid.

```SQL
SELECT ST_UNION(the_geom) as the_geom
  FROM (
  SELECT iso3, #{geometry_attribute(country, area_type)} the_geom
    FROM standard_polygons
    WHERE iso3 = #{iso3}
      AND ST_IsValid(polygon.wkb_geometry)
      AND is_marine = #{type}
      AND status NOT IN ('Proposed', 'Not Reported')
      AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
  UNION

  SELECT iso3, ST_Buffer(the_geom::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
   FROM standard_points
   WHERE iso3 = #{iso3}
    AND is_marine = #{type}
    AND status NOT IN ('Proposed', 'Not Reported')
    AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')


  UNION

  SELECT country.iso_3, ST_Makevalid(ST_Intersection(ST_Buffer(country.land_geom,0.0), polygon.the_geom)) the_geom
    FROM standard_polygons polygon
    INNER JOIN countries country ON ST_Intersects(ST_Buffer(country.land_geom,0.0), polygon.the_geom)
    WHERE polygon.iso3 LIKE '%,%'
      AND iso3 = #{iso3}
      AND is_marine = #{type}
      AND status NOT IN ('Proposed', 'Not Reported')
      AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
  ) a
```

## 8. Updating Table

All new geometries are stored in the countries table.

```SQL
UPDATE countries
SET #{type}_pas_geom = a.the_geom
  FROM(
  SELECT ST_UNION(the_geom) as the_geom
    FROM (
    SELECT iso3, #{geometry_attribute(country, area_type)} the_geom
      FROM standard_polygons
      WHERE iso3 = #{iso3}
        AND ST_IsValid(polygon.wkb_geometry)
        AND is_marine = #{type}
        AND status NOT IN ('Proposed', 'Not Reported')
        AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
    UNION

    SELECT iso3, ST_Buffer(the_geom::geography, |/( rep_area*1000000 / pi() ))::geometry the_geom
     FROM standard_points
     WHERE iso3 = #{iso3}
      AND is_marine = #{type}
      AND status NOT IN ('Proposed', 'Not Reported')
      AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')


    UNION

    SELECT country.iso_3, ST_Makevalid(ST_Intersection(ST_Buffer(country.land_geom,0.0), polygon.the_geom)) the_geom
      FROM standard_polygons polygon
      INNER JOIN countries country ON ST_Intersects(ST_Buffer(country.land_geom,0.0), polygon.the_geom)
      WHERE polygon.iso3 LIKE '%,%'
        AND iso3 = #{iso3}
        AND is_marine = #{type}
        AND status NOT IN ('Proposed', 'Not Reported')
        AND desig NOT IN ('UNESCO-MAB Biosphere Reserve', 'UNESCO-MAB Réserve de Biosphère')
    ) b
) a
```

## 9. In the Application

Most of the above queries are static and do not change. However, some
require that data such as ISO codes be interpolated. This is handled by
a
[`GeometryDissolver`](../../lib/modules/geospatial/country_geometry_populator/geometry_dissolver.rb)
class that generates SQL from an [ERB
template](../../lib/modules/geospatial/templates/dissolve_geometries.erb).

[Home](../stats.md) | [Next Step](marine_intersection.md)
