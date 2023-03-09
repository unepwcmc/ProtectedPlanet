# Docker Setup

To overcome difficulties with the installation of old packages/versions on different machines and make the setup faster, you can choose to run this project with [Docker](https://docs.docker.com/get-docker/).

## Prerequisites
- Docker 20.10.22
- SQL dump of the production database from the Centre's AWS S3
- Freshly cloned repository with updated .env (LastPass)
 
_To avoid potential problems, remove `node_modules` from your current directory._
  

## Step 1: Docker setup
**1.1. Download and/or build all required images:**

```
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose build
```

**1.2. Start the containers:**

```
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose up
```

The following services should be running now:
- web (protectedplanet-web)
- db (protectedplanet-db)
- webpacker (protectedplanet-webpacker)
- elasticsearch (protectedplanet-elasticsarch)
- redis (protectedplanet-redis)
- sidekiq (protectedplanet-sidekiq)
- kibana (protectedplanet-kibana-1)

To access individual container's logs:

`docker logs --tail 500 protectedplanet-web`

To attach to individual container's console:

`docker attach protectedplanet-web`

## Step 2: Rails setup
**2.1. Run migrations for development**

```
docker exec -it protectedplanet-web rake db:create db:migrate db:seed
```

**2.2. Run migrations for testing**

```
docker exec -e "RAILS_ENV=test" -it protectedplanet-web rake db:create db:migrate db:seed
```

## Step 3: PP (WDPA) import
```
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose run -v {PATH_TO_WDPA_SQL_DUMP}:/import_database/pp_development.sql -e "PGPASSWORD={PGPASSWORD_FROM_ENV_FILE}" web bash -c "psql protectedplanet-db < /import_database/pp_development.sql -U postgres -h 0.0.0.0"
```

## Step 4: CMS setup
Step 3 should populate the database with the newest CMS data. Step 4.1. will add minor changes (e.g. correct images)

**4.1. Finish CMS setup**

```
docker exec -it protectedplanet-web rake cms_categories:import

docker exec -it protectedplanet-web rake comfy:staging_import

docker exec -it protectedplanet-web rake 'comfy:cms_seeds:import[protected-planet, protected-planet]'
```

**4.2.  Go to 'http://localhost:3000/en/admin/sites' and update the host to be `localhost:3000`**

**4.3. Reindex elasticsearch**

```
docker exec -it protectedplanet-web rake search:reindex
```

## Step 5: API setup (optional)
The [Protected Planet API](https://github.com/unepwcmc/protectedplanet-api) is a separate Sinatra/Grape application that uses the same database and is included as a service in the docker-compose.yml.

To use this service, you need to add the absolute path to your local protectedplanet-api directory in your .env file under the `API_ABSOLUTE_PATH` key.

The api service has an 'api' profile and so does not start automatically with `docker compose up`. You can either run it alongside all of the standard ProtectedPlanet services with:
```
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose --profile api up
```
or run only the api and db services with:
```
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose run api
```

### Debugging
For debugging with byebug, attach to the server console:
`docker attach protectedplanet-web`


# Deployment
To deploy the project with docker:

```
sudo docker exec -it protectedplanet-web cap staging deploy
```

### Troubleshooting:
- `SSH_AUTH_SOCK` not found: make sure `echo ${SSH_AUTH_SOCK}` returns a path to your ssh agent

- if yarn integrity problems appear: temporary fix `docker run web yarn install`

- if CMS seeds downloading fails, remove `db/cms_seeds` and retry

- to force the image to rebuild without cache: `docker compose build --no-cache`

- Docker cleanup:
  - to remove all containers: `docker rm -f $(docker ps -a -q)`
  - to remove all volumes: `docker volume rm $(docker volume ls -q)`
  - (careful) to remove all images: `docker rmi $(docker image ls -q)`

  