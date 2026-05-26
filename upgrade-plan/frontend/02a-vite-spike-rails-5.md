# 02a — Vite spike on Rails 5.2 (validated)

| | |
|---|---|
| **Status** | **Working** in Docker (May 2026) |
| **Stack** | Rails 5.2 · Ruby 2.6.3 · Node 12.22 · `vite_rails` 2.0.13 |
| **Unblocks** | Track A/B frontend work **without waiting for B0** |
| **Still needs B0** | `vite_rails` 3.x, Vite 5+, Vue 3 plugin, Docker Node 20+ ([02](./02-vite-on-rails-8.md)) |

[← Back to overview](./README.md) · [02 — Target Vite setup](./02-vite-on-rails-8.md)

---

## What was proven

- `vite_rails` runs alongside **Webpacker 4** (dual bundler).
- `bundle exec vite build` produces assets under `public/vite-dev/`.
- Layout serves the bundle: `vite_javascript_tag 'entrypoints/application'` (manifest key is `entrypoints/application.js`).
- Homepage returns **200** with script tag `/vite-dev/assets/application.*.js`.
- Console spike message: `Vite + Rails spike: application.js loaded`.

**Not in scope for this spike:** Vue 3, HMR dev server in compose, staging deploy, Webpacker removal.

---

## Pinned versions (Rails 5.2 / Node 12)

| Package | Version | Notes |
|---------|---------|--------|
| `vite_rails` | `~> 2.0.13` | Pulls `vite_ruby` 1.2.x |
| `vite` (npm) | `2.9.18` | Last line for Node 12 |
| `vite-plugin-ruby` (npm) | `3.1.3` | Use `.default` in `vite.config.js` (CJS) |
| `loofah` | `~> 2.19.1` | 2.21+ needs `Nokogiri::HTML4` (not in nokogiri 1.10) |

**Do not use on this stack:** `vite_rails` 3.x (Ruby 2.7+ `filter_map`), Vite 5+ (Node 18+).

---

## Repo files (spike)

| File | Role |
|------|------|
| `config/vite.json` | `sourceCodeDir`: `app/frontend`, `autoBuild` in development |
| `vite.config.js` | CommonJS + `vite-plugin-ruby` |
| `app/frontend/entrypoints/application.js` | Spike entrypoint |
| `app/views/layouts/partials/_head.html.erb` | `vite_client_tag` + `vite_javascript_tag` **after** Webpacker tags |
| `bin/vite` | Binstub |
| `.gitignore` | `public/vite-dev`, `public/vite-test`, `public/vite` |

---

## Docker commands

**Full compose plan:** [15 — Docker: Webpacker → Vite dev](./15-docker-vite-dev.md).

```bash
# Build (after changing app/frontend/)
docker exec protectedplanet-web bash -lc 'cd /ProtectedPlanet && bundle exec vite build'

# Target: dedicated vite service (see doc 15)
# docker compose up  →  protectedplanet-vite on :3036
```

Verify: open http://localhost:3000 → browser console for spike message. **Vue 2** still needs `protectedplanet-webpacker` until phase 3.

---

## Why `vite_rails` 3.x waits for B0

| Requirement | Rails 5.2 spike | Target (Rails 7+) |
|-------------|-----------------|---------------------|
| Ruby | 2.6 OK with 2.x gems | 2.7+ / 3.x |
| Node (Dockerfile) | 12.x | **20+** (proposed) |
| Vite | 2.9 | 5.x |
| Vue | Webpacker 2.7 only | `@vitejs/plugin-vue` + Vue 3 |

Bump gems and npm on the **upgrade branch** when B0 lands — do not block prep islands on 5.2.

---

## Suggested next steps (on `main`, Rails 5.2)

- [ ] Add `frontend_mount` helper + JSON props ([14](./14-architecture-and-design.md)) — no Vue 3 required.
- [ ] Second entrypoint (e.g. `layout.ts` → plain `.js` spike) per page type from [01](./01-discovery-and-inventory.md).
- [ ] Document dual-bundler page list (Webpacker vs Vite).
- [ ] Implement Docker **D1**: `vite` service in `docker-compose.yml` ([15](./15-docker-vite-dev.md)).
- [ ] Keep Webpacker as source of truth for Vue 2 until B0 + phase 3 cutover.

---

## Exit criteria (spike — met)

- [x] Vite builds in Docker on Node 12.
- [x] Rails layout loads Vite asset without removing Webpacker.
- [x] Team agrees frontend prep is **not blocked** on backend for foundation work.
