# Protected Planet

[![Build Status](https://travis-ci.org/unepwcmc/ProtectedPlanet.svg)](https://travis-ci.org/unepwcmc/ProtectedPlanet)
[![Code Climate](https://codeclimate.com/repos/539b16466956806b20010ddc/badges/e90cf6ba84f66503705c/gpa.svg)](https://codeclimate.com/repos/539b16466956806b20010ddc/feed)
[![Test Coverage](https://codeclimate.com/repos/539b16466956806b20010ddc/badges/e90cf6ba84f66503705c/coverage.svg)](https://codeclimate.com/repos/539b16466956806b20010ddc/feed)

You can check out the previous version of Protected Planet on
[GitHub](https://github.com/unepwcmc/ppe).

## Topics

When you clone this repo please do it recursively. For the first time:
```
git clone --recurse-submodules
```

If you already cloned it:
```
git submodule update --init --recursive
```

1. [Getting Started and Configuration](docs/installation.md)
2. [Importing and Managing the WDPA](docs/wdpa.md)
    * [Automatic Import](docs/automatic_import.md)
3. [Deployment](docs/deployment.md)
4. [Development workflow, conventions and tips](docs/workflow.md)
5. [Search](docs/search.md)
6. [Background Workers](docs/workers.md)
7. [Downloads](docs/downloads.md)
8. [Statistics](docs/statistics.md)
9. [Caching](docs/caching.md)

## Licence

Protected Planet is released under the [BSD
3-Clause](http://opensource.org/licenses/BSD-3-Clause) License.

## Local 

### Setup

1. Import DB 
1. Import db seeds in `rake 'comfy:cms_seeds:import[protected-planet, protectedplanet]'`
1. Go to 'http://localhost:3000/en/admin/sites' and update the host to be `localhost:3000`
1. Index Elasicsearch in `rails c`
- Search::Index.delete 
- Search::Index.create 
- Search::Index.create_cms_fragments 

### Run application
1. `elasticsearch`
1. `redis-server`
1. `./bin/webpack-dev-server`
1. `rails s`

## Docker

You need a `.env` file similar to this:

```
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=protectedplanet-db
POSTGRES_MULTIPLE_EXTENSIONS=postgis,hstore,postgis_topology
REDIS_URL=redis://redis:6379/0
RAILS_ENV=development
ELASTIC_SEARCH_URL=http://elastic:elastic@elasticsearch:9200
xpack.security.enabled=false
discovery.type=single-node
```

The database is in a separate repo at the moment:
```
git submodule foreach git pull origin master
```

To prepare the Docker environment:
```
docker-compose build
```

To set-up the database
`docker-compose run web /bin/bash -l -c "rake db:create"`

To import the database sql dump:
```
docker-compose run -v ~/path/to/sql/dump:/import_database web bash -c "psql protectedplanet-db < /import_database/pp_development.sql -U postgres -h protectedplanet-db"
```

```
docker-compose run web /bin/bash -l -c "rake db:migrate"
docker-compose run web /bin/bash -l -c "rake db:seed"
```

To install front end dependencies
```
docker-compose run web /bin/bash -l -c "yarn install"
```

To precompile the assets
```
docker-compose run web /bin/bash -l -c "rake assets:precompile"
```

To bring up the ProtectedPlanet website locally:
```
docker-compose up
```

Visit: `http://localhost:3000`

To shutdown:
```
docker-compose down
```

To rebuild the Docker container after making changes:
```
docker-compose up --build
```

To reindex the data in Elasticsearch:
```
docker-compose run web /bin/bash -l -c "bundle exec rails c"
Search::Index.delete
Search::Index.create
```

For running tests, we have an additional table which must be created:
```
docker-compose run web /bin/bash -l -c "rails dbconsole"
Password for user postgres:
psql (11.1)
Type "help" for help.

protectedplanet-db=# CREATE DATABASE pp_test_backup;
CREATE DATABASE
```

Followed by:
```
docker-compose run -e "RAILS_ENV=test" web /bin/bash -l -c "rake db:create db:migrate db:seed"
```

Finally to actually run the tests:
```
docker-compose run -e "RAILS_ENV=test" web /bin/bash -l -c "rake test"
```

To backup a docker image to a tar file for sharing with others:
```
docker save protectedplanet_web > protectedplanet_web.tar
```

You can then share this exact tar file with anyone else and they will have an exact copy of that version of that Dockerised ProtectedPlanet, through loading it:

```
docker load < protectedplanet_web.tar.gz
```
