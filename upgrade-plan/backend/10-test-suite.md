# 10 — Test suite modernisation

| | |
|---|---|
| **Estimate** | 1–2 weeks · ~0.25–0.5 month |
| **Depends on** | [03 — Rails 6.1](./03-rails-6.md) (capybara 3 needs Rails 5.1+) |
| **Blocks** | Nothing — can run alongside any phase |

[← Back to overview](./README.md)

---

## Goal

Bring the test suite from Rails 5.2-era gems to versions compatible with Rails 7/8 and Ruby 3.x. The goal is a clean, green test suite at each Rails bump checkpoint — not test coverage expansion (that's a separate initiative).

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
- [ ] `gem 'mocha', '~> 2.0'` — confirms Ruby 3 support; API largely unchanged
- [ ] `gem 'minitest', '~> 5.25'` — upgrade within minitest 5.x
- [ ] `gem 'byebug', '~> 11'` — Ruby 3 compat
- [ ] `gem 'database_cleaner'` — confirm strategy (`truncation` vs `transaction`) still works with Zeitwerk and parallel tests disabled
- [ ] Remove `gem 'ejs'` — Konacha has been commented out since Rails 5 migration

---

## CI setup

The current CI setup is not documented in the repo (no `.github/workflows/` or `.travis.yml` found). As part of the test suite work:

- [ ] Determine current CI provider and whether it's still active
- [ ] If no CI: set up GitHub Actions with a basic Rails test matrix
  - Ruby version matrix: 2.7, 3.3
  - Services: PostgreSQL + PostGIS, Redis, Elasticsearch (7.17)
- [ ] Block merges to upgrade branch if tests fail

---

## Exit criteria

- `factory_girl_rails` replaced with `factory_bot_rails`; all `FactoryGirl` references renamed
- `capybara` on 3.x; `Ambiguous match` errors resolved
- `webmock` on 3.x; all HTTP stub tests pass
- Full test suite green on Ruby 2.7 (before B0) and Ruby 3.3 (after B0)
- `ejs` gem removed from Gemfile
