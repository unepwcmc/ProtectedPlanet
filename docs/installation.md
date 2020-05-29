## Setup and Configuration

Protected Planet is a standard Rails app, using a PostgreSQL database with
Postgis extensions.

⚠️ **This repository has submodules, be sure to clone it using `git clone --recursive`**

Submodules can be manually updated by running
```
  git submodule init
  git submodule update
```
Changes can be pulled by running
```
  git fetch
  git merge <branch>
```
from within the submodule (here `db`) folder.

### Installation

The application depends on:

* Ruby
* PostgreSQL
* GDAL
* Postgis
* Redis
* Elasticsearch

They require no special setup, so install them with your favourite
package manager. For example, on OS X:

```
  # Get https://rvm.io or any other ruby version manager, then...
  brew update
  brew install postgresql
  brew install gdal --with-postgresql
  brew install postgis
  brew install redis
  brew install elasticsearch

  # for assets
  brew install yarn
  yarn install
```

Use `brew services` to start `redis`, `elasticsearch`, and `postgres`.

If you are running Ubuntu or another Linux distribution, see "GEOS and
Linux" below.

After that, it's pretty standard:

```
  bundle install
  rake db:create
  rake db:migrate
  rake bower:install

  bundle exec rails s
```

Before you can really do much with the website, you'll need to import
a WDPA release. We have a small subset in the development S3 bucket,
so make sure you have the right secrets in your `.env`, and run this:

```
  bundle exec sidekiq

  # in another window
  bundle exec rails c
  > ImportWorkers::S3PollingWorker.perform_async
```

This will look for the latest file in the S3 bucket, and use it to import
its protected areas, countries, and whatnot. After 5 to 10 minutes, the main
worker will be done (you can check this in the sidekiq output). At this point,
go back to the rails console and enter

```
  > ImportWorkers::FinaliserWorker.perform_async
```
This will take another couple of minutes. After this, you are ready to `localhost:3000`!


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

**Update by J. Feist**
If you are using Ubuntu and are having issues installing GEOS (via GDAL that you will notice after failure to `bundle _1.17.3_ install` then see [this](https://stackoverflow.com/questions/12141422/error-gdal-config-not-found) SO question - you can install the library required with `sudo apt update && sudo apt install libgdal-dev`.

You may also need to install PostGIS for PostgreSQL e.g. `sudo apt install -y postgresql-10-postgis-2.4 && sudo service postgresql restart` if you get [this](https://gis.stackexchange.com/questions/271394/error-could-not-access-file-libdir-postgis-2-4-no-such-file-or-directory?newreg=ced3ebbc15f444e6b6fd0b64f7a8775b) error.

Please note, if you experience an error when viewing the regions or countries pages like this:

```
undefined method `point' for nil:NilClass
```

You must install the rgeo gem with the correct path for geos specified. Please use the following example as guidance:

```
  /usr/local/bin/geos-config --prefix
    /usr/local/Cellar/geos/3.6.2

  gem install rgeo --version '=0.4.0' -- --with-geos-dir=/usr/local/Cellar/geos/3.6.2/
    Building native extensions with: '--with-geos-dir=/usr/local/Cellar/geos/3.6.2/'
    This could take a while...
    Successfully installed rgeo-0.4.0
    Parsing documentation for rgeo-0.4.0
    Done installing documentation for rgeo after 2 seconds
    1 gem installed
```

This error should now be resolved.

### Configuration and Secrets

Application config is stored in `config/secrets.yml`, along with certain
required secrets (such as AWS keys). To make development easier, the
secrets.yml file uses environment variables to set secret config keys.

In development, these can be easily setup using a
[dotenv](https://github.com/bkeepers/dotenv) file in the project root.
There is a template `.env` available, and should be used and filled in so
that you don't have to manually set the required environment variables:

```
cp .env.example .env
```

Currently, despite best practices, dotenv is used in production. Should
you need to add a new piece of secret configuration, you will have to
add it to the server's `.env` file.

### Background Workers

Some tasks that take a long time require processing in the background,
and are handled by Sidekiq. See the [workers docs](workers.md) for more
info.

### WDPA

The WDPA is regularly imported to Protected Planet via an Import tool in
the application. You can use that tool to setup your local database with
Protected Areas data. Check out the [WDPA docs](wdpa.md) for more info.
