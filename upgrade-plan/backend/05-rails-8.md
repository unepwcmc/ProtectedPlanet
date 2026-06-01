# 05 — Rails 7.1 → 8.0 (B4)

| | |
|---|---|
| **Estimate** | 2–3 weeks · ~0.5–0.75 month |
| **Depends on** | [04 — Rails 7.1 (B0)](./04-rails-7.md) · [02 — Ruby 3.1+](./02-ruby-upgrade.md) (Rails 8 requires Ruby 3.1) |
| **Blocks** | B4 — platform target reached |

[← Back to overview](./README.md)

---

## Goal

Rails 8.0 is the stated platform target. This phase lands **milestone B4**. The frontend architecture does not change between Rails 7.1 and 8.0, but several backend concerns need attention.

---

## Pre-requisite: Ruby 3.1+

Rails 8 requires Ruby 3.1 minimum. Complete [02 — Ruby upgrade stage 2](./02-ruby-upgrade.md) before this phase. Ruby 3.3 is recommended.

---

## What changes in Rails 8.0

### Propshaft replaces Sprockets as the default asset pipeline

- Sprockets **still works** with Rails 8 — it is no longer the default but is fully supported if you opt in.
- Decision: **keep Sprockets** through this phase unless the team explicitly decides to migrate.
  - The app uses Sprockets for `application.scss`, `pdf.css`, and Comfy admin assets.
  - Propshaft migration is a separate, optional initiative — do not bundle it into this phase.
- Add `gem 'sprockets-rails'` explicitly if Rails 8 drops it from the default gemset.

### Authentication generator (new, opt-in)

- Rails 8 ships `rails generate authentication` — not relevant to this app (Comfy handles admin auth, public site has no user accounts to migrate).

### Solid Queue, Solid Cache, Solid Cable (new defaults)

- These replace Redis-backed solutions as the default for new apps.
- **Do not migrate Sidekiq to Solid Queue** in this phase — Sidekiq 7 is a better fit for this workload given the import pipeline complexity. See [08](./08-sidekiq-and-workers.md).
- `dalli` (Memcached) is used for caching in production/staging — keep it; no need to adopt Solid Cache.

### `config.load_defaults 8.0` changes

Notable defaults that could affect this app:

- `config.active_record.query_log_tags_enabled = true` — opt-in; no breaking change
- `config.active_support.to_time_preserves_timezone = :zone` — check any explicit timezone manipulation in stats/import code
- `config.action_dispatch.default_headers` — CSP and security header changes; confirm these don't break the Vue app or Mapbox CDN calls
- `ActiveRecord::Migration.check_pending!` — same as 7.1; ensure no pending migrations

### `secrets.yml` fully removed

- Must be migrated to `credentials.yml.enc` before this step — should already be done in [04](./04-rails-7.md).

### Deprecations from 7.x that become hard errors in 8.0

- `render :action` with a string — use `render action: :name`
- `config.cache_store` Dalli config — syntax may need updating
- `respond_to` block format — largely unchanged but scan controllers
- Any remaining `secrets.yml` usage → hard error

---

## Tasks

- [ ] Update `gem 'rails', '8.0.x'`; `bundle update rails`
- [ ] Confirm Ruby version is 3.1+ (required) — see [02](./02-ruby-upgrade.md)
- [ ] Run `rails app:update`; review all config diffs carefully
- [ ] Add `gem 'sprockets-rails'` explicitly to Gemfile if dropped from Rails 8 dependencies
- [ ] Apply `config.load_defaults 8.0` — test incrementally
- [ ] Audit `config.action_dispatch.default_headers` — confirm CSP headers don't break Mapbox, Vue CDN assets, Google Fonts
- [ ] Check `config/initializers/` for any use of deprecated APIs:
  - [ ] `Rails.application.secrets` → `Rails.application.credentials`
  - [ ] `config.cache_store :dalli_store` syntax — update to Rails 8 format if changed
- [ ] Check AppSignal gem — upgrade to 4.x (3.x EOL on Rails 8) — see [01](./01-gem-audit.md)
- [ ] Run full test suite on Rails 8.0
- [ ] Smoke-test import pipeline end-to-end
- [ ] Smoke-test Comfy `/admin` (B3 re-check at B4)
- [ ] Deploy to staging
- [ ] **Tag B4 on upgrade branch**
- [ ] Coordinate with frontend — confirm platform target locked at Rails 8

---

## Propshaft (optional future work)

If the team later decides to migrate from Sprockets to Propshaft:

- Propshaft has no manifest preprocessor (no `//= require` directives) — Comfy admin assets would need to be moved to explicit imports
- Public SCSS would stay in Vite by that point (frontend phase 8 complete) — only Comfy admin assets would remain in the asset pipeline
- This is a post-B4 initiative; scope separately

---

## Exit criteria

- Rails 8.0 boots locally with `bin/rails server`
- Ruby 3.1+ in use
- Sprockets retained explicitly (or Propshaft migration decision documented)
- No `secrets.yml` — all secrets in credentials
- Full test suite green
- Staging deploy confirmed
- B4 milestone tagged; frontend colleague notified
