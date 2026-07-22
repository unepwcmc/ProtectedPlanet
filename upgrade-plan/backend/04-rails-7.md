# 04 — Rails 6.1 → 7.0 → 7.1 (B0)

| | |
|---|---|
| **Estimate** | 3–5 weeks · ~0.75–1.25 months |
| **Depends on** | [03 — Rails 6.1 green](./03-rails-6.md) · **[02 — Ruby ≥ 3.2 done first](./02-ruby-upgrade.md)** |
| **Blocks** | **B0 — frontend phase 2b** (vite_rails 3.x, Vite 5, Vue 3) |

[← Back to overview](./README.md)

---

## Goal

Rails 7.1 boots locally and in CI. This is **milestone B0** — the most time-critical deliverable for the whole upgrade project. The frontend team cannot move to vite_rails 3.x or Vue 3 until this lands.

**Announce B0 completion to frontend colleague immediately on landing.**

---

## Step A — Rails 6.1 → 7.0

### Key changes in Rails 7.0

**Encryption (new, opt-in):**

- `ActiveRecord::Encryption` introduced. No action required unless adopting it, but review if there are any existing custom encryption patterns in models.

**Query interface changes:**

- `ActiveRecord::Base.where` is stricter with type coercion. Test all search queries.
- `in_order_of` — new, no action.
- Arel private API usage will raise warnings — grep `Arel::Nodes` usage in `lib/modules/search/`.

**`respond_to` / strong params:**

- Largely compatible from 6.1. Watch for `ActionController::Parameters` behaviour differences.

**`config.load_defaults 7.0` — notable changes:**

- `config.action_dispatch.cookies_same_site_protection` — enabled by default
- `config.active_support.cache_format_version = 7.0` — cache invalidation; flush Redis/memcached
- `config.action_controller.raise_on_open_redirects = true` — check any `redirect_to params[:return_to]` patterns in controllers

**Asset pipeline:**

- Propshaft is mentioned as an option but Sprockets still works — **keep Sprockets** for now
- `importmap-rails` is the new default for JS but we're using Vite — ignore it

**CMS swap — Comfy → Media Surfer (B3 gate):**

`comfortable_mexican_sofa 2.0.19` does not run on Rails 7. The Rails 7.0 bump is where we **swap it for `comfortable_media_surfer ~> 3.1`** — the gem requires Rails ≥ 7.0 and Ruby ≥ 3.2, so this is the earliest possible step and it should be a single cutover, not a two-stage move.

Full port scope and checklist: **[09](./09-cms-comfy.md)**. It is a phase in its own right (2–3 wk) and runs alongside this one, not inside it.

- [ ] Ruby ≥ 3.2 already landed ([02](./02-ruby-upgrade.md)) — hard prerequisite
- [ ] Swap the gem and run the engine's pending migrations (**DB snapshot first**)
- [ ] Port `comfy_patching.rb`, the custom CMS tag and the category models — see [09](./09-cms-comfy.md)
- [ ] Remove `tinymce-rails` — Media Surfer uses Redactor
- [ ] Do not merge Rails 7.0 until the B3 checklist in [09](./09-cms-comfy.md) passes

**Nokogiri / Loofah unpin:**

- Rails 7 drops the Nokogiri 1.10 constraint. Upgrade `nokogiri` to `~> 1.16` here.
- Remove the `loofah` pin — `loofah 2.21+` works with Nokogiri 1.13+.

### Tasks — Rails 7.0

