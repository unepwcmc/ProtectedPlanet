> ## ⚠️ **WARNING**
>
> Please use docker.md to setup locally and this doc is out of date
>

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

## ProtectedPlanet-db fetch
From time to time if your db is not up to date then 
- cd inside db folder
- git fetch
- git merge origin/master
- You should now have the latest db repo

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
  # Install postgresql@9.4 (see instructions below)
  # Install GDAL v2 now (see instructions below)
  brew install postgis
  brew install redis
  brew tap elastic/tap 
  brew install elastic/tap/elasticsearch-full # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/brew.html

  # for assets
  brew install yarn
  yarn install
```
#### Ruby Installation
    RUBY_CFLAGS="-w" rbenv install 2.6.3
#### PostgreSQL Installation

Brew may refuse to install v9. You could:

1. Download the [PostgreSQL legacy app](https://postgresapp.com/downloads_legacy.html) 
2. For Mac, try https://ralphjsmit.com/set-up-dbngin-tableplus
3. Your own method

#### GDAL Installation
1. Brew uninstall GDAL (if installed through Brew)
2. Install GDAL from http://www.kyngchaos.com/files/software/frameworks/GDAL_Complete-2.1.dmg
3. Check `which gdal-config` to see which path it originates from. 
4. 
If this doesn't work on MacOS, check `/Library/Frameworks/GDAL.framework/Programs/gdal-config` - you may need to add this to your PATH
3. `gem uninstall gdal`
4.
```
gem install gdal -v 2 -- --with-gdal-lib=/Library/Frameworks/GDAL.framework/unix/lib --with-gdal-includes=/Library/Frameworks/GDAL.framework/Versions/Current/Headers/
```

#### Set up

Use `brew services` to start `redis`, `elasticsearch`, and `postgres`.

If you are running Ubuntu or another Linux distribution, see "GEOS and
Linux" below.

After that, it's pretty standard:

```
  bundle install
  rails db:create
  rails db:migrate
  rails db:seed
```

There's subsequently two ways you can get the WDPA into your system. Either you 
can import the release locally, or alternatively you can get a database dump from
S3 and restore it into your local database.

#### Local import of release

The old walkthrough here polled an S3 bucket for a monthly WDPA geodatabase and
ran it through `ImportWorkers::S3PollingWorker` on a dedicated `import` Sidekiq
queue. **That entire path was removed in Aug 2026** — it had been superseded by
the portal release, and its own code said so.

Imports now run synchronously through rake, not through Sidekiq:

```
bundle exec rake 'pp:portal:release[<label>]'
```

`lib/tasks/portal_dev_tools.rake` has the escape hatches you will actually want
locally — `dev:import_only`, `dev:import_skip`, `dev:import_resume` and
`dev:release_resume` — so a partial or failed import can be resumed rather than
restarted. See `docs/release/portal_release_runbook.md` for the full procedure.

In practice, restoring a database dump (above) is far quicker than running an
import locally.

#### Alternative setup

For this, you will need: 
- Access to the centre's S3 instance
- PostgreSQL installed and working

This approach uses a database dump from production and restores it directly into 
your local database. With this method, you can be sure that you have the most up
to date data, particularly with respect to the CMS which most frequently changes. 

1. Download the latest database dump, which should be a TAR file, from the Daily folder within the `pp.bkp` bucket
2. In the terminal, run `pg_restore -d pp_development <path/to/your/file/dump_name.tar> -c -U <username>`


### Final steps

1. Run `rake cms_categories:import` to create the custom Comfy page and layout categories.
2. Go to `http://localhost:3000/en/admin/sites` and update the host to be `localhost:3000`
if not already set.
3. Reindex the search: `rake search:reindex`

Your CMS content comes from the database dump you restored above — there is no
separate seed-import step

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
If you are using Ubuntu and are having issues installing GEOS (via GDAL that you will notice after failure to `bundle _2.4.22_ install` then see [this](https://stackoverflow.com/questions/12141422/error-gdal-config-not-found) SO question - you can install the library required with `sudo apt update && sudo apt install libgdal-dev`.

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

Application config is stored in `config/app_secrets.yml`, along with certain
required secrets (such as AWS keys). To make development easier, the
app_secrets.yml file uses environment variables to set secret config keys.

Read it with `Rails.application.config_for(:app_secrets)`, or the `AppSecrets`
constant (set up in `config/initializers/00_app_secrets.rb`) from app code.
It was `config/secrets.yml` + `Rails.application.secrets` until Rails 7.2, which
removed that API.

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
