## Setup and Configuration

Protected Planet is a standard Rails app, using a PostgreSQL database with
Postgis extensions.

### Installation

The application depends on:

* Ruby
* PostgreSQL
* GDAL
* Postgis
* Redis

They require no special setup, so install them with your favourite
package manager. For example, on OS X:

```
  # Get https://rvm.io or any other ruby version manager, then...
  brew install postgresql
  brew install gdal --with-postgresql
  brew install postgis
  brew install redis
```

If you are running Ubuntu or another Linux distribution, see "GEOS and
Linux" below.

After that, it's pretty standard:

```
  bundle install
  rake db:setup

  bundle exec rails s
```

#### GEOS and Linux

The RGeo gem is dependent on GEOS (which is installed with GDAL) being
linked to the correct location on disk. The latest versions of GEOS
installed by package managers on most Linux distributions are located
incorrectly for RGeo's use. You can fix this easily:

```
  ls /usr/lib | grep geos
    #=> /usr/lib/libgeos-3.4.2.so
  ln -s /usr/lib/libgeos-3.4.2.so /usr/lib/libgeos.so
```

### Configuration and Secrets

Application config is stored in `config/secrets.yml`, along with certain
required secrets (such as AWS keys). To make development easier, the
secrets.yml file uses environment variables to set secret config keys.

In development, these can be setup using a
[dotenv](https://github.com/bkeepers/dotenv) file in the project root.
There is a template `.env` available, and should be used and filled in so
that you don't have to manually set the required environment variables:

```
cp .env.example .env
```

### Background Workers

Some tasks that take a long time require processing in the background,
and are handled by Sidekiq. See the [workers docs](workers.md) for more
info.

## Data

### Lazy Seeding for Development

In development you can use a pre-made database that is seeded with Countries,
Protected Areas, etc. Download the
[dataset](http://protectedplanet.s3.amazonaws.com/pp_development.tar.bz2) off
S3, and:

```
  tar xvf pp_development.tar.bz2
  psql pp_development < pp_development.sql
```

#### Manual Seeding

You can manually seed the database with data using the instructions below.

Some data is static and requires seeding if you're starting from an
empty database. For example, the Country and Sub Location list. If you
ran `rake db:setup` as above, you do not need to seed anything.

You can seed manually with:

```
  rake db:seed
```

### Country Geometries

Geometries for countries are required for stats generation, and for
generating shapefiles to be uploaded to CartoDB.

`rake import:countries_geometries`

#### Importing to CartoDB

The stats pages are dependent on a `countries_geometries` tables in
CartoDB for rendering country outlines on the map.

This is created using the geometries imported above. Export the
countries geometries as a CartoDB compliant format (Shapefile, CSV,
etc.) using ogr2ogr, shp2pgsql or even qgis, and upload to CartoDB.

### WDPA

The WDPA is regularly imported to Protected Planet via an Import tool in
the application. You can use that tool to setup your local database with
Protected Areas data. Check out the [WDPA docs](wdpa.md) for more info.
