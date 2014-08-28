# Statistics

The app renders three levels of stats: global, regional and country.

## Calculate Statistics

Stats are calculated, and then cached in their respective tables.
`country_statistics` for countries, and `regional_statistics` for
regions and global statistics.

```
bundle exec rake stats:calculate
```

## What are we doing here?

You can have a detailed explanation [here](stats.md).

### Dissolving protected areas by country

We have several protected areas that overlay each other. If we were
calculating the sum of all their areas we would not get the real area
protected.  That is why we are dissolving the protected areas by country
and type (marine/land).

### Simplifying geometries

In some countries we have a large number of protected areas and a very
large detail on them. We were taking too long to calculate them and the
country level results for simpflified geometries had no important
errors. So, we have selected the countries which were taking more than
an acceptable time and we have simplified their protected areas
geometries in 0.005º so we can dissolve all PA's in an hour.


### Handling with transnational Protected Areas

The only case where we intersect land protected areas with countries
geometries is when we have protected areas that cross boundaries.

### Handling Protected Areas represented by points

We are buffering the protected areas represented by points using their
reported area. These buffers are then dissolved with the polygons so we
can have a flat dataset. There is still an error in this one (Protected
Areas aren't perfect circles) but this is the closest way of getting
statistics for points.

###  Excluding particular areas

We are excluding the following Protected Areas according to the PA team
"Pre-processing of the WDPA dataset for coverage analyses" document:

- UNESCO-MAB Biosphere Reserves (UNESCO-MAB Réserve de Biosphère in
  French)
- Protected areas with 'Proposed' or 'Not Reported' status

### Marine Protected areas

We are intersecting the marine protected area with Exclusive Economic
Zones and Territorial Seas so we can calculate the statistics for both
zones. You can import them following the
[instructions](docs/installation.md#country-geometries).

### Intercontinental countries

We are considering that Russia and Turkey are in Asia to
calculate stats. In the future we may change th DB structure to split
the protected areas of these two countries and get more acurate values
for Regional Statistics.
