# 10 — Test suite modernisation

| | |
|---|---|
| **Estimate** | **Unknown depth — 2–4+ weeks.** Excavation, not a fixed task list (see baseline below) |
| **Depends on** | **Nothing** — runs on Rails 5.2 *now*, before any Rails bump |
| **Blocks** | **Everything.** No Rails bump can be verified until the suite loads and passes on 5.2 |
| **Priority** | **FIRST phase.** Re-sequenced from last → first after the Jul 2026 baseline |

[← Back to overview](./README.md)

---

## ⚠️ Baseline finding — the suite is 100% dead on Rails 5.2 (Jul 2026)

Ran the real suite locally against the current branch (`upgrade-plan`, Ruby 2.7.8, in the Docker stack — pg/postgis, redis, elasticsearch, `RAILS_ENV=test`). Result:

```
NameError: uninitialized constant MiniTest
  mocha-1.0.0/lib/mocha/integration/mini_test/adapter.rb:27
  test/test_helper.rb:14   ← require 'mocha/mini_test'
```

**Zero tests run.** The suite aborts at *load time*, before the first test. This confirms `docs/workflow.md`'s note that tests "have not been working for some time" (since 2021), and pins it to an exact cause.

| Fact | Value |
|---|---|
| Tests executed | **0** (crash at load) |
| `minitest` installed | 5.25.4 — modern, constant is `Minitest` |
| `mocha` installed | **1.0.0** (2014) — references the removed `MiniTest` constant |
| `webmock` installed | 1.22 (2015) — same-era, will crash next at `test_helper.rb:15` |
| Test files using mocha | **61 of 121** — cannot be removed, must be upgraded |

### Why this changes the whole plan

The plan's entire safety model is "run suite, confirm green" at each Rails bump. **That net does not exist** — the suite does not load on 5.2, the known-good baseline. Therefore:

- **This phase moves from last to first.** It has no Rails dependency; it must be done on 5.2 before anything moves.
- **The Jenkins CI fix must not merge to a built branch until the suite loads** — `backend/ci-test-baseline` flips the Test stage from `echo "rakeTest()"` to a real run, which would turn every build red at load. Land it *with or after* this phase, not before.
- Estimate is genuinely uncertain: each gem bump surfaces the next wall (mocha → webmock → factory_bot → real test failures). Could be a week to load-green; the *pass*-green depth is unknown until we excavate.

### "Make it load" ladder (do in this order, on Rails 5.2)

