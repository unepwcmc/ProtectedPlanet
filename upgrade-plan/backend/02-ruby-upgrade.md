# 02 — Ruby upgrade (2.6.3 → 2.7 → 3.3)

| | |
|---|---|
| **Estimate** | 1–2 wk (2.6 → 2.7) + 1–2 wk (2.7 → 3.x) = **2–4 wk total** |
| **Depends on** | [01 — Gem audit](./01-gem-audit.md) (native extensions audited) |
| **Blocks** | `vite_rails` 3.x needs Ruby 2.7+ · **[09 — Media Surfer needs Ruby ≥ 3.2](./09-cms-comfy.md)** · Rails 8 requires Ruby 3.1+ |

[← Back to overview](./README.md)

---

## Goal

Move Ruby from 2.6.3 (EOL March 2022) to 3.3.x. Done in two stages: **2.7 first** (unblocks vite_rails 3.x), then **3.2+ before the Rails 7.0 bump**.

> **Sequencing change.** Stage 2 was previously scheduled *after* B0. It now runs **before Rails 7.0**, because `comfortable_media_surfer` requires **Ruby ≥ 3.2 and Rails ≥ 7.0** and we want to adopt it in the same step as the Rails 7.0 bump — see [09](./09-cms-comfy.md). Doing Ruby 3.2 first means the CMS swap is a single cutover rather than two.

---

## Stage 1 — Ruby 2.6.3 → 2.7 ✓ **already done**

**Delivered on `feat/upgrade-frontend`:** `.ruby-version` is **2.7.8**, the Dockerfile base is `ruby:2.7-buster`, Node is 24.4.1, and the bundle resolves. Backend **inherits** this rather than repeating it.

Remaining backend work for this stage is verification, not migration:

- [ ] Full backend test suite green on 2.7.8 (frontend validated the boot, not the import/spatial paths)
- [ ] Import pipeline and download generators exercised on 2.7 — the keyword-arg sweep below still applies to `lib/modules/`
- [ ] Confirm native extensions compile on 2.7 in the image: `pg`, `gdal`, `levenshtein`, `bystander`

The rationale below is kept for the record.

### Why 2.7 first

- `vite_rails` 3.x uses `filter_map` — requires Ruby 2.7+
- Rails 7.0+ recommends Ruby 2.7; Rails 8 **requires** Ruby 3.1
- Ruby 2.7 surfaces keyword argument deprecation warnings without breaking — gives time to fix them before the hard break in 3.0
- `comfortable_mexican_sofa 2.0.19` still has to run on this Ruby through the Rails 6.0/6.1 hops, so don't jump straight to 3.x

### Tasks

- [ ] Update `.ruby-version` to `2.7.x` (use latest 2.7 patch — `2.7.8`)
- [ ] Update `set :rvm_ruby_version, '2.7.8'` in `config/deploy.rb`
- [ ] Run `bundle install` — fix any gems with Ruby 2.7 hard constraints
- [ ] Boot the app locally — address all `warning: Using the last argument as keyword parameters is deprecated` warnings
- [ ] Run test suite — fix failures before proceeding
- [ ] Key files to sweep for keyword arg warnings:
  - `app/controllers/` (any method calls with trailing hash args)
  - `app/services/` and `lib/modules/` (service objects often trigger this)
  - `lib/modules/import_tools/` (importer pipeline)
  - `lib/modules/download/` (download/PDF generators)
- [ ] Update CI Ruby version matrix to 2.7
- [ ] Deploy to staging with Ruby 2.7 — smoke test before proceeding to Rails bumps

### Native extensions to verify at 2.7

- `pg` — upgrade to `~> 1.5` here (0.21 does not compile on Ruby 3)
- `gdal` — confirm native ext compiles on 2.7; test a spatial query. **Being removed entirely in [13](./13-gdal-and-spatial-tooling.md)** — if that phase runs early, this risk disappears rather than being carried to 3.3
- `levenshtein` — confirm compiles
- `nokogiri` — usually fine; already pinned to 1.10.4 but should verify

---

## Stage 2 — Ruby 2.7 → 3.2+ (before Rails 7.0)

Run this **after the Rails 6.1 bump and before Rails 7.0**, so the CMS swap to Media Surfer can happen in the Rails 7.0 step ([09](./09-cms-comfy.md)).

Minimum useful target is **3.2** (Media Surfer floor, and the `activerecord-postgis-adapter` 11.x floor). Go to **3.3** directly unless something forces otherwise.

### Breaking changes in Ruby 3.0

**Keyword argument separation (hard break from 2.7 deprecation):**

```ruby
# Was valid in 2.x (last hash auto-converted to kwargs):
def foo(a:, b:); end
foo({a: 1, b: 2})   # raises ArgumentError in Ruby 3

# Fix: explicit double-splat or update call sites
foo(**{a: 1, b: 2})
```

- Run `ruby-next` or grep for patterns surfaced by 2.7 warnings — all must be fixed before 3.0
- `app/lib/modules/` service objects are the most likely source

**Other 3.0 breaks:**

- `Hash#each_with_object` / pattern matching — unlikely to affect this codebase but scan
- `Proc#{<<, >>}` composition — unlikely
- `$PROGRAM_NAME` / `$0` — unlikely
- Frozen string literals — Rails handles this; custom `String` mutation in lib needs a check

**Ruby 3.1 (required for Rails 8):**

- `Hash#except` available natively (no longer need `ActiveSupport` for it)
- `Data` class introduced — no action needed
- One-line pattern matching stable — no action needed

**Ruby 3.2 / 3.3:**

- `Refinements` scope changes — check if any refinements used in `lib/`
- Performance improvements — no action needed
- `IRB` improvements — no action needed

### Tasks

- [ ] Fix all remaining keyword argument issues surfaced in 2.7
- [ ] Update `.ruby-version` to `3.3.x`
- [ ] Update Capistrano `rvm_ruby_version` to `3.3.x`
- [ ] `bundle install` — fix gems incompatible with Ruby 3 (expect `webmock 1.x`, `mocha 1.x`, `factory_girl_rails` to fail — these should already be updated in [10](./10-test-suite.md))
- [ ] Run full test suite on Ruby 3.3
- [ ] Check `sinatra` version — Sinatra 1.x / 2.x does not support Ruby 3 (Sidekiq web UI depends on it) — upgrade to Sinatra 3.x
- [ ] Verify `gdal`, `levenshtein`, `bystander` native extensions compile on 3.3
- [ ] Deploy to staging and run import pipeline smoke test

### Recommended Ruby version path

```
2.6.3  →  2.7.8  →  3.3.x
          │          │
   before Rails 6   before Rails 7.0
                    (Media Surfer floor is 3.2)
```

Going 2.7 → 3.3 directly is safe if all keyword arg issues are resolved. 3.1/3.2 are optional intermediates.

---

## Deployment

While Capistrano is still live, `config/deploy.rb` sets `rvm_ruby_version` and must be updated in step:

```ruby
set :rvm_ruby_version, '3.3.x'
```

Once [11 — Docker + Kamal 2](./11-deploy-and-devops.md) lands, the Ruby version is **baked into the image** and rvm on the servers goes away entirely. That is the point of that phase — no more rvm/nvm drift.

---

## Exit criteria

- Stage 1: App boots and tests pass on Ruby 2.7.8; staging deploy confirmed
- Stage 2: App boots and tests pass on Ruby 3.3 **before the Rails 7.0 bump**; no `ArgumentError` from keyword arg separation; native extensions compile; staging deploy confirmed
