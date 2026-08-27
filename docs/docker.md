# Docker Setup

To overcome difficulties with the installation of old packages/versions on different machines and make the setup faster, you can choose to run this project with [Docker](https://docs.docker.com/get-docker/).

## Prerequisites
- Docker 29.2.0
- Docker Desktop (optional but easier to manage)
- Freshly cloned repository with updated .env (Keeper)
 
_To avoid potential problems, remove `node_modules` from your current directory._
  

## Step 1: Docker setup

Run compose up to build/run all services:

```
docker compose up
```
 

After very long long long build time the following services should be running:
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

## Step 2: Database restore

> **Already have a local database from before Aug 2026?** It is a PostgreSQL 11 cluster, and
> `db` now runs Postgres 17 — it will refuse to start with *"incompatible data directory"*
> until you upgrade it. That is a one-off, ~10 minute job that keeps your data:
> **[docker/pg-upgrade/README.md](../docker/pg-upgrade/README.md)**. Setting up fresh? Nothing
> to do — you get a 17 cluster.

**2.1. Recommended: restore a production dump into Docker Postgres**

The recommended way to populate your local database is:

- Start the stack:

  ```bash
  SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose up
  ```

- Create a fresh dump from the PP production DB server (e.g. `pp_production_backup.sql`)
- Restore it into your local Docker Postgres:
  - In your local machine terminal run `psql -h localhost -p 5441 -U postgres pp_development < pp_production_backup.sql`
  - When prompted for the Postgres password, use the value of `POSTGRES_PASSWORD` from your `.env` file.

## Step 2: (Optional) Reindex elasticsearch

```
docker exec -it protectedplanet-web rake search:reindex
```

## Step 3: Set up database connection with Data Management Portal 
[Read here](fdw_setup/index.md)

## Step 4: API setup (optional)
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

## Step 5: PDF generator setup (optional)

- If you need the pdf generator to generate PDFs then you need to do the following.
- The Chromium binary Puppeteer needs is downloaded automatically at image build time
  (`npx puppeteer browsers install chrome` in the `Dockerfile`, cached under
  `node_modules/.puppeteer-cache` so it survives container restarts) — no manual setup required.
  The download itself retries 3x and goes through a Docker build cache mount, so a rebuild
  doesn't need Google's Chrome-for-Testing bucket to still have that exact build once it's been
  fetched successfully once on a given host — see the comment above that `RUN` step in the
  `Dockerfile`.
- In `.env`, set `PDF_RASTERIZER_HOST=protectedplanet-web:3000` so the PDF generator (running inside
  the `sidekiq` container) reaches the app directly over the internal Docker network instead of
  round-tripping through the public site domain. This is deliberately separate from `MAILER_HOST`
  (`config/app_secrets.yml`'s `mailer.host`, which is what `default_url_options` actually resolves
  to for every other absolute URL the app generates, including real outgoing email links) — don't
  repurpose `MAILER_HOST` for this, or you'll silently redirect those emails too. If
  `PDF_RASTERIZER_HOST` is unset, the PDF generator falls back to `MAILER_HOST`.
- Rails 8's Host Authorization middleware rejects any Host header not on its allowlist, and a Docker
  service name like `protectedplanet-web` isn't covered by its built-in loopback/private-IP allowance
  (that only covers literal IPs, not DNS names) — `config/environments/development.rb` explicitly
  allows it for this reason. If you rename the `web` service or point `PDF_RASTERIZER_HOST` at
  something else, add that hostname there too.

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