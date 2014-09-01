# Complex Geospatial Statistics with Postgres/PostGIS

Displaying protected area coverage statistics is one of the main
features of Protected Planet. It is very important for the users to know
what percentage of the territory is covered by protected areas in a
given country, region or the entire planet.

Previously, these statistics were calculated manually and every year a
team spent multiple days calculating them for a yearly report using ESRI
Software.

We had a great challenge this time:

> Can we automatically calculate the statistics every month for all the
> protected areas and countries in the entire planet?

In this case time matters: if we want to calculate statistics every
month, it can't take 2 or 3 days of processing. To work through this, we
chose a full open source solution with Postgres/PostGIS to do all
the back end tasks that we need to calculate statistics.

## What do we have?

We have two sets of protected areas: Points and Polygons. The vast
majority (around 90%) is in polygon format with the boundaries of each
protected area defined. We have more than 200,000 protected areas
stored.

The protected areas represented by points have, in some cases, a
'reported area' column. We do not have the boundaries but we can create
polygons according to this area data supplied by the public entities of
the countries.

The protected areas can be marine or terrestrial, and the base dataset
defines this with a boolean `is_marine` flag.

In the great majority of the cases the protected areas are completely
within a country and there is also a column with the ISO3 of it. However
there are some transboundary sites that belong to two or three
countries.

We can have different protected areas in the same location. For
instance, you can be in a Park that it is at the same time an UNESCO
World Heritage Site, a National Park and a Natura 2000 area. This means
that we have many protected area's with overlapping polygons.

## What do we need?

We need to calculate the following percentages for every country, every
region (continent) and the entire planet:

* Territory Covered by Protected Areas
* Land Covered by Protected Areas
* Exclusive Economic Zones (EEZ) Covered by Protected Areas
* Territorial Seas Covered (TS) by Protected Areas

## What are we doing?

We follow a simple 3-step methodology explained in the following links:

1. [Dissolving Geometries](stats/dissolving_geometries.md)
2. [Splitting Marine Protected Areas](stats/marine_intersection.md)
3. [Calculating Stats](stats/stats_calculator.md)

The geospatial operations are focused on countries and in the last step
statistics are aggregated for regions and the entire planet. We are also
using Spatial Indexing with GIST to increase the performance of spatial
queries.

This process takes around 6 hours to run automatically (2 hours for the
first step and 4 hours for the second step).
