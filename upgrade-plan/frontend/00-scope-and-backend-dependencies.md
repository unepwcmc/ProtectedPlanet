# 00 — Scope reference (you vs backend, milestones)

| | |
|---|---|
| **Type** | **Reference** — not a gated phase or estimate line |
| **Status** | Assumed **done for active work** (B0a complete, prep/2a underway). **Revisit before B0** merge if ownership or dates change. |
| **Owner** | You (frontend lead + integration backend) |
| **Target** | **Rails 8** + Vite 5 + Vue 3 · **B0 (Rails 7.1+)** for target gem/npm stack |

[← Back to overview](./README.md) · **[Work while blocked →](./13-work-while-rails-upgrades.md)**

---

## Your role

**Primary:** Public UI — Vue 3, Vite, islands, maps, charts, search, styles, frontend tests.

**Also (integration backend):** Small Ruby/DevOps changes that unblock the frontend — you can own these with backend review:

- `vite_rails` 2.x on `main` (spike); bump to 3.x + `config/vite.rb` on upgrade branch
- ERB helpers, layout tags, `Procfile.dev`
- Comfy admin Coffee → JS + removing `coffee-rails`
- Dead gem removal (`sprockets-vue`, `phantompdf`, …) when audited
- Docker Node version, deploy docs for `bin/vite build` · [15 Docker Vite dev](./15-docker-vite-dev.md)

**Backend colleague still owns:** Full Rails upgrade path, PostGIS, Sidekiq, DB submodule, Elasticsearch, Capistrano production, Comfy **gem** compatibility on Rails 8.

---

## Milestones (plan around these)

| ID | Milestone | Who | Unblocks |
|----|-----------|-----|----------|
| — | **Prep work on Rails 5.2** | **You** ([13](./13-work-while-rails-upgrades.md)) | Smaller diff on upgrade branch |
| **B0a** | **Vite 2 + vite_rails 2.x** on Rails 5.2 (Docker) | **You** | **Done** — dual bundler ([02a](./02a-vite-spike-rails-5.md)) |
| **B0** | **Rails 7.1+ boots** locally & CI | Backend (+ you: vite 3.x bump PR) | **vite_rails 3.x, Vite 5, Vue 3 (G1)** |
| B1 | `bin/vite dev` + HMR on target stack | Shared | Phase 2b |
| B2 | Staging deploy includes `vite build` | DevOps + you | Staging QA |
| B3 | Comfy `/admin` works on upgrade branch | Backend + you smoke test | CMS pages |
| B4 | Rails **8.0** target reached | Backend | Platform target ([14](./14-architecture-and-design.md) unchanged) |
| B5 | Webpacker gem removed | Shared | Phase 8 cutover |

**You are not blocked on B0** for Track A, **Vite foundation (2a)**, or `frontend_mount` design in [13](./13-work-while-rails-upgrades.md).

---

## Rails 7 vs 8 (for you)

| | Rails 7.1+ | Rails 8 |
|--|------------|---------|
| `vite_rails` 2.x + Vite 2 (dual bundler) | **Yes — on main now** | Bump to 3.x on upgrade branch |
| `vite_rails` 3.x + Vite 5 | No (needs Ruby 2.7+, Node 18+) | **Start Vue 3 islands here (G1)** |
| Vue 3 + Vite islands | After B0 | Continue |
| Design | [14](./14-architecture-and-design.md) | Same on 7 and 8 |
| Your prep on 5.2 | **No change** | Still valid |

Frontend architecture does **not** change between 7 and 8 — only gem versions and QA.

---

## You own (detailed)

- `app/javascript/` → `app/frontend/` migration
- `package.json` / yarn (Vue 3, Vite, Vitest, maps, charts)
- `vite.config.ts`, entrypoints, composables, Pinia
- ERB: mount divs, `vite_*_tag`, remove `#v-app` pattern
- Public SCSS strategy ([08](./08-styles-and-assets.md))
- Vitest + Playwright ([09](./09-testing-and-qa.md))
- Comfy custom admin JS under `app/assets/javascripts/comfy/`

---

## Shared (explicit handoffs)

| Item | You | Backend |
|------|-----|---------|
| `vite_rails` 2.x on `main` | **Done (spike)** | Review merge |
| `vite_rails` 3.x bump | PR on upgrade branch | Review, bundle |
| `config/vite.rb` | Write (stub OK on 5.2) | Credentials / env |
| Rails version bumps | Assist on boot errors caused by your PRs | Lead |
| API contracts for search/stats | Document | Keep stable |
| `@for_pdf` | CSS/JS layout | PDF generator |

---

## When Rails 7 is not ready yet

→ **[13 — Work while Rails upgrades](./13-work-while-rails-upgrades.md)** (Track A + B).

Do **not** wait idle: Vue 2 prep refactors and Comfy JS merge to `main` and directly shrink the post-upgrade diff.

---

## Alignment checklist (optional — revisit before B0)

Use only if you need formal stakeholder sign-off; otherwise treat as satisfied while executing prep / 2a.

- [ ] Backend contact + target date for **B0 (Rails 7)**.
- [ ] Agreed prep PRs can merge to `main` before B0.
- [ ] Ticket backlog from Track A week 1–2 exists.
- [ ] Team signed off [14 — Architecture](./14-architecture-and-design.md) (islands + JSON props).
