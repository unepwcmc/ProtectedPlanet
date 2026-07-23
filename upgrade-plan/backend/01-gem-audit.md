# 01 — Gem audit & inventory

| | |
|---|---|
| **Estimate** | 1–2 weeks · ~0.25–0.5 month |
| **Depends on** | Nothing |
| **Blocks** | All phases — must confirm Comfy compat before committing to Rails 7 path |

[← Back to overview](./README.md)

---

## Goal

Every Gemfile entry has a **keep / upgrade / remove** decision recorded before any Rails bump begins. ComfortableMexicanSofa compat is the single most important output of this phase.

---

## Full Gemfile inventory

### Core framework

| Gem | Current | Rails 6 | Rails 7.1 | Rails 8 | Action |
|-----|---------|---------|-----------|---------|--------|
| `rails` | 5.2.0 | 6.1.x | 7.1.x | 8.0.x | **Upgrade** — step by step, one minor at a time |
| `pg` | ~> 0.21 | needs 1.x | needs 1.x | needs 1.x | **Upgrade to `~> 1.5`** — `pg` 0.21 does not support Ruby 3 |
| `activerecord-postgis-adapter` | 5.1.0 | 7.x | 8.x → 9.x | **11.x** | **Upgrade at each AR step** — majors track AR exactly (8→7.0, 9→7.1, 10→7.2, 11→8.0/8.1). `PostgisDatabaseTasks` removed from 8.x. See [06](./06-postgis-and-database.md) |
| `puma` | (config present) | ✓ | ✓ | ✓ | **Becomes the app server** (replaces Passenger) — see [11](./11-deploy-and-devops.md). Ensure version current, tune workers/threads |

### Frontend / asset pipeline (backend-touching gems)

| Gem | Current | Action | When | Notes |
|-----|---------|--------|------|-------|
| `webpacker` | ~> 4.0.2 | **Remove** | B5 (shared with frontend) | Remove gem + deploy hook together |
| `vite_rails` | ~> 2.0.13 | ✓ **Done — 3.11.1** on `feat/upgrade-frontend` | Delivered | Works on **Rails 5.2** (`railties >= 5.1, < 9`); needed only Ruby 2.7. Backend inherits it |
| `sass-rails` | ~> 5.0.7 | **Upgrade to `sassc-rails`** or keep for transition | Rails 6 | `sass-rails` 5 breaks on Rails 6 |
| `sprockets-rails` | ~> 3.2.1 | **Keep** through transition; Sprockets 4 on Rails 6 | Rails 6 | Required until Vite serves all CSS |
| `uglifier` | ~> 4.1.17 | **Remove** when Sprockets JS gone | B5 | Vite minifies; no Sprockets JS needed |
| `coffee-rails` | ~> 4.2.2 | **Remove** after Comfy CoffeeScript migrated to JS | Phase 2a | Frontend owns migration — [frontend/12](../frontend/12-gemfile-frontend-dependencies.md) |
| `autoprefixer-rails` | current | **Remove** when CSS moves to Vite PostCSS | B5 | Replace with npm `autoprefixer` in vite config |
| `jquery-rails` | ~> 4.3.3 | **Audit then remove** | Phase 1 | Likely only needed for Comfy admin; confirm no public `//= require jquery` |
| `bourbon` | current | **Remove** — no `@import bourbon` found in SCSS | Phase 1 | Confirm with grep before removing |
| `neat` | current | **Remove** with Bourbon | Phase 1 | Grid companion; no imports found |
| `vuejs-rails` | ~> 2.3.2 | **Remove** — public UI uses Webpacker, not this gem | Phase 1 | Confirm: `bundle show vuejs-rails` at boot |
| `sprockets-vue` | ~> 0.1.0 | **Remove** — no app references found | Phase 1 | Confirm no `.vue` Sprockets compile path |

### CMS

| Gem | Current | Action | Risk |
|-----|---------|--------|------|
| `comfortable_mexican_sofa` | ~> 2.0.0 | **Replace** with `comfortable_media_surfer ~> 3.1` at the Rails 7.0 step — upstream dead since Dec 2019 | Medium — same schema, but our monkey-patching must be ported. See [09](./09-cms-comfy.md) |
| `tinymce-rails` | ~> 4.3.2 | **Remove** — Media Surfer uses Redactor, not TinyMCE. Also drop `config.tinymce.install` (`config/application.rb:40`) | Low |
| `best_in_place` | ~> 3.0.1 | **Remove** if confirmed unused (no `app/` usage found) | Low |

