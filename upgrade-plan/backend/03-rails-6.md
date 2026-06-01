# 03 — Rails 5.2 → 6.0 → 6.1

| | |
|---|---|
| **Estimate** | 3–5 weeks · ~0.75–1.25 months |
| **Depends on** | [01 — Gem audit](./01-gem-audit.md) · [02 — Ruby 2.7](./02-ruby-upgrade.md) |
| **Blocks** | [04 — Rails 7](./04-rails-7.md) (B0) |

[← Back to overview](./README.md)

---

## Goal

Get from Rails 5.2 to Rails 6.1 with a clean test suite, without breaking the import pipeline or search. This is the longest and most mechanical step — two minor bumps that must run sequentially.

---

## Step A — Rails 5.2 → 6.0

### What changes in Rails 6.0 that will affect this app

**Zeitwerk autoloader (biggest risk):**

Rails 6 switches from `classic` to `Zeitwerk` autoloading by default. `config/application.rb` customises `autoload_paths`:

```ruby
config.autoload_paths += %W(
  #{config.root}/lib/modules
  #{config.root}/lib/cms_tags
  #{config.root}/app/presenters
  #{config.root}/app/serializers
)
```

- Zeitwerk expects each file to define exactly one constant matching the filename/path.
- `lib/modules/` contains nested directories (`download/`, `search/`, `import_tools/`, `wdpa/`, `stats/`, `ogr/`, `geospatial/`). Each must follow the `module Foo; class Bar` naming convention.
- `lib/cms_tags/` — same requirement.
- The safest first step: boot with `config.load_defaults 5.2` retained and add `config.autoloader = :classic` to buy time, then fix naming violations before enabling Zeitwerk.

**Action Mailbox / Action Text introduced:**

- Not used by this app — no action needed, but migrations may be generated; skip them.

**Parallel tests:**

- Rails 6 enables parallel tests by default. `DatabaseCleaner` strategy may conflict. Keep `config.parallel_tests = false` until [10](./10-test-suite.md) is addressed.

**`ActionDispatch::Response#content_type` header format changed:**

- Returns `"text/html; charset=UTF-8"` instead of `"text/html"` — may break test assertions.

**Other AR changes:**

- `ActiveRecord::Base.default_scope` behaviour stricter.
- `belongs_to` required by default (already the Rails 5.2 default — no change).
- `update_attributes` removed (use `update`) — grep the codebase.

### Tasks — Rails 6.0

- [ ] Update `gem 'rails', '6.0.x'` in Gemfile; `bundle update rails`
- [ ] Run `rails app:update` — review all diffs in `config/` carefully (don't blindly accept)
- [ ] Set `config.load_defaults 5.2` + `config.autoloader = :classic` temporarily to boot first
- [ ] Grep `update_attributes` across `app/` and `lib/` — replace with `update`
- [ ] Grep `ActionDispatch` in test files for content-type assertions
- [ ] Boot app — address all deprecation warnings before moving to Zeitwerk
- [ ] Enable Zeitwerk: change to `config.autoloader = :zeitwerk` — fix naming violations:
  - [ ] Audit `lib/modules/` — ensure every file's constant matches its path
  - [ ] Audit `lib/cms_tags/` — same
  - [ ] Run `bin/rails zeitwerk:check` to surface all violations
- [ ] Update `sass-rails` to `~> 6.0` (5.x incompatible with Rails 6)
- [ ] Update Sprockets to 4.x if prompted — test asset compilation
- [ ] Update `activerecord-postgis-adapter` to 7.x — see [06](./06-postgis-and-database.md)
- [ ] Update `capybara` and `selenium-webdriver` — see [10](./10-test-suite.md)
- [ ] Run full test suite — aim for green before 6.1 bump

### Files most likely to need changes

- `app/controllers/application_controller.rb` — strong params, response helpers
- `lib/modules/import_tools/` — any `update_attributes` calls in importers
- `app/models/` — any use of removed AR methods

---

## Step B — Rails 6.0 → 6.1

Rails 6.1 is a smaller bump. Key changes:

**`where` with association:**

- `where(association: nil)` behaviour changed — explicit `LEFT JOIN` now required in some cases. Grep for `where(X: nil)` patterns on associated models.

**`active_record.legacy_connection_handling`:**

- Set `config.active_record.legacy_connection_handling = false` in `config/application.rb` to opt in to the new connection handling. Required for Rails 7.

**Delegated types:**

- New feature — no action needed unless you want to adopt it.

**`destroy_all` / `delete_all` return value:**

- Now returns count instead of records — check any code that uses the return value.

**Error handling changes:**

- `ActiveRecord::Base.raise_on_missing_translations` — review locale files.

### Tasks — Rails 6.1

- [ ] Update `gem 'rails', '6.1.x'`; `bundle update rails`
- [ ] Run `rails app:update`; review `config/` diffs
- [ ] Set `config.active_record.legacy_connection_handling = false`
- [ ] Grep `destroy_all.map` / `delete_all` return value usage
- [ ] Grep `where(X: nil)` patterns — test spatial / association queries
- [ ] Run full test suite; confirm green before Rails 7 bump

---

## Sidekiq 5 → 6 (do during this phase)

Sidekiq 6 is compatible with Rails 6 and Ruby 2.7. Upgrade here to keep the dependency graph clean rather than carrying Sidekiq 5 into Rails 7.

- [ ] Update `gem 'sidekiq', '~> 6.5'`
- [ ] Sidekiq 6 drops Ruby 2.3/2.4 support — already on 2.7 by this phase
- [ ] Config file format unchanged between 5 and 6
- [ ] Web UI middleware registration changed — update `config/initializers/sidekiq.rb` if using the web UI
- [ ] Full Sidekiq 6→7 work is in [08](./08-sidekiq-and-workers.md)

---

## Exit criteria

- App boots on Rails 6.1 with Zeitwerk autoloader enabled
- `bin/rails zeitwerk:check` passes
- Full test suite green (or known failures documented with tickets)
- Import pipeline and download workers smoke-tested
- Staging deploy on Rails 6.1 confirmed
- `config.active_record.legacy_connection_handling = false` set (required for Rails 7)
