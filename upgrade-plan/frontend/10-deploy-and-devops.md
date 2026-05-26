# 10 — Deploy and DevOps

| | |
|---|---|
| **Estimate** | 2–4 weeks · ~0.5–1 month (overlaps phase 2b cutover) |
| **Depends on** | [02b](./02-vite-on-rails-8.md#phase-2b--on-upgrade-branch-rails-71) (staging/prod Vite 5) · [02a](./02a-vite-spike-rails-5.md) (local Docker only today) |
| **Blocks** | Production release |

[← Back to overview](./README.md)

---

## Goal

Staging and production deploy Rails + Vite assets reliably. Node version modernized. PDF generation still works.

**Today:** Vite 2 spike runs in **Docker dev only** ([02a](./02a-vite-spike-rails-5.md)) — no Capistrano `vite build` on servers until **B2** (target stack on Rails 7+).

---

## Current deployment (wiki)

| Item | Value |
|------|--------|
| Tool | **Capistrano** |
| Branches | `develop` → staging, `master` → production |
| Build | On server at deploy time |
| Node on server | 10 / 12 (legacy) |
| Ansible Node default | Very old pin in `config/deploy/ansible` — must update |

---

## Tasks

### Node & yarn

- [ ] Node **20 LTS** (or 22) on servers, Docker, CI, developer docs.
- [ ] `yarn install --frozen-lockfile` in deploy hook.
- [ ] `bin/vite build` before or during `assets:precompile`.

### Capistrano

- [ ] Document new deploy steps in project README.
- [ ] Verify `public/vite` / manifest copied to `current/release`.
- [ ] Rollback procedure tested (Capistrano rollback + asset manifest).

### Environment variables

- [ ] Mapbox token on server (was implicit via Rails/env for ERB; now `VITE_*` at build time).
- [ ] `NODE_ENV=production` for Vite build.
- [ ] Staging vs production analytics IDs.

### Puppeteer / PDF

- [ ] Upgrade `puppeteer` from v5 (security + Node compatibility) — **this is the live PDF path** (npm), not the `phantompdf` gem.
- [ ] Confirm `phantompdf` gem unused → remove from Gemfile ([12](./12-gemfile-frontend-dependencies.md)).
- [ ] `lib/modules/download/generators/pdf.rb` — path to Chromium binary.
- [ ] Docker: `docs/docker.md` chrome copy workaround — revisit for new Puppeteer.
- [ ] Regression: country PDF, PA PDF (`@for_pdf` class on layout).

### Monitoring

- [ ] AppSignal — confirm JS errors visible (if applicable).
- [ ] Smoke URL checks post-deploy (optional automation).

### CI

- [ ] Travis replacement / GitHub Actions: Ruby + Node matrix, `vite build`, `vitest`.
- [ ] Block merge if asset build fails.

---

## Dual-deploy period

While Webpacker and Vite coexist:

- [ ] Deploy must run **both** compiles or feature-flagged pages break.
- [ ] Document which release removed Webpacker.

---

## Exit criteria

- Staging deploy documented and repeatable by second developer.
- Production deploy dry-run completed.
- PDF download generation verified on staging after Node/Puppeteer upgrade.

---

## Reference

- `protected-planet-wiki/deployment.md`
- `ProtectedPlanet/docs/docker.md` (Puppeteer chrome path)