1. **`mocha` 1.0.0 → `~> 1.16`** (last 1.x — keeps the `.stubs`/`.expects` API the 61 files use; avoids mocha 2.x's stricter breaking changes). Change `test_helper.rb:14`: `require 'mocha/mini_test'` → `require 'mocha/minitest'`.
2. **`webmock` 1.22 → `~> 3.x`** — next crash at `test_helper.rb:15` (`require 'webmock/minitest'`). Same MiniTest-constant era.
3. **`factory_girl_rails` → `factory_bot_rails`** — likely the next load wall (`FactoryGirl` constant).
4. Re-run → first real pass/fail count. *Then* the numbers below become meaningful.

**Milestone L0 — "suite loads and reports pass/fail on Rails 5.2."** This is the true first deliverable of the whole backend upgrade.

---

## Goal

Bring the test suite from Rails 5.2-era gems to versions compatible with Rails 7/8 and Ruby 3.x, **starting from a suite that does not currently run at all.** First get it loading and green on **5.2** (milestone L0), then keep it green through each Rails bump. Not coverage expansion — that's separate.

---

## Current test stack

| Gem | Current | Issue |
|-----|---------|-------|
| `factory_girl_rails` | ~> 4.4.1 | Renamed to `factory_bot_rails` in 2017 — no longer maintained |
| `capybara` | ~> 2.3.0 | Rails 6+ requires capybara 3.x; Ruby 3 requires 3.36+ |
| `webmock` | ~> 1.22.0 | 1.x is incompatible with Ruby 3 |
| `timecop` | ~> 0.7.1 | Minor API changes in 0.9; fine to upgrade |
| `mocha` | ~> 1.0.0 | 1.x drops Ruby 3 support; upgrade to 2.x |
| `selenium-webdriver` | current | Must stay in sync with capybara version |
| `minitest` | ~> 5.10 | Upgrade to ~> 5.25 (Ruby 3 compat improvements) |
| `database_cleaner` | current | Verify strategy works with Zeitwerk and Rails 6+ |
| `ejs` | current | Remove — only needed for Konacha (commented out since Rails 5) |
| `byebug` | ~> 9.0 | Upgrade to ~> 11 for Ruby 3 |

---

## factory_girl → factory_bot (mechanical rename)

`factory_girl_rails` was renamed `factory_bot_rails` in 2017. The API is identical — this is a find-and-replace across the codebase.

### Steps

- [ ] Replace `gem 'factory_girl_rails'` with `gem 'factory_bot_rails', '~> 6.0'` in Gemfile
- [ ] Run: `grep -r "FactoryGirl" test/ spec/ --include="*.rb" -l` — list all affected files
- [ ] Replace `FactoryGirl` → `FactoryBot` across all test files (sed or IDE refactor)
- [ ] Replace `FactoryGirl.define` → `FactoryBot.define` in factory definitions
- [ ] Remove `require 'factory_girl_rails'` → `require 'factory_bot_rails'`
- [ ] Run test suite — confirm no `uninitialized constant FactoryGirl` errors

### Factory files location

Check:
- `test/factories/` or `spec/factories/` — standard Rails location
- May be in `test/` directly — grep for `FactoryGirl.define`

---

## capybara upgrade (2.3 → 3.x)

Capybara 3 has API changes but is largely backwards-compatible for basic usage. The upgrade may surface test brittleness that was hidden in 2.x.

### Capybara 3 breaking changes to watch for

- `find` raises if more than one element matches (was silent in 2.x) — tests using `find('.some-class')` may now fail if multiple elements exist; use `first` or more specific selectors
- `have_text` / `have_content` — whitespace handling stricter
- `wait` parameter removed from some matchers — use Capybara's built-in retry instead of explicit sleep
- `page.driver.browser` access pattern changed for JavaScript driver
- `Capybara::Selenium::Driver` setup changed — update any custom driver registration in `test_helper.rb`

### Steps

- [ ] Update `gem 'capybara', '~> 3.40'`
- [ ] Update `gem 'selenium-webdriver'` to match capybara's requirement
- [ ] Run system/integration tests — fix `Ambiguous match` errors from `find`
- [ ] Fix any `have_text` whitespace failures
- [ ] Remove any explicit `sleep` calls that were compensating for 2.x timing issues — capybara 3 handles retries better

---

## webmock upgrade (1.x → 3.x)

`webmock` 1.x does not support Ruby 3. Upgrade to 3.x.

- [ ] Update `gem 'webmock', '~> 3.23'`
- [ ] Check for any `WebMock::NetConnectNotAllowedError` test setup — API unchanged for basic stubs
- [ ] Run tests that use HTTP stubs (any test hitting the ES client, S3, HTTParty calls)

---

## Other gem updates

- [ ] `gem 'timecop', '~> 0.9'` — Timecop::TimeStackItem API slightly changed; check `Timecop.freeze` usage
- [ ] `gem 'mocha'` — **first bump to `~> 1.16` (make-it-load, keeps 1.x API)**, then to `~> 2.x` at the Ruby 3 step. Update the require path to `mocha/minitest` at the 1.16 bump
- [ ] `gem 'minitest', '~> 5.25'` — upgrade within minitest 5.x
- [ ] `gem 'byebug', '~> 11'` — Ruby 3 compat
- [ ] `gem 'database_cleaner'` — confirm strategy (`truncation` vs `transaction`) still works with Zeitwerk and parallel tests disabled
- [ ] Remove `gem 'ejs'` — Konacha has been commented out since Rails 5 migration

---

## CI setup

**CI is Jenkins** (`Jenkinsfile`, multibranch, `pollSCM` every 5 min, builds via `docker-compose`, Snyk scan, Slack to `#jenkins-cicd-pp`). Correction to the earlier "no CI found" note.

**The Test stage never actually ran** — [`Jenkinsfile`](../../Jenkinsfile) had `echo "rakeTest()"` instead of `rakeTest()`, so the suite was skipped in every build. That is *why* nobody noticed it broke in 2021. Fix staged on `backend/ci-test-baseline`.

- [ ] Land the `rakeTest()` fix **with or after** the make-it-load ladder — not before, or every build goes red at load
- [ ] Once the suite loads green on 5.2, decide whether to backport the Jenkinsfile fix to `develop`/`master` (until then it would block production hotfixes)
- [ ] Keep the existing docker-compose-based Jenkins flow; a GitHub Actions matrix is optional, not required (CI already exists)

---

## Exit criteria

- **L0: suite loads and reports pass/fail on Rails 5.2** (mocha/webmock/factory_bot make-it-load ladder done)
- Suite **green on Rails 5.2** before the first Rails bump
- `factory_girl_rails` replaced with `factory_bot_rails`; all `FactoryGirl` references renamed
- `capybara` on 3.x; `Ambiguous match` errors resolved
- `webmock` on 3.x; all HTTP stub tests pass
- Jenkins Test stage actually runs the suite (`rakeTest()` fix landed)
- Full test suite green on Ruby 2.7, then Ruby 3.3
- `ejs` gem removed from Gemfile
