# 02 — Ruby upgrade (2.6.3 → 2.7 → 3.3)

| | |
|---|---|
| **Estimate** | 1–2 wk (2.6 → 2.7) + 1–2 wk (2.7 → 3.x) = **2–4 wk total** |
| **Depends on** | [01 — Gem audit](./01-gem-audit.md) (native extensions audited) |
| **Blocks** | `vite_rails` 3.x needs Ruby 2.7+; Rails 8 requires Ruby 3.1+ |

[← Back to overview](./README.md)

---

## Goal

Move Ruby from 2.6.3 (EOL March 2022) to 3.3.x. Done in two stages: **2.7 first** (unblocks B0 / vite_rails 3.x), then **3.x after B0** (doesn't need to block frontend).

---

## Stage 1 — Ruby 2.6.3 → 2.7 (do before B0)

### Why 2.7 first

- `vite_rails` 3.x uses `filter_map` — requires Ruby 2.7+
- Rails 7.0+ recommends Ruby 2.7; Rails 8 **requires** Ruby 3.1
- Ruby 2.7 surfaces keyword argument deprecation warnings without breaking — gives time to fix them before the hard break in 3.0

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
- `gdal` — confirm native ext compiles on 2.7; test a spatial query
- `levenshtein` — confirm compiles
- `nokogiri` — usually fine; already pinned to 1.10.4 but should verify

---

## Stage 2 — Ruby 2.7 → 3.x (after B0)

This stage does **not** block the frontend. Schedule it after Rails 7.1 boots (B0).

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
2.6.3  →  2.7.8  →  3.1.6  →  3.3.x
          (B0)       (Rails 8   (target)
                     requires 3.1)
```

Going 2.7 → 3.1 directly is safe if all keyword arg issues are resolved. 3.2 is an optional intermediate.

---

## Deployment (Capistrano)

`config/deploy.rb` sets `rvm_ruby_version`. This must be updated in step:

```ruby
# config/deploy.rb — update for each Ruby bump
set :rvm_ruby_version, '3.3.x'
```

Also update the Ansible role that sets the system Ruby if applicable — check `config/deploy/ansible/`.

---

## Exit criteria

- Stage 1: App boots and tests pass on Ruby 2.7.8; staging deploy confirmed; B0 unblocked
- Stage 2: App boots and tests pass on Ruby 3.3; no `ArgumentError` from keyword arg separation; native extensions compile; staging + production deploy confirmed
