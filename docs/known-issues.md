# Known Issues

Open items needing a decision, an environment, or a fix. Remove an entry when it
is closed.

Last verified against the code: **2026-09-03**.

## 🔴 Sidekiq::Web admin panel has no authentication

`config/routes.rb:8` — `mount Sidekiq::Web => '/admin/sidekiq'` has no auth
constraint, no Basic-auth wrapper, nothing. Checked for any surrounding
middleware or route constraint that might cover it (`application_controller.rb`,
`config/`) — there is none in this repo.

**Verified 2026-09-03:** anyone who finds the URL can view, retry, or delete
every background job (WDPA import, PDF rendering, downloads) with no login.
Cloudflare Access or a firewall rule could still be shielding it at the edge,
but that is outside the codebase — confirm directly rather than assuming it.

**Fix** — wrap the mount in the same `COMFY_ADMIN_USERNAME`/`PASSWORD` Basic
auth already used for CMS admin (`config/initializers/comfortable_media_surfer.rb:111-112`),
or a route constraint.

## 🟡 No rate limiting or overload protection at the app tier

No `rack-attack` (or equivalent) in the Gemfile, no throttle config anywhere.
Nothing here caps requests per IP under a flood — the sibling `protectedplanet-api`
repo has this now (`config/rack_attack.rb`), this app does not.

Related gaps found alongside it:

- **`POST /downloads`** (`app/controllers/downloads_controller.rb:11`) only
  dedupes *identical* generation requests via a Redis lock
  (`lib/modules/download/requesters/base.rb`); a client varying search
  filters can still enqueue unlimited unique Sidekiq CSV/Shapefile/GDB jobs
  with no per-IP cap.
- **Puma is thin and single-mode** (`config/puma.rb:7`) — 5 threads,
  clustered `workers`/`WEB_CONCURRENCY` is commented out, no
  `worker_timeout`/`first_data_timeout` set. PDF/country-page requests can
  run up to 120s (Cloudflare's ceiling, `config/deploy.staging.yml:16`) — a
  handful of concurrent PDF renders can exhaust the whole thread pool.
- **No login brute-force protection** — the only login surface (CMS admin)
  is static HTTP Basic auth with no lockout/backoff on failed attempts.

**Fix** — add `rack-attack` with a per-IP throttle, at minimum on
`/downloads` and any admin login surface; consider a Puma request/worker
timeout given the 120s PDF path above.

## CI

- **`release_orchestration_integration_test.rb` may still be flaky** — *"Target
  staging table `staging_protected_areas` does not exist or has no records"*.
  Treat as unconfirmed: it surfaced in a run made after a concurrent suite was
  killed mid-flight, and this test shares staging tables with anything else
  touching the test database. **Re-run it alone** before believing it:
  `bin/rails test test/integration/wdpa/portal/release_orchestration_integration_test.rb`
- **The explanation at the top of `.github/workflows/test.yml` is out of date.**
  It blames `lib/tasks/db.rake` seeding 248 countries and colliding on
  `countries_pkey`. That file was deleted in the cleanup, and the current run
  shows **zero** such failures. It's also now stale on the search bug (see
  Closed below) — needs a fresh full-suite run to write an accurate summary.
- **Not a required check.** Deliberate while the suite's full-run status is
  unconfirmed — add the jobs to branch protection once it is green.
- **Snyk has no successor.** It was a Jenkins plugin step and stopped scanning
  when Jenkins was retired. Porting it means a `snyk/actions` step plus a
  `SNYK_TOKEN` secret. Open decision.
- **Nothing runs `rubocop` in CI.** The gem is in the `development` group and
  `.rubocop.yml` exists, but no workflow invokes it. Open decision.

## Deploy

- **No Kamal production destination.** `config/deploy.yml` and
  `config/deploy.staging.yml` both set `RAILS_ENV: staging`. There is no working
  production deploy path until one is added.

## Release

- **The portal checkpoint file store has no owner, and nothing resets it.** With
  no `Release` to hang off, `Wdpa::Portal::Checkpoint` persists offsets to
  `tmp/portal_checkpoints.json`, which survives across runs. A dry run or a
  crashed release leaves stale offsets behind and **the next real release
  silently imports zero records** — the visible symptom is *"Target staging table
  `staging_protected_areas` does not exist or has no records"*.
  It logs a loud warning when it takes that branch (`checkpoint.rb:23-27`), but
  that is the only guard. ⚠️ **Correction to the audit record:** it claimed
  `Checkpoint.reset_all!` was added to the setup and teardown of both portal
  integration tests. It is not there — `grep -rn "reset_all!" test/` matches only
  an assertion string in `adapters/protected_areas_test.rb`. So *nothing* resets
  the store, tests included. Either restore those resets, make the fallback refuse
  a store that does not belong to the current release, or disable it outside a
  `Release`.
- **`pp:portal:cleanup_backups` has not been run on the real environments.** Old
  `bkYYMMDDHHMM_*` backup tables accumulate after every release swap. The task
  takes a keep-count: `rake pp:portal:cleanup_backups[2]`.