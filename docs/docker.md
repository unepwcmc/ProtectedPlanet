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

## Step 2: DB setup (New method)
**2.1. Run migrations for development**

```
docker exec -it protectedplanet-web rake db:create
```

** Since in the next step [Step 3: PP (WDPA) import](#step-3:-pp-(wdpa)-import) we are importing production db dump so we do not want to duplicate some table content again to avoid errors while importing db. However, if you find the new method does not work for you please update this section as I am the first developer using this method

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

You will need to download a recent copy of the PP production database. If you are using [aws cli](https://github.com/unepwcmc/wiki/wiki/AWS-CLI), you can run the following:
```
aws s3 ls # see buckets
aws s3 ls s3://pp.bkp --recursive --human-readable --summarize # see contents of bucket
aws s3 cp s3://pp.bkp/Weekly/db/pp_weekly/2023.02.01.05.00.06/pp_weekly.tar pp.tar # copy a pp db dump to a local file
```

Once downloaded unzip the .tar file until you see .sql file
Copy the .sql file FULL path and use the command below to import the sql dump into the docker database
Replace {PATH_TO_WDPA_SQL_DUMP} with the actual file path

```
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose run -v {PATH_TO_WDPA_SQL_DUMP}:/import_database/pp_development.sql -e "PGPASSWORD={PGPASSWORD_FROM_ENV_FILE}" web bash -c "psql pp_development < /import_database/pp_development.sql -U postgres -h 0.0.0.0"
```
*** Notice! the pp_development here has to be the same set for variable POSTGRES_DBNAME in .env file

*** You might see the following error
  could not connect to server: Connection refused. Is the server running on host "protectedplanet-db" (172.18.0.4) and accepting TCP/IP connections on port 5432.

  That is because web container is run before db container. The solution for this is do not stop any running containers instead run the command again.

## Step 4: CMS setup
Step 3 should populate the database with the newest CMS data. Step 4.1. will add minor changes (e.g. correct images)

**4.1. Finish CMS setup**

```
docker exec -it protectedplanet-web rake cms_categories:import

docker exec -it protectedplanet-web rake comfy:staging_import

docker exec -it protectedplanet-web rake 'comfy:cms_seeds:import[protected-planet, protected-planet]'
```

**4.2.  Go to 'http://localhost:3000/en/admin/sites' and update the host to be `localhost:3000`**
Credentials are found in your .env file under COMFY_ADMIN_USERNAME and COMFY_ADMIN_PASSWORD

**4.3. Reindex elasticsearch**

```
docker exec -it protectedplanet-web rake search:reindex
```

## Step 5: API setup (optional)
The [Protected Planet API](https://github.com/unepwcmc/protectedplanet-api) is a separate Sinatra/Grape application that uses the same database and is included as a service in the docker-compose.yml.

To use this service, you need to add the path to your local protectedplanet-api directory in your .env file under the `API_PATH` key.

The api service has an 'api' profile and so does not start automatically with `docker compose up`. You can either run it alongside all of the standard ProtectedPlanet services with:
```
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose --profile api up
```
or run only the api and db services with:
```
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose run api
```
## Recommend you to read this section
### The md below gives you all difficulties and tips that other developers have faced when set up/ work on this project so you overcome them without spending a lot of time finding solutions.
[Development workflow, conventions and tips](docs/workflow.md)

### Debugging
For debugging with byebug, attach to the server console:
`docker attach protectedplanet-web`


# Deployment
To deploy PP.net with docker:

```
sudo docker exec -it protectedplanet-web cap staging deploy
```

To deploy the PP API with docker:
```
sudo docker exec -it protectedplanet-api cap staging deploy
```

### Troubleshooting:
- `SSH_AUTH_SOCK` not found: make sure `echo ${SSH_AUTH_SOCK}` returns a path to your ssh agent

- if yarn integrity problems appear: temporary fix `docker run protectedplanet-web yarn install`

- if CMS seeds downloading fails, remove `db/cms_seeds` and retry

- to force the image to rebuild without cache: `docker compose build --no-cache`

- Docker cleanup:
  - to remove all containers: `docker rm -f $(docker ps -a -q)`
  - to remove all volumes: `docker volume rm $(docker volume ls -q)`
  - (careful) to remove all images: `docker rmi $(docker image ls -q)`

# Edit this file
<mark>If you do edit this file please consider if [Docker Setup - For Mac](docker-mac.md) also needs editting</mark>