# 08 — Sidekiq & background workers

| | |
|---|---|
| **Estimate** | 1–2 weeks · ~0.25–0.5 month |
| **Depends on** | [03 — Rails 6.1](./03-rails-6.md) (Sidekiq 5→6 done there) · [04 — Rails 7.1 (B0)](./04-rails-7.md) |
| **Blocks** | Nothing independently — schedule after B0 |

[← Back to overview](./README.md)

---

## Goal

Sidekiq upgraded from 5.2.5 to 7.x. All background workers — import pipeline and download workers — smoke-tested end-to-end. Scheduled jobs confirmed working.

---

## Current state

| Component | Detail |
|-----------|--------|
| Sidekiq version | 5.2.5 |
| Queues | `default` (downloads) · `import` (WDPA pipeline) |
| Sidekiq processes | `pp_default` · `pp_import` (two separate systemd/service entries) |
| Scheduled job | `S3PollingWorker` — every hour via `whenever` / cron |
| Deploy | `capistrano-sidekiq` 1.0.2; `service:pp_default:restart` + `service:pp_import:restart` after publish |

---

## Upgrade path: 5 → 6 → 7

Sidekiq must be upgraded in two steps. Do not jump directly from 5 to 7.

### Step 1 — Sidekiq 5 → 6 (done in [03 — Rails 6](./03-rails-6.md))

Sidekiq 6 is the most compatible intermediate. Key changes:

- Ruby 2.5+ required (already on 2.7)
- Web UI middleware registration: if using `Sidekiq::Web`, the mount syntax changed slightly
- Config file format (`config/sidekiq.yml`) unchanged

Confirm in phase 3:
- [ ] `gem 'sidekiq', '~> 6.5'` — use latest 6.x patch
- [ ] Update `capistrano-sidekiq` to `~> 2.x` (required for Sidekiq 6 compat)
- [ ] Boot Sidekiq locally with both queues — confirm no errors
- [ ] Run one download job manually — confirm completion

---

### Step 2 — Sidekiq 6 → 7 (this phase)

Sidekiq 7 has more significant changes.

**Configuration DSL changed:**

```ruby
# Sidekiq 6 (config/initializers/sidekiq.rb)
Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

# Sidekiq 7 — same pattern works, but some options moved
# Check for any use of `Sidekiq.options[:...]` — now via `Sidekiq.default_configuration`
```

- [ ] Audit `config/initializers/sidekiq.rb` — update to Sidekiq 7 config API
- [ ] Check `config/sidekiq.yml` and `config/sidekiq-import.yml` — format is backwards-compatible but verify

**Sidekiq Pro / Enterprise features:**

- Not used in this app — no action

**Web UI:**

- `Sidekiq::Web` requires Rack 2.x or 3.x — confirm `config/routes.rb` mount still works
- Sinatra 3.x required (upgrade `sinatra` gem — see [01](./01-gem-audit.md))

**`perform_async` / worker API:**

- Unchanged — no migration needed in worker files themselves

**Scheduled jobs (via `whenever`):**

- `config/schedule.rb` runs `S3PollingWorker.perform_async` — this API is unchanged
- [ ] Confirm `whenever` gem generates correct cron syntax on Ruby 3.x

---

## Worker inventory

### Download workers (`app/workers/download_workers/`)

| Worker | Purpose |
|--------|---------|
| `base.rb` | Base class |
| `general.rb` | General area downloads |
| `pdf.rb` | PDF generation (triggers Puppeteer) |
| `protected_area.rb` | PA-specific downloads |
| `search.rb` | Search result downloads |

- [ ] Run each download type manually after Sidekiq upgrade — confirm completion
- [ ] PDF worker: confirm Puppeteer `pdf.rb` still calls `rasterize.js` correctly (no Ruby changes expected, but smoke-test)

### Import workers (`app/workers/import_workers/`)

| Worker | Purpose | Notes |
|--------|---------|-------|
| `s3_polling_worker.rb` | Polls S3 for new WDPA releases | Runs every hour via `whenever` |
| `main_worker.rb` | Orchestrates the import | Called by S3 polling worker |
| `protected_areas_importer.rb` | Core PA data import | High-risk — touches PostGIS |
| `geometry_populator_worker.rb` | Populates geometry columns | Reads shapefiles via GDAL |
| `finaliser_worker.rb` | Post-import cleanup / indexing | May call Elasticsearch reindex |

**Import pipeline chain:**
```
S3PollingWorker (cron, hourly)
  └─ MainWorker
       └─ ProtectedAreasImporter  (imports PA data)
            └─ GeometryPopulatorWorker  (populates geometries)
                 └─ FinaliserWorker  (cleanup, ES index update)
```

- [ ] Trigger a test import run (staging, with a small fixture) after Sidekiq 7 upgrade
- [ ] Confirm the full chain completes without errors
- [ ] Verify S3 polling worker still reads the correct S3 bucket (env var check)
- [ ] Confirm `net-sftp` / `net-scp` calls in import workers still work on Ruby 3.x

---

## Capistrano integration

`config/deploy.rb` restarts both Sidekiq services after deploy:

```ruby
after :publishing, 'service:pp_default:restart'
after :publishing, 'service:pp_import:restart'
```

- [ ] Upgrade `capistrano-sidekiq` to `~> 3.x` (Sidekiq 7 compatible)
- [ ] Confirm `service:pp_default:restart` and `service:pp_import:restart` still work after gem upgrade
- [ ] Test a staging deploy — confirm both services restart cleanly

---

## Redis

Sidekiq uses Redis. Confirm the Redis version on production is compatible with Sidekiq 7 (requires Redis 6.2+):

```bash
ssh wcmc@new-web.pp-production.linode.protectedplanet.net 'redis-cli info server | grep redis_version'
```

- [ ] Confirm Redis version; upgrade if below 6.2

---

## Exit criteria

- Sidekiq 7.x running locally and on staging
- Both queues (`default`, `import`) processing jobs
- S3 polling worker triggers correctly on cron schedule
- Full import pipeline smoke test passes end-to-end on staging
- All download worker types produce correct output
- Capistrano deploy restarts both Sidekiq services cleanly
