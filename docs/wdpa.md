### WDPA Import

The WDPA is uploaded to AWS S3 on a monthly basis (though sometimes more
often) by the Protected Areas team at UNEP-WCMC. It's stored as a [File
Geodatabase](http://webhelp.esri.com/arcgisdesktop/9.2/index.cfm?topicname=types_of_geodatabases),
which means we have to do some conversions before we can use the data in
the application.

**NOTE:** none of the following steps are required to install or setup
the application.

#### Importing to Rails

In the Rails console, run the following:

```
  Wdpa::Importer.import
```

This downloads the WDPA, imports it to your local PostgreSQL install and
creates the appropriate Rails models for the Protected Areas.

Some attributes (wikipedia summaries, etc.) take some time to generate
and so depend on Sidekiq workers to be calculated. Thus having a Redis
server running is a requirement so that these jobs can be queued -- see
the [workers docs](workers.md) for more info.

The WDPA modules have [documentation](../lib/modules/wdpa/README.md)
available.

##### Imported Data Retention

The WDPA is imported in to the Rails database (e.g. `pp_development`)
and consists of three tables: polygon, points and source. Although these
aren't used in the general running of the application, they are kept so
that we can generate downloads with the WDPA Data Standard without
having to re-transform the data back to how it started.

You can find more info in the [download documentation](downloads.md).

##### Testing the import process

Generally in development you are able to use the database dump given in
the [installation docs](installation.md). However, if you need to test
the import process, using the whole WDPA can be time consuming. There is
a smaller File Geodatabase [available on
S3](http://protectedplanet.s3.amazonaws.com/WDPA_dev.zip).

#### Map Tiles and Geometries

Map tiles are stored and rendered by [CartoDB](http://cartodb.com). Due
to the complexity of running this, there is no easy way to render tiles
for your local dataset, and so locally you will render the same tiles
that are run in production -- thankfully you are unlikely to find this a
problem.

You do not have to do any CartoDB setup in development. The CartoDB
modules have [documentation](../lib/modules/carto_db/README.md)
available for production.

#### Esri ArcGIS REST Service

An ArcGIS REST service is provided for analysing the Protected Areas
data directly. It runs independently of the Protected Planet
application -- you can find more documentation about it in the [GitHub
Repository](https://github.com/unepwcmc/ProtectedPlanet-ESRI).
