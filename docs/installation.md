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
  rake db:migrate
  rake db:lazy_seed

  bundle exec rails s
```

There is a database dump available so that you can work with real data
straight away. See "Lazy Seeding" below.

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

You can manually seed the database with data using the instructions below.

### Initial Seeding

Some data is static and requires seeding if you're starting from an
empty database. For example, the Country and Sub Location list. If you
ran `rake db:setup` as above, you do not need to seed anything.

You can seed manually with:

```
  rake db:lazy_seed
```

Or if you have plenty of time, and want to manually run your seeds:

```
  rake db:seed
```

### WDPA

The WDPA is regularly imported to Protected Planet via an Import tool in
the application. You can use that tool to setup your local database with
Protected Areas data. Check out the [WDPA docs](wdpa.md) for more info.
