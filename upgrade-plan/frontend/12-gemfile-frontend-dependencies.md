# 12 — Gemfile & asset pipeline (frontend-related gems)

| | |
|---|---|
| **Estimate** | Included in phases 2, 8, 10 (+ CMS spike **1–2 weeks · ~0.25–0.5 month** if Comfy admin breaks) |
| **Depends on** | [01 — Discovery](./01-discovery-and-inventory.md) |
| **Blocks** | Accurate Rails upgrade scoping |

[← Back to overview](./README.md)

This document maps **every Gemfile entry that affects the browser, assets, or CMS admin UI**. The original upgrade plan focused on Webpacker, Vue, and Vite; several gems below were under-documented.

---

## Summary table

| Gem | In original plan? | Role today | Upgrade action |
|-----|-------------------|------------|----------------|
| `webpacker` | Yes | Vue 2 packs via `@rails/webpacker` (package.json) | **Remove** after Vite cutover (dual bundler today — [02a](./02a-vite-spike-rails-5.md)) |
| `vite_rails` | Partial | **2.0.13** on Rails 5.2 spike; Vite 2.9 in npm | **2.x on `main` now** → **3.x on upgrade branch** |
| `loofah` | **No** | Pinned `~> 2.19.1` for nokogiri 1.10 + Rails boot | Keep pin until nokogiri upgraded |
| `vuejs-rails` | Mentioned | Legacy Vue 1.x Sprockets integration (~2.3) | **Remove** — public UI uses Webpacker, not this gem |
| `sprockets-vue` | **No** | Declared; **no app references found** | **Remove** after confirming no Sprockets `.vue` compile path |
| `sass-rails` | Partial (phase 8) | `application.scss` + ~135 SCSS files | **Keep** initially (`sassc-rails` on Rails 7) or migrate imports to Vite |
| `sprockets-rails` | Partial | Serves `application.css`, `pdf.css`, CMS assets | **Keep** through transition; required if Sprockets CSS remains |
| `uglifier` | **No** | Sprockets JS minification (if any manifest JS) | **Drop** when Sprockets JS gone; Vite minifies |
| `coffee-rails` | **No** | CMS admin only: 2 files in `comfy/admin/cms/*.coffee` | **Migrate** → [plain JS task](#migrate-cms-coffeescript--plain-js-coffee-rails); remove gem in phase 2 |
| `autoprefixer-rails` | **No** | PostCSS for Sprockets CSS pipeline | **Replace** with Vite PostCSS / `autoprefixer` npm when CSS moves to Vite |
| `jquery-rails` | **No** | Gem present; **no `app/assets` jquery manifest** found for public site | **Audit** Comfy/vendor JS; likely removable from *public* path |
| `bourbon` | **No** | Path in `config/initializers/assets.rb`; **no `@import bourbon` in SCSS** | **Remove** if confirmed unused |
| `neat` | **No** | Grid companion to Bourbon; no imports found | **Remove** with Bourbon if unused |
| `tinymce-rails` | **No** | Comfy CMS WYSIWYG (`config.tinymce.install = :compile`) | **Upgrade** with Comfy/Rails 7; test `/admin` editor |
| `comfortable_mexican_sofa` | **No** (CMS) | Whole CMS admin + public CMS pages | **Major** — Rails upgrade + admin asset QA (not Vue, but frontend-facing) |
| `phantompdf` | Partial (Puppeteer only) | Gem in Gemfile; **PDF generation uses Node Puppeteer**, not this gem | **Remove** gem after confirming no `Phantompdf` calls |
| `premailer-rails` | N/A (email) | Inline CSS for **emails** | Out of public frontend scope; keep for mailers |
| `ejs` | **No** | Test/dev group — EJS templates for JS tests | Update/remove with test stack (`factory_girl`, capybara 2) |
| `capybara` / `selenium-webdriver` | Partial (phase 9) | System tests (very old capybara ~2.3) | **Upgrade** with Rails 7 (see phase 9) |
| `best_in_place` | **No** | In Gemfile; **no `app/` usage found** | Confirm dead; **remove** if unused |
| `turnout` | N/A | Maintenance page gem | Ops, not UI migration |

**npm (not gems but frontend-critical):** `@rails/webpacker`, `vue`, `puppeteer` — covered in phases 2–4, 7, 10.

---

## Public site asset flow (today)

```
┌─────────────────────────────────────────────────────────────┐
│  Sprockets (sass-rails, sprockets-rails, autoprefixer-rails) │
│    → stylesheet_link_tag 'application'  (SCSS)               │
│    → stylesheet_link_tag 'pdf'          (@for_pdf)           │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  Webpacker (webpacker gem + @rails/webpacker npm)            │
│    → javascript_pack_tag 'application'  → vue.js + .vue    │
│    → stylesheet_pack_tag 'application'                         │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  Vite (vite_rails 2.x + vite 2.9 — spike, May 2026)          │
│    → vite_javascript_tag 'entrypoints/…'  → app/frontend/    │
│    → public/vite-dev/ (development autoBuild)                  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│  CDN (not gems)                                              │
│    → Mapbox GL 1.4.1, Google Fonts, Font Awesome, Hotjar     │
└─────────────────────────────────────────────────────────────┘
```

Vue is **not** driven by `vuejs-rails` or `sprockets-vue` in this repo — only Webpacker.

---

## CMS admin (`/admin`) — separate frontend surface

Comfortable Mexican Sofa brings its own admin UI:

| Piece | Location / config |
|-------|-------------------|
| `comfortable_mexican_sofa` | Routes `comfy_route :cms_admin, path: '/admin'` |
| `tinymce-rails` | `config/application.rb` → `config.tinymce.install = :compile` |
| Custom admin JS | `app/assets/javascripts/comfy/admin/cms/custom.js` |
| CoffeeScript | `editor.js.coffee`, `versions.js.coffee` (see [migration task](#migrate-cms-coffeescript--plain-js-coffee-rails) below) |
| Patches | `config/initializers/comfy_patching.rb` |

**Tasks (coordinate with backend):**

- [ ] Smoke-test CMS after each Rails minor bump: login, edit page, TinyMCE, upload, fixtures import.
- [ ] Confirm Comfy 2.x compatibility with target Rails or plan Comfy upgrade.
- [ ] **[Migrate CMS CoffeeScript → plain JS](#migrate-cms-coffeescript--plain-js-coffee-rails)** — small, do early in phase 2 (unblocks removing `coffee-rails`).
- [ ] Do **not** assume Vite is needed for Comfy admin on day one — Sprockets may carry admin until Comfy is upgraded.

---

## Migrate CMS CoffeeScript → plain JS (`coffee-rails`)

**Why:** `coffee-rails` exists only to compile two Comfy admin scripts. There is no other CoffeeScript in the app. Conversion is mechanical (~30 minutes) and avoids carrying a legacy gem through the Rails 7 upgrade.

**When:** Phase [02 — Rails + Vite](./02-rails-and-vite-integration.md) (during gem audit / first Rails bump), not at public-site Vite cutover.

**Scope:**

| File | Role |
|------|------|
| `app/assets/javascripts/comfy/admin/cms/editor.js.coffee` | Redactor WYSIWYG options for CMS admin |
| `app/assets/javascripts/comfy/admin/cms/versions.js.coffee` | Toggle version-selection UI on CMS pages |
| `app/assets/javascripts/comfy/admin/cms/custom.js` | Sprockets manifest — `//= require` paths stay the same after rename to `.js` |
| `test/javascripts/spec_helper.js.coffee` | Konacha/Mocha helper — **delete** (Konacha gem commented out; unused) |

**Checklist:**

- [ ] Convert `editor.js.coffee` → `editor.js` (plain `function` callbacks; template literals for `CMS.*` URLs).
- [ ] Convert `versions.js.coffee` → `versions.js`.
- [ ] Remove the `.coffee` files after the `.js` files work.
- [ ] Delete `test/javascripts/spec_helper.js.coffee` (or convert only if Konacha is revived).
- [ ] Confirm `custom.js` still precompiles: `//= require 'comfy/admin/cms/versions'` and `//= require 'comfy/admin/cms/editor'` (no extension change needed).
- [ ] Remove `gem 'coffee-rails'` from `Gemfile`; `bundle install`; commit `Gemfile.lock`.
- [ ] Smoke-test `/admin`: login, edit a page with rich text (Redactor), toggle versions on/off if that UI is in use.

**Notes:**

- Comfy loads `custom.js` by convention — no layout change required.
- Optional hardening while converting `editor.js`: initialize `params = ''` before the CSRF `if`, so Redactor URLs are defined when meta tags are missing (same latent bug as today).
- Do **not** move Comfy admin onto Vite for this task; Sprockets continues to serve admin assets.

---

## PDF generation — gem vs npm

| Mechanism | Status |
|-----------|--------|
| `phantompdf` gem | In Gemfile; **no Ruby usage found** in app/lib |
| `phantomjs` shell | Commented in `country_controller.rb` / `protected_areas_controller.rb` |
| **Puppeteer** (`package.json`) | **Active** — `lib/modules/download/generators/pdf.rb` runs `vendor/.../rasterize.js` |

→ Phase [10](./10-deploy-and-devops.md) should say: upgrade **npm Puppeteer**, audit **remove `phantompdf` gem**.

---

## Target Gemfile direction (public UI)

**Today (Rails 5.2 spike):** see [02a](./02a-vite-spike-rails-5.md).

After cutover on **Rails 7+** ([vite_rails](https://vite-ruby.netlify.app/) + [14](./14-architecture-and-design.md)):

```ruby
# Replace 2.x pin with
gem 'vite_rails', '~> 3.0'
gem 'sassc-rails'   # if Sprockets SCSS retained

# Remove (when done)
gem 'webpacker'
gem 'vuejs-rails'
gem 'sprockets-vue'
gem 'uglifier'          # if no Sprockets JS
gem 'coffee-rails'      # after CMS coffee migrated
gem 'phantompdf'        # after confirmed unused
gem 'bourbon'           # if audit confirms unused
gem 'neat'
```

`jquery-rails` — remove only after Comfy/admin and any vendor `//= require jquery` audit.

---

## Discovery checklist (phase 1 add-ons)

- [ ] `bundle show vuejs-rails sprockets-vue` — confirm nothing requires them at boot.
- [ ] Grep `Phantompdf`, `phantompdf`, `best_in_place`, `bourbon`, `neat` across repo.
- [ ] List all `javascript_include_tag` / `stylesheet_link_tag` in layouts (public + `comfy`).
- [ ] Open `/admin` → Network tab: which assets load (Sprockets vs pack vs CDN).
- [ ] Document Comfy version constraint vs Rails 7 in ComfortableMexicanSofa changelog.

---

## Exit criteria

- Every frontend-related gem has **keep / upgrade / remove** decision recorded.
- CMS admin works on staging after Rails + asset changes.
- No duplicate PDF stacks (phantompdf gem removed if dead).
