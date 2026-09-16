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


## 🟡 Puma has no overload protection (rate limiting now done)

**Rate limiting: DONE (Sep 2026).** `rack-attack` in the Gemfile, configured in
`config/initializers/rack_attack.rb`, Redis-backed, covered by
`test/integration/rack_attack_test.rb` (8 tests).

⚠️ **Correction:** the previous version of this entry said the sibling
`protectedplanet-api` repo "has this now (`config/rack_attack.rb`)". It does not —
no such file on any branch, and `rack-attack` is not in its Gemfile. Written from
scratch, not ported.

**The shape matters more than the numbers, because WCMC staff share an office/VPN
egress — a whole team arrives as ONE IP.** Anything counting ordinary work per-IP
punishes exactly the people who should be using the site.

- **`POST /downloads` — 60/min per IP.** Each unique request enqueues a Sidekiq job
  writing a multi-GB artefact, and the Redis lock in `Download::Requesters::Base`
  dedupes only *identical* requests. One person taking CSV + SHP + GDB + PDF is
  already 4, so this is a runaway-script cap, not a per-person quota.
  `GET /downloads/poll` is exempt — the frontend polls it while a download builds.
- **`/admin` — NOT throttled.** Only **failed authentications** are counted:
  `AdminAuthFailureTracker` (middleware, inserted after Rack::Attack so it sees the
  real response) reports 401s, and Fail2Ban bans an address after 20 failures in
  10 minutes for 15 minutes. Successful admin work is unlimited however many
  people are behind the address.
  An earlier draft throttled all of `/admin` at 20/min per IP. That was wrong twice:
  Sidekiq's dashboard polls `/admin/sidekiq/stats` on a timer (`web/views/
  dashboard.erb` sets `updateUrl`), so an idle open dashboard would eat the budget;
  and a team editing CMS pages from one VPN address would lock itself out. That poll
  is also exempt from failure counting, or an expired session on an open dashboard
  could ban the office.
- **No global request cap, deliberately.** The post-deploy hook walks 46 URLs in
  seconds from one IP; a blanket cap low enough to matter would 429 the smoke walk
  and fail every deploy. Tests pin this omission.

### ⚠️ Client IP resolution is only correct while no proxy APPENDS itself

`Rack::Attack::Request` subclasses `::Rack::Request`, which has **no `#remote_ip`** —
using it raises NoMethodError and turns every guarded request into a 500. The
initializer defines it from `env['action_dispatch.remote_ip']`. Plain `#ip` is wrong
too: behind a proxy that is the proxy.

`config.action_dispatch.trusted_proxies` is **unset** (Rails defaults: loopback and
private ranges). Measured on staging:

| `X-Forwarded-For` | `REMOTE_ADDR` | `remote_ip` |
| --- | --- | --- |
| `203.0.113.9` | `172.17.0.5` (kamal-proxy, private) | `203.0.113.9` ✓ |
| `203.0.113.9` | `104.16.1.1` (public, Cloudflare-shaped) | `203.0.113.9` ✓ |
| `203.0.113.9, 104.16.1.1` | `104.16.1.1` | **`104.16.1.1`** ✗ |

Staging is fine (kamal-proxy is on a private address). Cloudflare normally *sets*
`X-Forwarded-For` to the client rather than appending, so production is probably
fine too — but that is **assumed, not measured**, and row 3 is the failure mode:
every visitor collapses onto one counter and the whole internet shares one budget.
**Before production goes behind Cloudflare, either add the Cloudflare ranges to
`trusted_proxies` or read `CF-Connecting-IP`, and verify with a real request.**

### Still open

