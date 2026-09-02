# Local setup with Docker

Docker is the only supported way to run this app locally.

## Prerequisites

- Docker Desktop
- A freshly cloned repo, **with submodules** (see the [README](../README.md))
- A `.env` file — copy `.env.example` and fill it from Keeper
- No `node_modules/` left over from a non-Docker checkout

## 1. Start the stack

```bash
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose up
```

`SSH_AUTH_SOCK` is needed because the bundle pulls a gem from a private git
remote. The first build takes a long time.

An `install` service runs `bundle install`, `yarn install`, the Puppeteer Chrome
download and `comfy:compile_assets` **once** into shared volumes; `web`, `vite`
and `sidekiq` wait on it rather than racing each other.

| Service | Container | Port |
|---|---|---|
| `web` — Rails (runs `db:migrate` on boot) | `protectedplanet-web` | 3000 |
| `vite` — Vite dev server | `protectedplanet-vite` | 3036 |
| `sidekiq` — background jobs, incl. the PDF capsule | — | — |
| `db` — PostGIS | `protectedplanet-db` | 5441 |
| `db_test` — PostGIS for `rails test` | `protectedplanet-db-test` | 5442 |
| `redis` | `protectedplanet-redis` | 6379 |
| `elasticsearch` | `protectedplanet-elasticsearch` | 9200 |
| `kibana` | — | 5601 |
| `memcached` | — | 11211 |
| `mailpit` — catches outgoing mail | `protectedplanet-mailpit` | 1025 / 8025 (UI) |
| `minio` — S3 stand-in for downloads | — | 9000 / 9001 (console) |
| `api` — profile `api`, see step 5 | `protectedplanet-api` | 9292 |

```bash
docker logs --tail 500 protectedplanet-web   # logs
docker attach protectedplanet-web            # console (byebug)
```

## 2. Restore the database

Take a dump from the PP production DB server, then:

```bash
psql -h localhost -p 5441 -U postgres pp_development < pp_production_backup.sql
```

The password is `POSTGRES_PASSWORD` from your `.env`.

## 3. Connect to the Data Management Portal

The release importers read the portal database over PostgreSQL FDW —
[set that up next](fdw_setup/index.md).

## 4. Reindex Elasticsearch (optional)

```bash
docker exec -it protectedplanet-web rake search:reindex
```

## 5. API (optional)

The [Protected Planet API](https://github.com/unepwcmc/protectedplanet-api) is a
separate app sharing this database. Point `API_PATH` in `.env` at your local
checkout, then:

```bash
SSH_AUTH_SOCK=$SSH_AUTH_SOCK docker compose --profile api up
```

## 6. PDF generation (optional)

Chromium is downloaded at image build time (`npx puppeteer browsers install
chrome`, cached in `node_modules/.puppeteer-cache`) — no manual setup.

The generator runs in the `sidekiq` container and renders the page by fetching
it over HTTP, so it needs a hostname that resolves from there.
`PDF_RASTERIZER_HOST` sets that hostname; unset, it falls back to `PP_HOST`
(`config.x.app_host`).

**Locally, set `PDF_RASTERIZER_HOST=protectedplanet-web:3000` in `.env`.** That is
a docker-compose service name, so the sidekiq container reaches the web container
directly over the compose network. The `PP_HOST` fallback is no use here: in dev it
is `localhost:3000` (or `host.docker.internal:3000`), neither of which a sibling
container can hairpin back through.

**On production, leave `PDF_RASTERIZER_HOST` unset and let `PP_HOST` do its thing.**
The production host is publicly resolvable, so the job container hairpins out through
kamal-proxy and back in ~0.11s — not worth optimising away. Never copy the dev
value into a Kamal env or secret: `protectedplanet-web` resolves to nothing there,
and every PDF render fails at navigation.

Rails 8's Host Authorization rejects Host headers not on its allowlist, and a
Docker service name isn't covered by the built-in private-IP allowance (literal
IPs only). `config/environments/development.rb` allows `protectedplanet-web`
explicitly — add any hostname you point `PDF_RASTERIZER_HOST` at.

See [pdf-shared-chrome.md](pdf-shared-chrome.md) for how the shared browser works.

## Running tests

`rails test` must use the PG17 `db_test` container, not `db`:

```bash
docker exec -e TEST_POSTGRES_HOST=protectedplanet-db-test -it protectedplanet-web \
  bundle exec rails test
```

## Troubleshooting

- **`SSH_AUTH_SOCK` not found** — check `echo $SSH_AUTH_SOCK` returns a path.
- **Yarn integrity errors** — `docker compose run --rm web yarn install`.
- **Rebuild from scratch** — `docker compose build --no-cache`.
- **Collation mismatch on `db:test:prepare`** — run
  `ALTER DATABASE template1 REFRESH COLLATION VERSION` on `db_test`.
- **Cleanup** — `docker rm -f $(docker ps -aq)`,
  `docker volume rm $(docker volume ls -q)`, and (careful)
  `docker rmi $(docker image ls -q)`.

Next: [Development workflow, conventions and tips](workflow.md).
