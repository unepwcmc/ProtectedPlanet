# Known Issues

Open items needing a decision, an environment, or a fix. **Delete an entry when
it is closed** — the git history is the record of what was fixed.

Last verified against the code: **2026-10-09**.

## 🟡 Admin credentials are shared and weak

`/admin/sidekiq` sits behind the same HTTP Basic wall as the CMS admin
(`config/initializers/sidekiq.rb`). Two things about those credentials are open:

- **One username/password covers both surfaces.** `COMFY_ADMIN_USERNAME` /
  `COMFY_ADMIN_PASSWORD` gate the CMS *and* the job console, so anyone who can
  edit a page can also retry and delete WDPA imports. No separate credential, no
  per-person identity.
- **The staging password is 8 characters** (measured 2026-09-04, value not read).
  Thin, for a console that can delete an import.

## 🟡 Client IP resolution breaks if a proxy APPENDS itself

`config/initializers/rack_attack.rb` defines `Rack::Attack::Request#remote_ip`
from `env['action_dispatch.remote_ip']` (`Rack::Request` has no `#remote_ip`, and
plain `#ip` is the proxy). `config.action_dispatch.trusted_proxies` is unset, so
Rails trusts loopback and private ranges only. Measured on staging:

| `X-Forwarded-For` | `REMOTE_ADDR` | `remote_ip` |
| --- | --- | --- |
| `203.0.113.9` | `172.17.0.5` (kamal-proxy, private) | `203.0.113.9` ✓ |
| `203.0.113.9` | `104.16.1.1` (public, Cloudflare-shaped) | `203.0.113.9` ✓ |
| `203.0.113.9, 104.16.1.1` | `104.16.1.1` | **`104.16.1.1`** ✗ |

Row 3 is the failure mode: every visitor collapses onto one counter and the whole
internet shares one rate-limit budget. Cloudflare normally *sets* `X-Forwarded-For`
rather than appending, so production is probably fine — but that is **assumed, not
measured**. Before production traffic goes through Cloudflare, add the Cloudflare
ranges to `trusted_proxies` or read `CF-Connecting-IP`, and verify with a real
request.

## 🟡 Puma has no request timeout

`config/puma.rb:7` gives 5 threads; clustered `workers`/`WEB_CONCURRENCY` is
commented out. `worker_timeout` would be inert — puma 6.6.1 reads it only in
clustered mode, and it is a worker liveness check, not a per-request cap.

Cold TTFB measured on staging 2026-09-15 (warm hits are ~0.2s; memcached caches
these, so only first hits count):

| Page | Cold TTFB |
| --- | --- |
| Country pages (USA, SWE, CAN, AUS) | 1.1–2.6s |
| Regions | 0.4–2.4s |
| Protected area pages | 0.2–0.5s |
| Search / search-areas | 0.08–0.83s |
| `?for_pdf=true` render pages | 0.2–0.36s |

The slowest legitimate request is ~2.6s against a 120s proxy ceiling — a 46× gap,
so anything holding a thread longer is already pathological.

**Deferred 2026-09-15.** The real exposure is a pathological query or a hung
Elasticsearch call, not PDFs: the rasterizer's `?for_pdf=true` pages are the
*fastest* heavy pages, and Chrome rasterizes inside Sidekiq, never on a Puma
thread. If thread exhaustion is ever observed, `rack-timeout` at ~20s is the cheap
fix (it works in single mode); going clustered needs `preload_app!` plus
`on_worker_boot` reconnects on a 1.5GB VM. Sample the long tail before picking a
number — only the ten heaviest pages by PA count were measured.

## 🟡 No global request cap, deliberately

Rate limiting is Redis-backed `rack-attack`, covered by
`test/integration/rack_attack_test.rb`. **The shape matters more than the numbers,
because WCMC staff share an office/VPN egress — a whole team arrives as ONE IP.**

- **`POST /downloads` — 60/min per IP.** Each unique request enqueues a Sidekiq job
  writing a multi-GB artefact, and the Redis lock in `Download::Requesters::Base`
  dedupes only *identical* requests. One person taking CSV + SHP + GDB + PDF is
  already 4, so this is a runaway-script cap, not a per-person quota.
  `GET /downloads/poll` is exempt — the frontend polls it while a download builds.
- **`/admin` is not throttled.** Only *failed* authentications count:
  `AdminAuthFailureTracker` (inserted after Rack::Attack, so it sees the real
  response) reports 401s, and `Rack::Attack::Fail2Ban` bans an address after 20
  failures in 10 minutes, for 15 minutes. Sidekiq's dashboard poll is exempt, or an
  expired session on an open dashboard could ban the office.
