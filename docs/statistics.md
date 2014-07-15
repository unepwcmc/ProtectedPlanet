# Statistics

With every new WDPA release background jobs need to be run to create new dissolved geometries and calculate areas and coverage from them.

## Mollweide Projection

Postgis does not come with Mollweide support so you will need to run

```
ŕake geo_stats:insert_mollweide
```

After it you would be able to use 954009 as the SRID for Mollweide

## Dissolve geometries

We have a rake task that dissolves the geometries by each country. THis operation would take several days if we were using the full dataset. 
We have select the countries that have the most complex geometries to simplify them so we can do this operation in a reasonable time.
You should run:

```
ŕake geo_stats:dissolve_countries

```

This operation should take around one hour. It populates land_pas_geom and marine_pas_geom on the country table.

## Calculate statistics

We have a rake task that populates the country_statistics table. You can use it running:

```
ŕake geo_stats:calculate
```