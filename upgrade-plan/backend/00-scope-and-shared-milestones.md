# 00 — Scope & shared milestones

| | |
|---|---|
| **Type** | **Reference** — not a gated phase or estimate line |
| **Status** | Active — B0 is the next shared gate. Revisit before each milestone. |
| **Owner** | Backend lead |
| **Target** | Rails 8 · Ruby 3.3 · **B0 (Rails 7.1+)** as the backend platform milestone |

[← Back to overview](./README.md) · **[Gem audit →](./01-gem-audit.md)**

---

## Backend owns

**Full upgrade path:**

- Rails 5.2 → 6.0 → 6.1 → 7.0 → 7.1 → 7.2 → 8.0
- Ruby 2.6.3 → 2.7 → **3.2+ before Rails 7.0** → 3.3
- PostGIS / `activerecord-postgis-adapter` at each AR step (landing on **11.x**)
- Elasticsearch client gem alignment (server stays on 7.17.24)
- Sidekiq 5 → 7 + WDPA import pipeline health
- CMS: `comfortable_mexican_sofa` → **`comfortable_media_surfer`** at the Rails 7.0 step
- **GDAL 2.2.3 + ESRI FileGDB → distro GDAL 3.8 + OpenFileGDB**; remove the `gdal` gem
- **Deployment: Capistrano → Docker + Kamal 2**; Passenger → Puma
- **Infrastructure: new Ubuntu 24.04 web + DB hosts; Postgres → 17/18 + PostGIS 3.5/3.6**

> ## ⚠️ Corrected July 2026 — B0 does **not** gate the frontend
>
> The plan previously stated that `vite_rails` 3.x, Vite and Vue 3 required **Rails 7.1+**, making B0 the most schedule-critical item in the project. **That was wrong.**
>
> `feat/upgrade-frontend` has `vite_rails 3.11.1` + Vite 7 + Vue 3 islands running on **Rails 5.2.0**, verified in `Gemfile.lock`. The gem's only constraint is `railties >= 5.1, < 9`.
>
> The real gates were **Ruby ≥ 2.7** (`filter_map`) and **Node ≥ 18** (Vite 5+) — both already delivered on that branch (Ruby 2.7.8, Node 24.4.1).
>
> **Consequences:**
> - The two tracks are **decoupled**. Frontend is not waiting on any backend milestone.
> - B0 is now a **backend platform milestone**, not a cross-team gate. It stops being the most time-critical deliverable.
> - Backend can sequence Rails bumps on engineering grounds (risk, review capacity) rather than racing a frontend handoff.
> - **Phase 2 stage 1 (Ruby 2.6.3 → 2.7.8) is already done** on `feat/upgrade-frontend` — it is not backend work to repeat, only to inherit.

**Also owns (integration):**

- Announce B0 when Rails 7.1 boots locally + CI — informational for frontend, not a gate
- Keep API contracts for search / stats / downloads stable throughout migration
- `config/vite.rb` credentials / env vars on upgrade branch (coordinate with frontend)
- B3: smoke-test `/admin` after each Rails bump — login, edit (**Redactor**, not TinyMCE), upload

**Does not own:**

- Frontend Vue 3, Vite, islands, maps, charts, styles, Vitest, Playwright
- Comfy admin CoffeeScript → JS migration (frontend owns that — [frontend/12](../frontend/12-gemfile-frontend-dependencies.md))
- Vite build in Docker dev (frontend owns Docker vite service — [frontend/15](../frontend/15-docker-vite-dev.md))

---

## Shared (explicit handoffs)

| Item | Backend | Frontend |
|------|---------|----------|
| `vite_rails` 3.x bump on upgrade branch | Review, bundle | Write PR |
| `config/vite.rb` credentials / env | Set prod/staging values | Write stub |
| Rails version bumps | Lead | Assist on boot errors caused by frontend PRs |
| API contracts for search/stats | Keep stable | Document consumed shape |
| Node version (B2) | Baked into the Docker image ([11](./11-deploy-and-devops.md)) | Confirm `bin/vite build` works in the image |
| `VITE_*` build args | Wire into the image build, keep out of public layers | Declare which vars are needed |
| Webpacker removal (B5) | Remove gem + Dockerfile stage | Remove pack tags, JS |
| B3 CMS admin smoke | Lead | Confirm admin JS still works under Media Surfer |
| Comfy admin asset pipeline | Test Media Surfer under Sprockets; flag if Propshaft is forced | Adjust frontend assumption in [frontend/15](../frontend/15-docker-vite-dev.md) |