### Background jobs & queues

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `sidekiq` | ~> 5.2.5 | **Upgrade to 7.x** | See [08](./08-sidekiq-and-workers.md) — two steps: 5→6, then 6→7 |
| `sinatra` | >= 1.3.0 | **Upgrade to 3.x** | Required by Sidekiq web UI — Sinatra 1.x incompatible with Ruby 3 |
| `whenever` | current | **Keep** — check for Ruby 3 compat | Cron schedule for `S3PollingWorker` |
| `capistrano-sidekiq` | 1.0.2 | **Upgrade** in step with Sidekiq | See [11](./11-deploy-and-devops.md) |

### Search

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `elasticsearch` | ~> 7.2.0 | **Bump to `~> 7.17`** | Server is 7.17.24 — no infra change needed. See [07](./07-elasticsearch.md) |

### Storage / networking

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `aws-sdk` | 3.0.1 | **Upgrade to current 3.x patch** | 3.0.1 is very old; breaking changes within 3.x are minimal but security patches are missing |
| `net-sftp` | current | **Keep** — verify Ruby 3 compat | Used in import pipeline |
| `net-scp` | current | **Keep** — verify Ruby 3 compat | Used in import pipeline |
| `httparty` | ~> 0.15.1 | **Upgrade to ~> 0.21** | 0.15 has known incompatibilities; comment in Gemfile warns of breaking changes |
| `httmultiparty` | ~> 0.3.14 | **Audit** — depends on httparty; may be removable | Check if still called in codebase |

### XML / HTML parsing

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `nokogiri` | ~> 1.10.4 | **Upgrade to ~> 1.16** | Pin exists only because of loofah cascade — unpin at Rails 7 step |
| `loofah` | ~> 2.19.1 | **Unpin** when nokogiri upgraded | Constraint is `2.21+ needs Nokogiri::HTML4 (not in nokogiri 1.10)` |

### Monitoring / error tracking

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `appsignal` | ~> 3.3.11 | **Upgrade to 4.x** | AppSignal 4 adds Rails 8 support; 3.x EOL — confirm before B4 |
| `exception_notification` | ~> 4.3.0 | **Keep or remove** | Check if AppSignal has replaced all alerting |
| `slack-notifier` | ~> 1.5.1 | **Keep** — verify compat | Used in exception notifications |

### Auth / security

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `bcrypt_pbkdf` | >= 1.0, < 2.0 | **Keep** — SSH key gem for Capistrano | Verify net-ssh compat |
| `ed25519` | >= 1.2, < 2.0 | **Keep** — SSH key gem for Capistrano | |
| `dotenv` | ~> 0.11.1 | **Upgrade to ~> 2.8** | 0.11 is ancient; breaking changes in `dotenv` 1.x and 2.x | 
| `dotenv-deployment` | current | **Audit** — may be absorbed into `dotenv` 2.x | |

### Deploy

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
**All Capistrano gems are being removed** — deployment moves to Docker + Kamal 2, see [11](./11-deploy-and-devops.md). Keep them working until a Kamal production deploy is proven; remove as the last step, not the first.

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `capistrano` | 3.11.0 | **Remove** at Kamal cutover | Bump to `~> 3.18` only if it must survive on Ruby 3 in the interim |
| `capistrano-rails` | 1.4.0 | **Remove** | |
| `capistrano-bundler` | 1.6.0 | **Remove** | |
| `capistrano-rvm` | 0.1.2 | **Remove** | Ruby version is baked into the image |
| `capistrano-passenger` | 0.2.0 | **Remove** | Passenger → Puma behind kamal-proxy |
| `capistrano-maintenance` | 1.2.1 | **Remove** | Replaced by kamal-proxy maintenance mode |
| `capistrano-service` | current | **Remove** | `pp_default` / `pp_import` become Kamal worker roles |
| `capistrano-git-with-submodules` | 2.0.3 | **Remove** | Confirm whether the DB submodule is still needed under Docker |
| `whenever` | current | **Remove** | Kamal has no cron primitive — move `S3PollingWorker` to `sidekiq-cron` or a supercronic role, see [11](./11-deploy-and-devops.md) |
| `turnout` | ~> 2.5.0 | **Audit** | Maintenance mode — check whether kamal-proxy covers this before removing |