- [ ] Update `gem 'rails', '7.0.x'`; `bundle update rails`
- [ ] Run `rails app:update`; review all diffs
- [ ] Apply `config.load_defaults 7.0` — test each change incrementally if needed
- [ ] Grep `redirect_to params[` — add `allow_other_host: false` or explicit allowlist
- [ ] Flush staging cache after deploy (cache format version changed)
- [ ] Upgrade `nokogiri` to `~> 1.16`; remove `loofah` pin
- [ ] Upgrade `activerecord-postgis-adapter` to **8.x** (Rails 7.0 row — 9.x at 7.1, 11.x at Rails 8) — see [06](./06-postgis-and-database.md)
- [ ] **`PostgisDatabaseTasks` is gone from 8.x** — add explicit `CREATE EXTENSION postgis` to CI and the Docker entrypoint
- [ ] Replace `ActiveRecord::Base.connection_config` (removed in 7.0) — used in `lib/modules/ogr/postgres.rb`, see [13](./13-gdal-and-spatial-tooling.md)
- [ ] Grep Arel private API usage in `lib/modules/search/` — update to public API
- [ ] Swap to `comfortable_media_surfer` and pass the B3 checklist — see [09](./09-cms-comfy.md)
- [ ] Run full test suite; confirm green

---

## Step B — Rails 7.0 → 7.1 **(B0)**

Rails 7.1 is a smaller bump from 7.0. Primary new features are opt-in (async queries, composite primary keys, `generates_token_for`). The main concern is deprecations.

### Key changes in Rails 7.1

**`config.load_defaults 7.1` changes:**

- `config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction` — changed default; could affect any AR callback chains during imports
- `config.active_support.message_serializer = :json_allow_marshal` — serialiser change; affects signed cookies / sessions
- `ActiveRecord::Base.automatically_invert_plural_associations` — new; unlikely to affect this app but run test suite

**`ActiveRecord::Migration.check_pending!` strictness:**

- Pending migrations raise on boot in production — ensure no pending migrations exist on the upgrade branch

**Logging improvements:**

- Query logging changed format — no action needed

**`secret_key_base` from credentials:**

- Rails 7.1 deprecates `secrets.yml` in favour of `credentials.yml.enc`. Check `config/secrets.yml` — migrate if needed before hitting hard deprecation in 8.0.

### Tasks — Rails 7.1 **(B0)**

- [ ] Update `gem 'rails', '7.1.x'`; `bundle update rails`
- [ ] Run `rails app:update`; review diffs
- [ ] Apply `config.load_defaults 7.1`
- [ ] Migrate `config/secrets.yml` → `config/credentials.yml.enc` if not already done — note `config/storage.yml` reads `Rails.application.secrets.*` for the S3 credentials and must be updated with it
- [ ] Bump `activerecord-postgis-adapter` 8.x → **9.x** (the Rails 7.1 row) — see [06](./06-postgis-and-database.md)
- [ ] Check AR callback order in import workers — `run_commit_callbacks_on_first_saved_instances_in_transaction` change
- [ ] Run `rails db:migrate:status` — ensure no pending migrations
- [ ] Run full test suite
- [ ] Boot locally — confirm clean boot with no deprecation warnings
- [ ] CI green
- [ ] **Tag B0 on upgrade branch**
- [ ] **Notify frontend colleague — B0 is done**

### What B0 unlocks for frontend

Once B0 lands, the frontend team can:

- Bump `vite_rails` to 3.x on the upgrade branch (needs Ruby 2.7+ and Rails 7.1+)
- Target Vite 5 and Vue 3 builds
- Start Vue 3 island mounts (frontend phase 2b)

---

## Shared work at B0

| Item | Backend | Frontend |
|------|---------|----------|
| `vite_rails` 3.x bump | Review + bundle | Write PR |
| `config/vite.rb` | Set prod env vars | Write stub |
| `bin/vite dev` + HMR | Ensure server boots | Wire Docker vite service |

See [frontend/00](../frontend/00-scope-and-backend-dependencies.md) for the full frontend view.

---

## Exit criteria

- Rails 7.1 boots locally with `bin/rails server`
- CI passes on Rails 7.1
- `comfortable_media_surfer` in place; `/admin` works (B3 checkpoint — see [09](./09-cms-comfy.md))
- `activerecord-postgis-adapter` on 9.x
- `secrets.yml` migrated to credentials
- No pending migrations
- Frontend colleague notified of B0
