# 02 — Vite setup (prep on 5.2 → target on Rails 7+)


|                                   |                                                                                                              |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Estimate**                      | **2a:** 1–2 wk after **B0**                                                                                  |
| **Prep (now)**                    | [02a — Spike validated](./02a-vite-spike-rails-5.md)                                                         |
| **Blocked for target stack only** | `vite_rails` 3.x, Vite 5, Vue 3 plugin — gated on **Ruby 2.7+ & Node 18+ (Node 24 LTS)**, *not* Rails 7 ([README §Version gates](./README.md#version-gates--execution-order)) |
| **Design**                        | [14 — Architecture](./14-architecture-and-design.md)                                                         |


[← Back to overview](./README.md)

---

## Two sub-phases

```text
2a — Foundation (Rails 5.2, NOW)          2b — Target stack (Rails 7+, after B0)
────────────────────────────────          ─────────────────────────────────────
✓ vite_rails 2.x + Vite 2.9               vite_rails 3.x + Vite 5+
✓ Dual Webpacker + Vite                   @vitejs/plugin-vue + Vue 3
✓ app/frontend/entrypoints                Docker Node 20+, staging vite build
  helpers, mount design                     First Vue 3 island on upgrade branch
```

Frontend **is not idle** while backend upgrades — only the **gem/npm bump** waits for B0.

---

## Phase 2a — On `main` (Rails 5.2) — in progress

See [02a](./02a-vite-spike-rails-5.md) for versions and Docker commands.

### Done (spike)

- `gem 'vite_rails', '~> 2.0.13'` + `loofah ~> 2.19.1`
- `config/vite.json`, `vite.config.js`, `app/frontend/entrypoints/application.js`
- `_head.html.erb`: Vite tags alongside Webpacker
- `bundle exec vite build` in Docker (Node 12)

### Remaining on 5.2

- `frontend_mount` helper + `readMountProps` ([14](./14-architecture-and-design.md))
- `content_for :vite_entrypoints` pattern for per-layout entrypoints
- Page list: Webpacker pack vs Vite entrypoint ([01](./01-discovery-and-inventory.md))
- Optional: `Procfile.dev` / compose service for `bin/vite dev` (HMR)
- Document `VITE_`* env names for Mapbox etc. (`config/vite.rb` stub OK on 5.2)

### Constraints (do not fight on 5.2)

- Stay on **Vite 2.9** and **vite_rails 2.x** until B0.
- New islands: prefer **vanilla JS** or keep Vue 2 in Webpacker until 2b.
- Tag helper name: `vite_javascript_tag 'entrypoints/<name>'` (manifest keys include `entrypoints/`).

---

## Phase 2b — On upgrade branch (Rails 7.1+)

Follow [vite_rails](https://vite-ruby.netlify.app/) current docs — not the 5.2 spike pins.

### npm + Vite

- Bump to `vite` 5.x, **`vite-plugin-rails`** (not `vite-plugin-ruby`; confirmed — see `vite.config.mts`), `@vitejs/plugin-vue`, `vue@3` — pin after `bundle exec vite install` on upgrade branch.
- `vite.config.ts`: `rails()` + `vue()`; `@` → `app/frontend`; Vue **runtime-only** in production ([14](./14-architecture-and-design.md)).
- Replace `vite.config.js` (CJS) with TS config when Node 20 is in Docker.

### Ruby

- `gem 'vite_rails', '~> 3.0'` (drop 2.x pin)
- `config/vite.rb` — `VITE_`* for Mapbox token, etc.

### ERB / first Vue 3 island

- Re-verify tag helpers (manifest keys may differ on plugin 5.x — may simplify to `vite_javascript_tag 'application'`).
- First mount: e.g. nav-burger via JSON script props ([03](./03-end-runtime-compilation.md))
- Staging deploy with `bin/vite build` after **B2**

### Dev workflow

- `Procfile.dev`: `web` + `vite`
- Docker Node **20+** in `Dockerfile` ([10](./10-deploy-and-devops.md))
- Document `rails s` + `bin/vite dev`

---

## Prep from Rails 5.2 ([13](./13-work-while-rails-upgrades.md))

Discovery, Comfy JS, Vue 2 slot fixes — merge to `main`; 2a Vite foundation continues in parallel.

---

## Exit criteria

**2a (5.2):**

- Dual bundler documented and building in Docker.
- `frontend_mount` helper merged.
- ≥1 non-spike entrypoint or page-level entrypoint plan from discovery.

**2b (7+):**

- `vite_rails` 3.x + Vite 5 on upgrade branch.
- One Vue 3 island on staging (after B2).
- Page list updated for target manifest/tag conventions.