- **Puma is thin and single-mode, but the risk is smaller than this entry used to
  claim.** `config/puma.rb:7` gives 5 threads; clustered `workers`/`WEB_CONCURRENCY`
  is commented out, and there is no request timeout.

  ⚠️ **Corrections, measured on staging 2026-09-15:**

  - The old text said "concurrent PDF renders can exhaust the thread pool". They
    cannot. The pages the rasterizer fetches (`?for_pdf=true`, see
    `Download::Generators::Pdf#params`) are the **fastest** heavy pages at
    **0.2–0.36s** — they render a stripped layout. The slow part of a PDF is Chrome
    rasterizing inside Sidekiq, which never occupies a Puma thread.
  - `worker_timeout` would be **inert** here anyway. In puma 6.6.1 it is read only
    in `cluster.rb` and `cluster/worker_handle.rb`, never in `single.rb`, so it does
    nothing without clustered mode. It is also a worker *liveness* check, not a
    per-request cap: when it fires it kills the worker and every in-flight request
    on it.

  **Measured cold TTFB** (warm hits are ~0.2s; memcached caches these, so only first
  hits count — `/en/country/USA` went 2.17s → 0.20s between two calls):

  | Page | Cold TTFB |
  | --- | --- |
  | Country pages (USA, SWE, CAN, AUS) | 1.1–2.6s |
  | Regions | 0.4–2.4s |
  | Protected area pages | 0.2–0.5s |
  | Search / search-areas | 0.08–0.83s |
  | `?for_pdf=true` render pages | 0.2–0.36s |

  Slowest legitimate request is **~2.6s** against a proxy ceiling of **120s**
  (`config/deploy.staging.yml:16`) — a 46× gap. Anything holding a thread longer is
  already pathological, so a timeout at 90s would almost never fire; a useful value
  would be nearer **15–30s**.

  **Deferred 2026-09-15**, deliberately. The real exposure is narrow — a pathological
  query or a hung Elasticsearch call, not PDFs. If thread exhaustion is ever observed,
  `rack-timeout` at ~20s is the cheap fix (it works in single mode, unlike
  `worker_timeout`); going clustered is the larger one and needs `preload_app!` plus
  `on_worker_boot` reconnects on a 1.5GB VM. Sample the long tail before picking a
  number: only the ten heaviest pages by PA count were measured.
- **Redis is now on the request path** for `/downloads` and `/admin`. It already was
  via Sidekiq, but a Redis outage now touches those two surfaces directly.

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
- **`.ruby-version` pins 4.0.6, which is not installed on the dev Macs.** Every
  rbenv shim refuses to start, which is what breaks `kamal` (`rbenv: version
  '4.0.6' is not installed`). Workaround is `RBENV_VERSION=3.4.7 kamal ...` —
  kamal itself runs fine on any installed Ruby, since it only drives the remote
  build. **Fix:** `rbenv install 4.0.6`.
  **Do not "fix" this by editing the file down to an installed version.** It must
  match `Dockerfile`, `Dockerfile.deploy`, `config/deploy.yml` (`builder.args`)
  and `.github/workflows/test.yml`, which all build 4.0.6. (This entry previously
  said 3.3.7; it went stale when the app moved to Ruby 4.0.6 in Sep 2026, and the
  old advice — install 3.3.7 — would now put a developer on the wrong Ruby.)
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

- **The portal checkpoint file store is global, and only a *successful* release
  clears it.** ⚠️ **Correction to the earlier entry here, which said nothing reset
  the store at all:** `Checkpoint.reset_all!` *is* called, from
  `app/services/portal_release/service.rb:234` — but it is the last entry in
  `PortalRelease::Service::PHASES`, so it runs only on the full success path. The
  `ensure` block releases the lock and nothing else, `abort_current!` drops
  staging tables and releases the lock, and a dry run or a partial
  `PP_RELEASE_ONLY_PHASES` subset breaks out before reaching it. So a crash, an
  abort or a partial run leaves offsets behind.
  **Scope is narrower than it first looked:** a real release passes
  `release_id: @release.id` (`service.rb:187`), so its offsets live in that
  Release's `stats_json`, scoped to it — resume within a release is safe and
  unaffected. The hazard is the fallback taken when `release_id` is nil: one
  global `tmp/portal_checkpoints.json` shared by every run.
  **Mitigated 2026-09-07:** that fallback now discards whatever it finds and
  starts empty (`Checkpoint#discard_unowned_file_store!`), because a global store
  cannot be shown to belong to the current run. The trade is that a file-store run
  can no longer resume across processes; the alternative was skipping records that
  were never imported, which surfaces as *"Target staging table
  `staging_protected_areas` does not exist or has no records"* and is silent.
  Covered by `test/unit/wdpa/portal/checkpoint_test.rb`.
  **Still open:** `reset_all!` is not on the failure or abort paths, so a failed
  release leaves its own Release-scoped offsets in `stats_json`. That is harmless
  for the *next* release (new row, empty checkpoints) but means a re-run of the
  *same* release resumes from wherever it died — intended, but undocumented and
  untested.
- **`pp:portal:cleanup_backups` has not been run on the real environments.** Old
  `bkYYMMDDHHMM_*` backup tables accumulate after every release swap. The task
  takes a keep-count: `rake pp:portal:cleanup_backups[2]`.