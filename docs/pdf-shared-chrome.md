# Shared Chrome for PDF rendering — verifying a deploy

The `pdf` Sidekiq capsule renders in one long-lived headless Chrome instead of
launching a browser per job. Ruby owns its lifetime: `lib/modules/shared_chrome.rb`,
started and stopped from Sidekiq's `:startup` / `:shutdown` hooks in
`config/initializers/sidekiq.rb`, launching `docker/scripts/pdf-chrome`.

Chrome here is **always best-effort**. `app/frontend/backend-scripts/rasterize.js`
launches a private browser whenever it cannot reach the shared one — slower and
~440MB heavier per concurrent job, but correct. Nothing in `SharedChrome` may
raise into Sidekiq's boot or shutdown.

`bin/pdf-chrome-permission-check` proves only the *permissions* the supervisor
depends on (spawn, process group, IPv4 bind, TERM→KILL, reap). The behavioural
features — capsule gating, wedge detection, restart, give-up, port-already-taken,
graceful shutdown, fallback — have to be provoked deliberately. This is the full
post-deploy checklist for staging.

## 0. Get a shell in the right container

Everything below runs **as the app user, from the app root, inside `job_default`**
— never `job_import` (no `pdf` capsule) and never `web` (Puma never starts a
browser).

```bash
bin/kamal app exec -d staging --roles=job_default --reuse -i "bash"
# then, inside:
cd /app && ./bin/pdf-chrome-permission-check
```

`--reuse` matters: it runs in the *live* container, with `init: true`, the real
env and the real user — not a fresh one. The script uses spare port 9010 (never
9222) and kills the browser it starts, so it is safe next to a running Sidekiq.

Expect `checks 1-4 PASSED`, plus in sections 5–6: own process group, answers on
IPv4, group-kill + reap, SIGSTOP accepted, SIGKILL to the group permitted,
reaped. Any FAIL there means the supervisor's corresponding step will fail
silently in production too.

## 1. Startup and capsule gating

```bash
bin/kamal app logs -d staging --roles=job_default --grep "pdf-chrome" -n 100
```

Want `[pdf-chrome] ready on 127.0.0.1:9222 (pid N)` within ~45s of boot
(`PDF_CHROME_READY_SECONDS`).

These two must produce **no** `[pdf-chrome] ready` line at all:

```bash
bin/kamal app logs -d staging --roles=job_import --grep "pdf-chrome"
bin/kamal app logs -d staging --roles=web        --grep "pdf-chrome"
```

And exactly one browser should exist in `job_default`:

```bash
bin/kamal app exec -d staging --roles=job_default --reuse \
  "bash -lc 'pgrep -af remote-debugging-port'"
```

## 2. `reachable?` and real sharing

```bash
bin/kamal app exec -d staging --roles=job_default --reuse \
  "bash -lc 'curl -sS http://127.0.0.1:9222/json/version'"
```

It must answer over **IPv4** specifically. With the port taken, Chrome binds
`[::1]` instead and looks perfectly healthy while `rasterize.js` can never reach
it — that is the trap `wait_until_reachable` exists for.

Then trigger a real PDF download on staging (a country or region PDF) and check
the log does **not** contain `No shared browser at ...; launching a private one.`
Memory while it renders should grow by ~90MB, not ~440MB.

## 3. Crash → restart

```bash
bin/kamal app exec -d staging --roles=job_default --reuse \
  "bash -lc 'pkill -f remote-debugging-port=9222'"
```

Within one check interval (30s, `PDF_CHROME_CHECK_SECONDS`) the log should show
`Chrome is gone; restarting it (PDFs use private browsers meanwhile)` followed by
a new `ready ...` line with a different pid.

## 4. Zombie reaping (the `init: true` fix)

Immediately after step 3:

```bash
bin/kamal app exec -d staging --roles=job_default --reuse \
  "bash -lc 'ps -eo stat,ppid,cmd | grep -c \"[d]efunct\"'"
```

Must stay at 0, or be transient. ~11 permanent `<defunct>` entries per Chrome
restart means tini is not at PID 1 — check `init: true` survived the deploy on
the `job_default` role. Sidekiq as PID 1 never reaps processes it did not spawn.

## 5. Wedge detection (`WEDGED_AFTER_FAILED_PROBES`)

Nothing else exercises this path. A Chrome can be alive and useless — hung,
deadlocked, or wedged after an OOM — which `exited?` cannot see. SIGSTOP the
browser leader so it is alive but unanswering, then wait ~90s (3 × the check
interval):

```bash
bin/kamal app exec -d staging --roles=job_default --reuse \
  "bash -lc 'kill -STOP $(pgrep -f remote-debugging-port=9222 | head -1)'"
```

Expect `Chrome (pid N) is running but has not answered on 127.0.0.1:9222 for 3
checks; replacing it`, then a fresh `ready`. Do this with no PDF job in flight —
it deliberately kills the browser, and Sidekiq retries are not reliable for
these jobs.

## 6. Port already taken — both branches

**a) A real DevTools endpoint is already there.** `start!` should leave it alone
rather than fight it. Start one by hand, then restart the role:

```bash
bin/kamal app exec -d staging --roles=job_default --reuse -i \
  "bash -lc './docker/scripts/pdf-chrome &'"
bin/kamal app boot -d staging --roles=job_default
```

Log: `a browser is already listening on 127.0.0.1:9222; leaving it alone`.

**b) A non-DevTools squatter.** Occupy the port with a dumb TCP listener
(`nc -l 9222`) before boot. Expect three rounds of `Chrome is running but never
answered on 127.0.0.1:9222 after 45s -- is the port already taken?` and then
`giving up after 3 failed starts; every PDF will launch its own browser from
here on` (`GIVE_UP_AFTER_FAILED_STARTS`).

**Verify PDFs still succeed in this state.** That is the whole best-effort
contract, and it is the only part of this checklist that is a release blocker.

## 7. Graceful shutdown

```bash
bin/kamal app stop -d staging --roles=job_default   # or a normal deploy
```

Log: `stopping shared Chrome (pid N)`. After the container is gone, no orphaned
Chrome should be left on the host:

```bash
ssh <staging-host> 'pgrep -af remote-debugging-port'
```

`Chrome (pid N) ignored TERM; killing` is fine — it means the escalation path
(section 6 of the permission check) fired for real. `stop!` signals the process
*group*, so renderers and the crashpad handler go with it instead of being
re-parented and stranded.

## 8. Kill switch and fallback

Set `PDF_SHARED_CHROME=0` in the `job_default` env and redeploy. Expect
`[pdf-chrome] disabled by PDF_SHARED_CHROME`, no browser process, and a PDF
download that still completes — `rasterize.js` logs `launching a private one`.
Then revert.

This is the production escape hatch, so confirm it works *before* you need it.

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `PDF_SHARED_CHROME` | on | `0`/`false`/`no` disables the shared browser entirely |
| `PDF_BROWSER_PORT` | 9222 | Moves both ends (`SharedChrome` and `rasterize.js`) off 9222 together |
| `PDF_CHROME_READY_SECONDS` | 45 | Grace for a freshly spawned Chrome to answer before it counts as a failed start |
| `PDF_CHROME_CHECK_SECONDS` | 30 | Supervisor poll interval, and the retry delay after a failed start |
| `PDF_CHROME_LOG` | unset | Unset sends Chrome's output to the Sidekiq log (and so `kamal app logs`); a path splits it into a file, which docker-compose does to keep dev logs readable |

A value that is not a positive integer falls back to the default rather than
raising — these constants are evaluated at boot in **every** role, including
Puma, which never touches Chrome.
