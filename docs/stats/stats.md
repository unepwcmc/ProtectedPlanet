#Complex Geospatial Statistics with Postgres/PostGIS

As you may know we are managing [ProtectedPlanet.net](http://www.protectedplanet.net), a website which shows all the protected areas in the world.

Now we are [rebuilding it](http://alpha.protectedplanet.net). At the end of the year we will have a completely new website running. You can view all the code for this new website in its [repository](https://github.com/unepwcmc/ProtectedPlanet) on [github](https://github.com).

Coverage Statistics is one of the main features. It is very important for the users to know what is the percentage of the territory that is covered by protected areas in a certain country These statistics were calculated manually in the old website and every year we have a team spending some days calculating them for an yearly report using ESRI Software.

So we had a great challenge this time:

Can we automatically calculate the statistics every month for all the protected areas and countries in the entire planet?

In this case time matters. If we want to calculate statistics every month it is not supposed to take 2 or 3 days processing as it was taking. We have chosen a full open source solution with Postgres/PostGIS to do all the back end tasks that we need to calculate statistics.

## What do we have?

We have two sets of protected areas: Points and Polygons. The vast majority (around 90%) is in polygon format with the boundaries of each protected area defined. We have more than 200.000 Protected Areas stored.

The protected areas represented by points have, in some cases, a 'reported area' column. We do not have the boundaries but we can create polygons according to that area. This value was sent by the public entities of the countries.

The protected areas can be marine or terrestrial and the base dataset has a column categorize them.

In the great majority of the cases the protected areas are completely within a country and there is also a column with the ISO3 of it. However there are some transboundary sites that belong to two or three countries.

We can have different protected areas in the same location. For instance, you can be in a Park that it is at the same time an UNESCO World Heritage Site, a National Park and a Natura 2000 area. Due to this particularity we have Protected Area's polygons overlapping each other.

## What do we need?

We need to calculate the following percentages for every country, every region (continent) and the entire planet:

* Territory Covered by Protected Areas
* Land Covered by Protected Areas Covered by Protected Areas
* Exclusive Economic Zones (EEZ) Covered by Protected Areas
* Territorial Seas Covered (TS) by Protected Areas

## What are we doing?

We follow a simple 3-step methodology explained in the following links:

1. [Dissolving Geometries](dissolving_geometries.md)
2. [Splitting Marine Protected Areas](marine_intersection.md)
3. [Calculating Stats](stats_calculator.md)

In the end we are taking around 6 hours to run automatically (2 hours for the first step and 4 hours for the second).