---

## Milestones (detail)

| ID | Milestone | Who | Unblocks | Notes |
|----|-----------|-----|----------|-------|
| B0a | Vite 2 + vite_rails 2.x on Rails 5.2 | Frontend | ✓ Done | Dual bundler in dev |
| **G1** | **Ruby 2.7.8 + Node 24 + Vite 7 + `vite_rails` 3.11.1 on Rails 5.2** | Frontend | ✓ **Done** (`feat/upgrade-frontend`) | **The actual frontend gate.** Backend inherits the Ruby 2.7 bump from here |
| **B0** | **Rails 7.1+ boots locally & CI** | **Backend** | Backend phases 6–14 | Backend platform milestone. **Does not gate frontend** — see the correction above |
| B1 | `bin/vite dev` + HMR on target stack | Shared | ✓ Done — HMR wired on `feat/upgrade-frontend` (`VITE_RUBY_HOST`, compose) | |
| B2 | Staging deploy includes `vite build` | DevOps + Frontend | Staging QA | Now built **into the image** — see [11](./11-deploy-and-devops.md) |
| B3 | CMS `/admin` works on upgrade branch | Backend | CMS pages in frontend migration | Smoke: login, edit via Redactor, upload, fixture import — see [09](./09-cms-comfy.md) |
| B4 | Rails 8.0 target reached | Backend | Platform target locked | Frontend architecture unchanged between 7 and 8 |
| B5 | Webpacker gem removed from deploy | Shared | Final Vite cutover | See [11](./11-deploy-and-devops.md) |

**Frontend is not blocked on B0 at all** — see the correction above. The remaining cross-team dependency runs the *other* way: the backend must not break the Vite/Vue 3 island setup that already exists while bumping Rails.

---

## Rails 7 vs 8 (backend impact summary)

| | Rails 6.1 | Rails 7.0 | Rails 7.1 (B0) | Rails 8.0 (B4) |
|--|-----------|-----------|----------------|----------------|
| Ruby min | 2.5 | 2.7 | 2.7 (3.x recommended) | 3.1 |
| Zeitwerk | Required | Required | Required | Required |
| Encrypted attrs | — | New | Stable | Stable |
| Propshaft | — | Optional | Optional | Default (Sprockets still works) |
| CMS | sofa 2.0.19 | **swap → Media Surfer** | Media Surfer | Media Surfer |
| PostGIS adapter | 7.x | 8.x | 9.x | **11.x** |
| Ruby min | 2.5 | **3.2 (our floor, for Media Surfer)** | 3.2 | 3.2 |

---

## Alignment checklist (revisit before B0)

- [ ] Backend contact + target date for B0 communicated to frontend colleague (informational — no longer a gate).
- [ ] **Vite/Vue 3 island setup re-smoke-tested after every Rails bump** — `vite_client_tag`, `vite_typescript_tag 'entrypoints/layout'`, `frontend_mount` output, and at least one live island (Banner). This is the live cross-team dependency now.
- [ ] CI (GitHub Actions or equivalent) configured to run against upgrade branch.
- [ ] Comfy admin asset-pipeline outcome under Media Surfer communicated to frontend — see [09](./09-cms-comfy.md).

---

## Facts still needed (blocking estimates on 11 / 12 / 13)

No shell access on the backend side. Someone with server access must confirm:

- [ ] Production Postgres + PostGIS versions, and **database size** — see [12](./12-infrastructure-migration.md)
- [ ] Current OS on the Linode web and DB hosts
- [ ] WDPA release cadence, so the DB switchover window avoids an import
- [ ] Data-team acceptance criteria for `.gdb` downloads — see [13](./13-gdal-and-spatial-tooling.md)
- [ ] Whether infrastructure work is in scope and budgeted alongside the Rails upgrade
- [ ] Container registry decision (GHCR under `unepwcmc`, or Docker Hub)
