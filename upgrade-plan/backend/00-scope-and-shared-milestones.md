# 00 — Scope & shared milestones

| | |
|---|---|
| **Type** | **Reference** — not a gated phase or estimate line |
| **Status** | Active — B0 is the next shared gate. Revisit before each milestone. |
| **Owner** | Backend lead |
| **Target** | Rails 8 · Ruby 3.3 · **B0 (Rails 7.1+)** for frontend unblock |

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

**Also owns (integration / unblocking frontend):**

- Announce B0 when Rails 7.1 boots locally + CI — frontend can't start phase 2b without it
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
| B0a | Vite 2 + vite_rails 2.x on Rails 5.2 | Frontend | Done | Dual bundler in dev |
| **B0** | **Rails 7.1+ boots locally & CI** | **Backend** | **Frontend phase 2b** | vite_rails 3.x, Vite 5, Vue 3 all need Ruby 2.7+ and Rails 7.1+ |
| B1 | `bin/vite dev` + HMR on target stack | Shared | Frontend phase 2b complete | Backend ensures server boots; frontend wires vite service |
| B2 | Staging deploy includes `vite build` | DevOps + Frontend | Staging QA | Now built **into the image** — see [11](./11-deploy-and-devops.md) |
| B3 | CMS `/admin` works on upgrade branch | Backend | CMS pages in frontend migration | Smoke: login, edit via Redactor, upload, fixture import — see [09](./09-cms-comfy.md) |
| B4 | Rails 8.0 target reached | Backend | Platform target locked | Frontend architecture unchanged between 7 and 8 |
| B5 | Webpacker gem removed from deploy | Shared | Final Vite cutover | See [11](./11-deploy-and-devops.md) |

**Frontend is not blocked on B0** for its Track A prep work (Vue 2 refactors, Comfy Coffee → JS). Backend should not block frontend from merging prep PRs to `main`.

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

- [ ] Backend contact + target date for B0 communicated to frontend colleague.
- [ ] Agreed that frontend prep PRs can merge to `main` before B0.
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
