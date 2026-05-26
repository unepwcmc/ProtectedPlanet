# 08 — Styles and assets (incl. Sass)

| | |
|---|---|
| **Estimate** | 3–5 weeks · ~0.75–1.25 months |
| **Depends on** | [02](./02-vite-on-rails-8.md), [03](./03-end-runtime-compilation.md) (late) |
| **Blocks** | Webpacker removal |

[← Summary](./README.md)

---

## Goal

One clear asset pipeline for production. Webpacker removed. Styles load correctly in development and after deploy.

---

## Sass scan (May 2026)

### What you have today

| Item | Detail |
|------|--------|
| **Public site CSS** | **~135 SCSS files**, ~8.8k lines under `app/assets/stylesheets/` |
| **Entry** | `application.scss` → Sprockets `stylesheet_link_tag 'application'` |
| **PDF** | `pdf.scss` → `stylesheet_link_tag 'pdf'` (`@for_pdf`) |
| **CMS admin** | `app/assets/stylesheets/comfy/admin/cms/custom.scss` (Sprockets) |
| **Compiler** | `sass-rails` 5.0.8 → **sassc** (libsass) + old `sass` 3.7.4 gem — **not** Dart Sass |
| **Webpacker CSS** | `stylesheet_pack_tag 'application'` in layout but pack is **JS only** (`application.js` → `vue.js`) — **no pack SCSS**; safe to drop tag with Webpacker |
| **Vue SFC styles** | Almost all styling in global SCSS; Vue files rarely use `<style lang="scss">` |
| **Bourbon / Neat** | In Gemfile + `assets.paths`, **no `@import` in SCSS** — remove after audit ([12](./12-gemfile-frontend-dependencies.md)) |
| **Autoprefixer** | `autoprefixer-rails` on Sprockets pipeline |

### Import style (migration-relevant)

```scss
// application.scss — glob imports via Sprockets/sass-rails
@import './utilities/*';
@import './helpers/mixins/*';
@import './base/*';
@import './components/*';
@import './pages/*';
```

- Widespread **`@import`** (not `@use` / `@forward`).
- Custom **`rem-calc()`** (Foundation-style) in `utilities/_rem-calc.scss`.
- **`/` division** in functions and a few rules (e.g. `strip-unit`, flickity) — Dart Sass 2.x treats `/` as list separator unless using `math.div()` or legacy API.

### What “latest Sass” means

| Tool | Status |
|------|--------|
| **Ruby `sass` 3.x** | Deprecated |
| **libsass / sassc** | Deprecated (what you use now via `sass-rails`) |
| **Dart Sass** (`sass` on npm, or `dartsass-rails` gem) | **Current standard** — required for “latest” |

You do **not** need to rewrite all SCSS to use `@use` on day one; Dart Sass still compiles legacy `@import` with deprecation warnings.

---

## Upgrade path (recommended)

### Phase A — Keep Sprockets, modern compiler (low risk, can start on Rails 5.2 prep)

**When:** Before or during Rails 7 upgrade, independent of Vite JS.

| Step | Action |
|------|--------|
| A1 | Replace `sass-rails` with **`dartsass-rails`** on Rails 7+ (official Rails 7+ path) |
| A2 | Or run **`sass` npm** in CI to compile `application.scss` → `app/assets/builds/application.css` if using Propshaft-style pipeline later |
| A3 | Fix **slash-div** if build fails: enable `silenceDeprecations: ['slash-div']` temporarily, or patch `rem-calc` / flickity to `math.div()` |
| A4 | Smoke: home, country, search, thematic tabs, PDF layout |

**On Rails 5.2 today:** stay on sassc until B0; only document issues. Optional: one-off `npx sass app/assets/stylesheets/application.scss` in Docker to surface Dart Sass errors early.

### Phase B — Vite handles CSS (after [02b](./02-vite-on-rails-8.md), optional / incremental)

**When:** Vite 5 + Node 20 on upgrade branch.

| Step | Action |
|------|--------|
| B1 | `yarn add -D sass` (Dart Sass) |
| B2 | In `vite.config.ts`: `css.preprocessorOptions.scss` (silence deprecations during migration if needed) |
| B3 | New entry e.g. `app/frontend/entrypoints/application.scss` → `@import` or copy manifest from `application.scss` |
| B4 | Layout: `vite_stylesheet_tag 'application'` **or** keep Sprockets until full cutover ([08](#decision-scss-strategy) option A → B) |
| B5 | Move `pdf.scss` to Vite entry `pdf.scss` or keep Sprockets for PDF-only |

Vite bundles CSS referenced from JS entrypoints; for a global stylesheet, use a dedicated SCSS entrypoint.

### Phase C — Vue SFC + design tokens (optional, late)

- Scoped `<style lang="scss">` in migrated Vue 3 components.
- Shared variables: `app/frontend/styles/_settings.scss` imported via Vite `resolve.alias` (`@/styles/settings`).

---

## Decision: SCSS strategy

| Option | Description | Sass compiler |
|--------|-------------|----------------|
| **A — Sprockets + Vite JS only** | Keep `stylesheet_link_tag 'application'`; Vite only for JS. **Default for cutover.** | `dartsass-rails` on Rails 7 |
| **B — Incremental Vite CSS** | SCSS entries in `app/frontend/`; migrate slice by slice. | `sass` (npm) via Vite |
| **C — Tailwind** | Product redesign only. | n/a |

---

## Tasks

### Sass / compiler

- [ ] Baseline: `bundle exec rails assets:precompile` (Docker) — note compile time and output size.
- [ ] Optional spike: `npx sass app/assets/stylesheets/application.scss /tmp/app.css` on Node 12+ (Dart Sass) — list errors.
- [ ] On Rails 7 branch: swap `sass-rails` → `dartsass-rails`; remove `sassc` from lockfile.
- [ ] Remove `bourbon` / `neat` gems and `node_modules/bourbon` asset path if still unused.
- [ ] Replace `autoprefixer-rails` with PostCSS + `autoprefixer` when CSS moves to Vite; or `postcss-rails` with dartsass.

### Cutover (Webpacker)

- [ ] Remove `stylesheet_pack_tag 'application'` (redundant today).
- [ ] Remove `javascript_pack_tag` when Webpacker retired.
- [ ] Remove `config/webpack/`, `bin/webpack`, `@rails/webpacker`.

### Assets

- [ ] Audit CDN Font Awesome (v4 + v5 duplicate).
- [ ] `image_pack_tag` → Vite imports where used.
- [ ] `cookieconsent` CSS — Vite or Sprockets.

### PDF & Comfy

- [ ] `pdf.scss` + `@for_pdf` layout smoke after any compiler change.
- [ ] Comfy `custom.scss` — compile under same Dart Sass path as admin Sprockets.

### Vue

- [ ] Optional: scoped SFC styles for new islands only; do not mass-move 8k lines up front.

---

## Exit criteria

- Documented “how CSS works” (Sprockets vs Vite entries).
- **Dart Sass** in production path (gem or Vite), not sassc/libsass.
- No Webpacker; visual spot-check key pages + PDF.

---

## Risks

| Risk | Mitigation |
|------|------------|
| Dart Sass `/` division breaks build | `math.div()` in `rem-calc`; or deprecation silencing short-term |
| Glob `@import '*'` behaves differently | Test full compile; flatten imports only if needed |
| Dual CSS (Sprockets + Vite) | Option A until stable; one `application.css` URL in layout |
| 8k lines — big-bang rewrite | **Do not** `@use` migrate everything; compile-first migration |
