# Creating a flat dataset

As we have written [before](stats.md#what-do-we-have), a place can be inside two or more protected areas. Due to tat we have in several places overlapping polygons. To have the correct values for coverage we need to dissolve overlapping polygons in just one. As you imagine, doing that for around 200.000 polygons around the world (some of them very complex) should take a while (it was taking more than 3 days when we stopped it), so we had to design a quicker way of doing that.

This is the base query that was taking days to run:

```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  GROUP BY iso3
```

## 1. Split by countries

Instead of creating a single query to dissolve everything, as we need the statistics for countries, we do one dissolve query per country, using Ruby to loop through all the countries.


```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  WHERE iso3 = #{iso3}
  GROUP BY iso3
```

## 2. Split by type

Each country can have two different types of protected areas: Marine and Terrestrial. In order to calculate coverage statistics for land, Exclusive Economic Zone (EEZ) and Territorial Seas (TS) we also need to split the protected areas by type. This type field in fact is called 'is_marine' and works as a boolean (true if it is marine, false if it is land) We will have one dissolve query per type for each country.


```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  WHERE iso3 = #{iso3} AND is_marine = #{type}
  GROUP BY iso3
```

## 3. Buffer Protected Areas Represented as points

We have about [10% of the Data](stats.md#what-do-we-have) represented by points. In order to have the most accurate representation we buffer the points according to the given area. If the areas were not supplied we simply ignore those points. All the new polygons created by this method are dissolved at the same time as the other polygons and according to their country and type.


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

## 4. Simplifying polygons

The only way of doing this process in an reasonable time is simplifying the geometries so we have less nodes in each polygon. As we are calculating statistics for each country we have a wide range of territories and protected areas, from the Holy See to Russia. So, a simplification of 100 yards in Russia should not have any effect on the final result, while hat same simplification would affect the results of dozens of small countries.

We took an iterative method to get the most accurate statistics in the fastest way.

Many countries have a set of protected areas that can be dissolved in a couple of seconds due to their size, number and/or geometry's complexity. These countries do not need any simplification.

On other hand we spent several hours to dissolve all the protected areas in countries like Germany, USA or Australia. We have then created two groups of countries (marine and terrestrial) whose geometries should be simplified. We then use two different queries, one with simplified geometries and the other one using the raw data.

But, how much should we simplify? In first place, as we have all the data in a Geographical Coordinate System (WGS 84) does not make sense to transform it in a projected coordinate system, as we need to speed up the process. We took here also an iterative approach comparing speed and results. In the end we found that simplifying by 0.005 degrees would allow having accurate results in reasonable time.

At this point we are simplifying the land protected areas of 18 countries and the marine protected areas of 6 countries.

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


## 5. Dealing with transnational Protected Areas

Transnational Protected Areas are the only ones to have a comma in their ISO3 column (we are using the raw tables sent to us and not our tables in order to save time). After detecting a Protected Area like this, we intersect it with the geometries of the related countries to split it before dissolving with the other Protected Areas of each country.

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


## 6. Excluding unwanted protected areas

Some of the Protected Areas should not be used to calculate statistics. In this group we have the ones whose status is _Proposed_ or _Not_ _Reported_ or _UNESCO_ _Biosphere_ _Reserves_.

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

In some cases we create not valid geometries when simplifying or creating a buffer. We need in each case to make features topologically valid.

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

## 8. Updating table

All the geometries should be stored in the countries table. According to what we mentionend above we will have three update queries per country everytime we have new geometries.

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

## 9. Inside a rails project

The above query is (almost) in plain SQL. The only the countries, types of protected areas and simplifying code are ruby injections. In order to embed in a rails project we have created a [ERB template](../../lib/modules/geospatial/templates/dissolve_geometries.erb) with the full query that is run by a [class](../../lib/modules/geospatial/country_geometry_populator/geometry_dissolver.rb).

[Home](stats.md) | [Next Step](marine_intersection.md)