- **No blanket cap.** The post-deploy hook walks 46 URLs in seconds from one IP; a
  cap low enough to matter would 429 the smoke walk and fail every deploy. Tests
  pin this omission.

Redis is now on the request path for `/downloads` and `/admin`. It already was via
Sidekiq, but an outage now touches those two surfaces directly.

## CI

The suite is green (754 runs, 2036 assertions, 0 failures/errors/skips on Rails
8.1.3.1 / Ruby 4.0.6), including the two portal FDW integration tests, which load
`test/support/portal_fdw/` instead of skipping. Open decisions:

- **No branch protection on any branch.** The old reason — don't gate on a red
  suite — no longer applies. The catch is *where*: all PRs target `master`, but the
  deployed branches (`staging_kamal`, `production_kamal`) are pushed to directly,
  and GitHub rejects a direct push to a protected branch whose commit has no
  passing required check. Protecting a deploy branch means moving it to a PR flow;
  protecting `master` alone gates every PR and changes nobody's push habits. Checks
  to require: `Ruby test suite`, `JavaScript test suite`. **Deferred 2026-09-04**,
  not rejected.
- **Snyk has no successor.** It was a Jenkins plugin step and stopped scanning when
  Jenkins was retired. Porting it means a `snyk/actions` step plus a `SNYK_TOKEN`
  secret.
- **Nothing runs `rubocop` in CI.** The gem is in the `development` group and
  `.rubocop.yml` exists, but no workflow invokes it.

## Local development

- **Ruby 4.0.6 is not installed on the dev Macs.** Every pin in the repo agrees on
  it (`.ruby-version`, `.tool-versions`, both Dockerfiles, `config/deploy.yml`
  `builder.args`, `.github/workflows/test.yml`), so the version manager refuses to
  start any `ruby` on the host -- which is what breaks `kamal`
  (`rbenv: version '4.0.6' is not installed`).

  If your version manager says 4.0.6 does not exist, its ruby-build definitions are
  stale, not the pin -- upstream ships 4.0.0 through 4.0.7. Update the plugin first:

  ```bash
  asdf plugin update ruby && asdf install ruby 4.0.6   # or: rbenv install 4.0.6
  ```

  Workaround until then: `RBENV_VERSION=3.4.7 kamal ...`, since kamal only drives
  the remote build. Everything else runs in Docker anyway.
- **`db/structure.sql` can go internally inconsistent, and re-dumping preserves the
  damage.** A copy was found listing migration `20260130120000`
  (`RenameGreenListColumnsToGlNames`) as applied while still defining the
  pre-rename `green_list_statuses.status`. Any database built from it skips the
  migration forever, then dumps the same contradiction back out. The symptom is 42
  errors of `PG::UndefinedColumn: column green_list_statuses.gl_status does not
  exist`. The file is gitignored, so this is per-machine. **Fix:**
  `rm db/structure.sql && rails db:drop db:create db:migrate` — a clean run reports
  207 migrations, not 2.
- **The `install` compose service can wedge on `puppeteer browsers install
  chrome`.** Observed stalled 2h45m at 176MB of a ~180MB download, with no timeout.
  `web`, `sidekiq` and friends wait on `install: service_completed_successfully`, so
  every `docker compose run` queues behind it and looks hung. Kill the container,
  delete the partial zip under `node_modules/.puppeteer-cache/chrome/`, and pass
  `--no-deps` if you only need the app container.
- **16 view tests fail locally** on the vite manifest while the test-mode vite build
  is still running. Re-run; they pass in CI.

## Release

- **`Checkpoint.reset_all!` is not on the failure or abort paths.** It is the last
  entry in `PortalRelease::Service::PHASES`, so it runs only on the full success
  path — the `ensure` block releases the lock and nothing else. A failed release
  therefore leaves its own Release-scoped offsets in `stats_json`. Harmless for the
  *next* release (new row, empty checkpoints), but it means re-running the *same*
  release resumes from wherever it died. Intended, but undocumented and untested.
- **A file-store release cannot resume across processes.** When `release_id` is nil
  the checkpoint store falls back to one global `tmp/portal_checkpoints.json`, which
  `Checkpoint#discard_unowned_file_store!` now discards on load, because a global
  store cannot be shown to belong to the current run. The alternative was silently
  skipping records that were never imported. Real releases pass `release_id` and are
  unaffected. Covered by `test/unit/wdpa/portal/checkpoint_test.rb`.
- **The "all rows failed" hard error is not applied to the sibling importers**
  (green list, PAME, sources, country statistics), which share the soft-only
  pattern. Green list and PAME have a `skipped_count` for rows that legitimately
  match no PA, so "every row skipped" is not provably a failure there, and adding
  the rule could stop a release that works today.
