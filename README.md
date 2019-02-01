# Protected Planet

[![Build Status](https://travis-ci.org/unepwcmc/ProtectedPlanet.svg)](https://travis-ci.org/unepwcmc/ProtectedPlanet)
[![Code Climate](https://codeclimate.com/repos/539b16466956806b20010ddc/badges/e90cf6ba84f66503705c/gpa.svg)](https://codeclimate.com/repos/539b16466956806b20010ddc/feed)
[![Test Coverage](https://codeclimate.com/repos/539b16466956806b20010ddc/badges/e90cf6ba84f66503705c/coverage.svg)](https://codeclimate.com/repos/539b16466956806b20010ddc/feed)

You can check out the previous version of Protected Planet on
[GitHub](https://github.com/unepwcmc/ppe).

## Topics

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

## Docker

You need a `.env` file similar to this:

```
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_HOST=protectedplanet-db
REDIS_URL=redis://redis:6379/1
```

To prepare the Docker environment:
```
docker volume create protectedplanet_pg_data
docker volume create protectedplanet_redis_data
docker-compose build
```

To set-up the database
```
docker-compose run web rake db:create
docker-compose run web rake db:migrate
docker-compose run web rake db:seed
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
