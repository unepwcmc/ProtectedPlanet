## Setup

Protected Planet is a standard Rails app, using a PostgreSQL database with
Postgis extensions.

### Installation

The application depends on Ruby, PostgreSQL and Postgis. They require no
special setup, so install them with your favourite package manager.

After that, it's pretty standard:

```
  bundle install
  rake db:setup
  bundle exec rails s
```

### Secrets

Some secrets are required by the application, such as AWS keys. Take a
look in [`config/secrets.yml.example`](config/secrets.yml.example) for
the options available, and fill them in as required (probably all of
them). **You will need to copy the `secrets.yml` example file for the
application to run correctly:**

```
  cp config/secrets.yml.example config/secrets.yml
```

## Data

### Initial Seeding

Some data is static and requires seeding if you're starting from an
empty database. For example, the Country and Sub Location list. If you
ran `rake db:setup` as above, you do not need to do anything else.

You can seed manually with:

```
  rake db:seed
```

### WDPA

The WDPA is regularly imported to Protected Planet via an Import tool in
the application. You can use that tool to setup your local database with
Protected Areas data. Check out the [WDPA docs](wdpa.md) for more info.
