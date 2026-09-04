# Known Issues

Open items needing a decision, an environment, or a fix. Remove an entry when it
is closed.

Last verified against the code: **2026-09-04**.

## 🟡 The admin credentials are shared and weak

`/admin/sidekiq` now sits behind the same HTTP Basic wall as the CMS admin
(`config/initializers/sidekiq.rb`, added 2026-09-04 — it served 200 to anyone
before that). Two things about those credentials are still open:

- **One username/password covers both surfaces.** `COMFY_ADMIN_USERNAME` /
  `COMFY_ADMIN_PASSWORD` gate the CMS *and* the job console, so anyone who can
  edit a page can also retry and delete WDPA imports. There is no separate
  credential and no per-person identity.
- **The staging password is 8 characters** (measured on the running container
  2026-09-04, value not read). For a console that can delete an import, that is
  thin, and there is no lockout on repeated attempts (see rate limiting below).


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

- **The suite is green.** Full run 2026-09-04 on Rails 8.1.3.1 with
  `load_defaults 8.1`: **738 runs, 1972 assertions, 0 failures, 0 errors,
  2 skips**, matched by three consecutive green `Tests` runs in Actions.
- **The 2 skips are the portal FDW integration tests**, and they are skipped
  structurally, not flakily — `release_workflow_integration_test.rb:28` and
  `release_orchestration_integration_test.rb:12` both call `skip` when the portal
  FDW schema is absent from the test database, which it always is locally and in
  CI. ⚠️ **This supersedes the earlier "may still be flaky" entry for
  `release_orchestration_integration_test`:** the test is not flaky, it never
  runs. Its question is still unanswered, and the release path — the highest-stakes
  code in the app — has no executing integration coverage. Getting the FDW schema
  into the test database is what would change that.
- **The explanation at the top of `.github/workflows/test.yml` is out of date**
  and now actively misleading. It says the repo has no test CI, that the jobs
  "will report red until the suite is fixed", and blames `lib/tasks/db.rake`
  seeding 248 countries into `countries_pkey` collisions. That rake file is
  deleted, the search bug it also cites is fixed, and the suite is green. Rewrite
  it against the run above.
- **No branch protection at all, on any branch.** `GET /repos/.../branches/
  staging_kamal/protection` returns `404 Branch not protected`. The old reason
  for holding off — don't gate on a red suite — no longer applies now the suite
  is green, so this is a live decision rather than a deliberate wait. The catch
  is *where*: all PRs (including the open dependabot ones) target `master`, but
  the branch actually deployed is `staging_kamal`, and it is pushed to directly.
  GitHub rejects a direct push to a protected branch when the commit has no
  passing required check yet, so protecting `staging_kamal` means moving it to a
  PR-based flow. Protecting `master` alone gates every PR and changes nobody's
  push habits. Check names to require: `Ruby test suite`, `JavaScript test suite`.
  **Deferred 2026-09-04**, not rejected.
- **Snyk has no successor.** It was a Jenkins plugin step and stopped scanning
  when Jenkins was retired. Porting it means a `snyk/actions` step plus a
  `SNYK_TOKEN` secret. Open decision.
- **Nothing runs `rubocop` in CI.** The gem is in the `development` group and
  `.rubocop.yml` exists, but no workflow invokes it. Open decision.

## Local development

Three traps that cost time on 2026-09-04 and will catch the next person.

- **`db/structure.sql` can go internally inconsistent, and re-dumping preserves
  the damage.** A copy was found listing migration `20260130120000`
  (`RenameGreenListColumnsToGlNames`) in its `schema_migrations` insert while
  still defining the pre-rename `green_list_statuses.status`. Any database built
  from it marks the rename applied without ever running it, then `db:migrate`
  dumps the same contradiction back out. The symptom is 42 errors of
  `PG::UndefinedColumn: column green_list_statuses.gl_status does not exist`.
  The file is gitignored and untracked, so this is per-machine. **Fix:**
  `rm db/structure.sql && rails db:drop db:create db:migrate` — a clean run
  reports 207 migrations, not 2.
- **`.ruby-version` pins 3.3.7, which is not installed on the dev Macs.** Every
  rbenv shim refuses to start, which is what breaks `kamal` (`rbenv: version
  '3.3.7' is not installed`). Workaround is `RBENV_VERSION=3.4.7 kamal ...`;
  the fix is `rbenv install 3.3.7` or correcting the file.
- **The `install` compose service can wedge indefinitely on
  `puppeteer browsers install chrome`.** Observed stalled 2h45m at 176MB of a
  ~180MB download with no progress and no timeout. Because `web`, `sidekiq` and
  friends all wait on `install: service_completed_successfully`, every
  `docker compose run` queues behind it and looks hung. Kill the container,
  delete the partial zip under `node_modules/.puppeteer-cache/chrome/`, and pass
  `--no-deps` if you only need the app container.

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