#Complex Geospatial Statistics with Postgres/PostGIS

As you may know we are managing [ProtectedPlanet.net](http://www.protectedplanet.net), a website which shows all the protected areas in the world.

Now we are [rebuilding it](http://alpha.protectedplanet.net). At the end of the year we will have a completely new website running. You can view all the code for this new website in its [repository](https://github.com/unepwcmc/ProtectedPlanet) on [github](https://github.com).

Coverage Statistics is one of the main features. It is very important for the users to know what is the percentage of the territory that is covered by protected areas in a certain country These statistics were calculated manually in the old website and every year we have a team spending some days calculating them for an yearly report using ESRI Software.

So we had a great challenge this time:

Can we automatically calculate the statistics every month for all the protected areas and countries in the entire planet?

In this case time matters. If we want to calculate statistics every month it is not supposed to take 2 or 3 days processing as it was taking using mainly ESRI software. We have chosen a full open source solution with Postgres/PostGIS to do all the back end tasks that we need to calculate statistics.

##What do we have?

We have two sets of protected areas: Points and Polygons. The vast majority (around 90%) is in polygon format with the boundaries of each protected area defined. We have more than 200.000 Protected Areas stored.

The protected areas represented by points have, in some cases, a 'reported area' column. We do not have the boundaries but we can create polygons buffering according to that area. This value was sent by the public entities of the countries.

The protected areas can be marine or terrestrial and the base dataset has a column categorize them.

In the great majority of the cases the protected areas are completely within a country and there is also a column with the ISO3 of it. However there are some transboundary sites that belong to two or three countries.

We can have different protected areas in the same location. For instance, you can be in a Park that it is at the same time an UNESCO World Heritage Site, a National Park and a Natura 2000 area. Due to this particularity we have Protected Area's polygons overlapping each other.

##What do we need?

We need to calculate the following percentages for every country, every region (continent) and the entire planet:

+ Territory Covered by Protected Areas
+ Land Covered by Protected Areas Covered by Protected Areas
+ Exclusive Economic Zones (EEZ) Covered by Protected Areas
+ Territorial Seas Covered (TS) by Protected Areas

## What are we doing?

###Creating a flat dataset

To have the correct values for coverage we need to dissolve overlapping polygons in just one. As you imagine, doing that for around 200.000 polygons around the world (some of them very complex) should take a while (it was taking more than 3 days when we stopped it), so we had to design a quicker way of doing that.

####Base Query

```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  GROUP BY iso3
```

1. Split by countries
Instead of creating a single query to dissolve everything, as we need the statistics for countries, we do one dissolve query per country


####Query Evolution 1

```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  WHERE iso3 = #{iso3}
  GROUP BY iso3
```

2. Split by type
Each country can have two types of protected areas: Marine and Terrestrial. In order to calculate coverage statistics for land, EEZ and TS we also need to split the protected areas by type. This type field in fact is called 'is_marine' and works as a boolean (true if it is marine, false if it is land) We will have one dissolve query per type for each country.

####Query Evolution 2

```SQL
SELECT iso3, ST_Union(the_geom)
  FROM standard_polygons
  WHERE iso3 = #{iso3} AND is_marine = #{type}
  GROUP BY iso3
```

3. Buffer Protected Areas Represented as points
As we referred above we have about 10% of the Data represented by points. In order to have the most accurate representation we buffer the points according to the given area. If the areas were not supplied we simply ignore those points. All the new polygons created by this method are dissolved at the same time as the other polygons and according to their country and type.

####Query Evolution 3

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
```

4. Simplifying polygons
The only way of doing this process in an reasonable time is simplifying the geometries so we have less nodes in each polygon. As we are calculating statistics for each country we have a wide range of areas and protected areas, from the Holy See to Russia. So, a simplification of 100 yards in Russia should not have any effect on the final result, that same simplification would affect the results of dozens of small countries.
So, we took an iterative method to get the most accurate statistics in the fastest way. Many countries have a set of protected areas that can be dissolved in a couple of seconds due to their size, number and/or geometry's complexity. These countries do not need any simplification.
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


5. Dealing with trans-national Protected Areas
Trans-national Protected Areas are the only one to have a comma in their ISO3 column. After detecting a Protected Area like this, we intersect it with the geometries of the related countries to split it before dissolving with the other Protected Areas of each country.

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


5. Excluding unwanted protected areas
Some of the Protected Areas should not be used to calculate statistics. In this group we have the ones whose status is _Proposed_ or _Not_ _Reported_ or _UNESCO_ _Biosphere_ _Reserves_.

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

6. Making Geometries Valid
In some cases we create not valid geometries when simplifying or creating a buffer. We need in each case to make features topologically valid.


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








