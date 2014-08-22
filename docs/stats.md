#Complex Geospatial Statistics with Postgres/PostGIS

As you may know we are managing [ProtectedPlanet.net](http://www.protectedplanet.net), a website which shows all the protected areas in the world.

No we are rebuilding it. At the end of the year we will have a completely new website running. You can view all the code for this new website in its repository on github.

Coverage Statistics is one of the main features. It is very important for the users to know what is the percentage of the territory that is covered by protected areas in a certain country These statistics were not calculated manually in the old website and every year we had a team spending several days to calculate them for an yearly report.

So we had a great challenge this time:

Can we automatically calculate the statistics every month for all the protected areas and countries in the entire planet?

In this case time matters. If we want to calculate statistics every month it is not supposed to take 2 or 3 days processing as it was taking using mainly ESRI software. We have chosen a full open source solution with Postgres/PostGIS to do all the back end tasks that we need to calculate statistics.

What do we have?

We have two sets of protected areas: Points and Polygons. The vast majority (around 90%) is in polygon format with the boundaries of each protected area defined.

The protected areas represented by points have, in some cases, a 'reported area' column. We do not have the boundaries but we can create polygons buffering according to the area.

The protected areas can be marine or terrestrial and the base dataset has a column categorize them.

In the great majority of the cases the protected areas are completely within a country and there is also a column with the ISO3 of it. However there are some transboundary sites that belong to 2 or three countries.

We can have different protected areas for the same point. For instance, you can be in a Park that it is at the same time an UNESCO World Heritage Site, a National Park and a Natura 2000 area. Due to this particularity we have Protected Area's polygons overlapping each other.

What do we need?

r.

Creating a flat dataset

To have