### Spatial / native

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `gdal` | ~> 2.0 | **Remove** | Abandoned gdal-ruby SWIG bindings; used only in `Ogr::Info` / `Ogr::Split`. Replaced by `ogrinfo` shell-outs — see [13](./13-gdal-and-spatial-tooling.md) |

### Test / development

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `factory_girl_rails` | ~> 4.4.1 | **Replace with `factory_bot_rails`** | Renamed in 2017; mechanical sweep — see [10](./10-test-suite.md) |
| `capybara` | ~> 2.3.0 | **Upgrade to ~> 3.40** | API changes in `find`, `have_text` — see [10](./10-test-suite.md) |
| `webmock` | ~> 1.22.0 | **Upgrade to ~> 3.x** | 1.x incompatible with Ruby 3 |
| `timecop` | ~> 0.7.1 | **Upgrade to ~> 0.9** | Minor API changes |
| `selenium-webdriver` | current | **Upgrade** with capybara | Match capybara version requirements |
| `database_cleaner` | current | **Keep** — verify Rails 6 compat | Strategy may need adjustment with Zeitwerk |
| `mocha` | ~> 1.0.0 | **Upgrade to ~> 2.x** | 1.x drops Ruby 3 support |
| `minitest` | ~> 5.10 | **Upgrade to ~> 5.25** | Keep within minitest 5.x; avoid 5.10.2 (pinned out) |
| `ejs` | current | **Remove** — Konacha commented out, JS tests not in use | |
| `byebug` | ~> 9.0 | **Upgrade to ~> 11** | Ruby 3 compat |
| `web-console` | >= 3.3.0 | **Upgrade to ~> 4.x** | 3.x requires Rails < 7 |

### PDF generation

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `phantompdf` | ~> 1.2.2 | **Remove** | No Ruby usage found; active PDF path is npm Puppeteer — see [frontend/12](../frontend/12-gemfile-frontend-dependencies.md) |

### Other

| Gem | Current | Action | Notes |
|-----|---------|--------|-------|
| `will_paginate` | ~> 3.0 | **Keep** — confirm Rails 7 compat (3.3+ supports it) | |
| `bystander` | 2.0.0 git | **Audit** — private gem from unepwcmc org | Confirm still maintained; check Ruby 3 compat |
| `levenshtein` | ~> 0.2.2 | **Audit** — native C extension | May need update for Ruby 3 |
| `dbf` | ~> 2.0.7 | **Upgrade to ~> 4.x** | Used in import; pure Ruby, no native ext risk |
| `system` | current | **Audit** — unclear purpose | Identify what this gem provides |
| `premailer-rails` | current | **Keep** — email inline CSS | Out of migration scope |

---

## Discovery checklist

- [ ] `bundle show vuejs-rails sprockets-vue best_in_place bourbon neat` — confirm nothing required at boot.
- [ ] Grep `Phantompdf`, `best_in_place`, `bourbon`, `neat`, `httmultiparty` across `app/` and `lib/` — confirm dead.
- [ ] Grep `BestInPlace`, `Phantompdf` in views and controllers.
- [ ] `grep -r "require.*system" config/ app/ lib/` — identify what the `system` gem provides.
- [ ] Check `bystander` gem for last commit / Ruby 3 issues on GitHub.
- [ ] Verify GDAL system library version on production (`gdalinfo --version`) — baseline for the [13](./13-gdal-and-spatial-tooling.md) comparison.
- [ ] Confirm `dotenv-deployment` is still needed or absorbed by `dotenv` 2.x.
- [ ] Confirm nothing outside Comfy admin uses `tinymce-rails` or `jquery-rails` before removing them.

---

## Exit criteria

- Every gem has **keep / upgrade / remove** decision in writing.
- CMS replacement path confirmed: `comfortable_media_surfer` — drives [09](./09-cms-comfy.md) scope.
- Dead gems (`bourbon`, `neat`, `phantompdf`, `vuejs-rails`, `sprockets-vue`, `best_in_place`) confirmed dead and removal tickets created.
- `pg` 1.x upgrade confirmed safe (no `PGconn`/`PGresult` raw API usage in app).
