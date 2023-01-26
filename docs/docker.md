# Docker Setup

To overcome difficulties with the installation of old packages/versions on different machines and make the setup faster, you can choose to run this project with [Docker](https://docs.docker.com/get-docker/).

## Prerequisites
- Docker 20.10.22
- SQL dump of the production database from the Centre's AWS S3
- Freshly cloned repository with updated .env (LastPass)
  

## Step 1: Docker setup
**1.1. Download and/or build all required images:**

```
docker compose build
```

**1.2. Start the containers:**

```
docker compose up
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
docker compose run -v {PATH_TO_WDPA_SQL_DUMP}:/import_database/pp_development.sql -e "PGPASSWORD={PGPASSWORD_FROM_ENV_FILE}" web bash -c "psql protectedplanet-db < /import_database/pp_development.sql -U postgres -h 0.0.0.0"
```

## Step 4: CMS setup
**4.1.  Go to 'http://localhost:3000/en/admin/sites' and update the host to be `localhost:3000`**

**4.2. Reindex elasticsearch**

```
docker exec -it protectedplanet-web rake search:reindex
```

Step 3 should populate the database with the newest CMS data. In case of a problem with the CMS seeds (images not rendering etc.), import the CMS seeds from staging:

`docker exec -it protectedplanet-web rake cms_categories:import`

`docker exec -it protectedplanet-web rake comfy:staging_import`

`docker exec -it protectedplanet-web rake 'comfy:cms_seeds:import[protected-planet, protected-planet]'`

and run 4.1-4.2 again


### Debugging
For debugging with byebug, attach to the server console:
`docker attach protectedplanet-web`

### Troubleshooting:
- if yarn integrity problems appear: temporary fix `docker run web yarn install`

- if CMS seeds downloading fails, remove `db/cms_seeds` and retry

- to force the image to rebuild without cache: `docker compose build --no-cache`

- Docker cleanup:
  - to remove all containers: `docker rm -f $(sudo docker ps -a -q)`
  - to remove all volumes: `docker volume rm $(sudo docker volume ls -q)`
  - (careful) to remove all images: `docker rmi $(docker images -a -q)`

  