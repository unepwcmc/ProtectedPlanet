## Setup

Protected Planet is a standard Rails app, using a PostgreSQL database with
Postgis extensions.

### Installation

The application depends on:

* Ruby
* PostgreSQL
* Postgis
* Redis

They require no special setup, so install them with your favourite
package manager. For example, on OS X:

```
  # Get https://rvm.io or any other ruby version manager, then...
  brew install postgresql
  brew install postgis
  brew install redis
```

After that, it's pretty standard:

```
  bundle install
  rake db:setup

  bundle exec rails s
```

### Configuration and Secrets

Some secrets are required by the application, such as AWS keys. Take a
look in [`config/secrets.yml.example`](config/secrets.yml.example) for
the options available, and fill them in as required (probably all of
them). **You will need to copy the `secrets.yml` example file for the
application to run correctly:**

```
  cp config/secrets.yml.example config/secrets.yml
```

Generally `secrets.yml` is also used for non-secret configuration, so
that the config values can reside in the same file for easy maintenance.
It is advisable that only in exceptional circumstances do you put custom
config in environments files or other initializers.

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
  rake db:seed
```

### WDPA

The WDPA is regularly imported to Protected Planet via an Import tool in
the application. You can use that tool to setup your local database with
Protected Areas data. Check out the [WDPA docs](wdpa.md) for more info.
