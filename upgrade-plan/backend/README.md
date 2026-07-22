Total around 6–8.5 months for backend if no major surprises (GDAL/FileGDB and the Postgres server move being the highest risks)

# Protected Planet — Backend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below


|                     |                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------ |
| **Target**          | Rails 8 · Ruby 3.3 · Sidekiq 7 · PostGIS adapter 11.x · Postgres 17/18 · Docker + Kamal 2       |
| **Now**             | Rails 5.2 · Ruby 2.6.3 · Sidekiq 5.2.5 · Node v10 · ES client 7.2.0 · Capistrano + Passenger    |
| **Owner**           | Backend (+ shared deploy/DevOps tasks with frontend)                                             |
| **Not in estimate** | Frontend Vue 3 / Vite migration · CMS content redesign · Elasticsearch server upgrade (stays 7.17) |
| **Critical gate**   | **B0 = Rails 7.1+ boots** — unblocks frontend phases 2b onward (vite_rails 3.x, Vue 3)          |
| **Scope**           | **[Gem audit](./01-gem-audit.md)** — every Gemfile entry with keep/upgrade/remove decision       |


---

## Task plan

*Estimates @ 1 FTE. Phases 3–6 must run sequentially (Ruby/Rails bump order). Phases 7–11 can begin after B0. Phases 12–14 are the infrastructure track and run after B0 — 12 gates 13, 13 gates 14.*


| #   | Phase                        | Key deliverables                                                          | Estimate                | Detail                              |
| --- | ---------------------------- | ------------------------------------------------------------------------- | ----------------------- | ----------------------------------- |
| 0   | Scope & shared milestones    | B0–B5 milestone ownership; shared handoffs documented                     | —                       | [00](./00-scope-and-shared-milestones.md) |
| 1   | Gem audit & inventory        | Every gem: keep / upgrade / remove                                        | 1–2 wk (~0.25–0.5 mo)  | [01](./01-gem-audit.md)             |
| 2   | Ruby 2.6.3 → 2.7             | Keyword arg warnings resolved; CI green on 2.7                            | 1–2 wk (~0.25–0.5 mo)  | [02](./02-ruby-upgrade.md)          |
| 3   | Rails 5.2 → 6.0 → 6.1        | Zeitwerk; AR 6 APIs; PostGIS adapter → 7.x; Sidekiq 5→6                   | 3–5 wk (~0.75–1.25 mo) | [03](./03-rails-6.md)               |
| 4   | Ruby 2.7 → 3.3               | Keyword arg hard-break fixed. **Moved before Rails 7** — Media Surfer needs ≥ 3.2 | 1–2 wk (~0.25–0.5 mo) | [02](./02-ruby-upgrade.md)      |
| 5   | Rails 6.1 → 7.0 → **7.1 (B0)** | **B0 delivered**; CMS swapped to Media Surfer; Nokogiri unpinned         | 3–5 wk (~0.75–1.25 mo) | [04](./04-rails-7.md)               |
| 6   | Rails 7.1 → 8.0 **(B4)**     | Propshaft decision; PostGIS adapter → 11.x; Rails 8 target reached        | 2–3 wk (~0.5–0.75 mo)  | [05](./05-rails-8.md)               |
| 7   | PostGIS & database           | Adapter kept current at each Rails step; spatial regression suite         | 1–2 wk (~0.25–0.5 mo)  | [06](./06-postgis-and-database.md)  |
| 8   | Elasticsearch client         | `elasticsearch` gem → `~> 7.17`; server stays on 7.17.24 (no infra change)| 0.5–1 wk               | [07](./07-elasticsearch.md)         |
| 9   | Sidekiq 5 → 7                | Config DSL updated; WDPA pipeline smoke-tested end-to-end                 | 1–2 wk (~0.25–0.5 mo)  | [08](./08-sidekiq-and-workers.md)   |
| 10  | CMS — Comfy → Media Surfer   | Gem swapped; monkey-patches, custom tags and categories ported (B3)       | 2–3 wk (~0.5–0.75 mo)  | [09](./09-cms-comfy.md)             |
| 11  | Test suite modernisation     | `factory_bot`; capybara 3.x; webmock/timecop bumped                       | 1–2 wk (~0.25–0.5 mo)  | [10](./10-test-suite.md)            |
| 12  | **GDAL & spatial tooling**   | ESRI FileGDB SDK dropped; distro GDAL 3.8 + OpenFileGDB; `gdal` gem removed | 1–2 wk (~0.25–0.5 mo) | [13](./13-gdal-and-spatial-tooling.md) |
| 13  | **Deploy — Docker + Kamal 2** *(B2, B5)* | Production images; Kamal roles; Puma; cron; Capistrano removed  | 3–4 wk (~0.75–1 mo)    | [11](./11-deploy-and-devops.md)     |
| 14  | **Infrastructure migration** | Ubuntu 24.04 web + DB hosts; Postgres → 17/18 + PostGIS 3.5/3.6           | 2–3 wk (~0.5–0.75 mo)  | [12](./12-infrastructure-migration.md) |
|     | **Total — conservative**     |                                                                           | **23–37 wk (~5.75–9.25 mo)** |                             |
|     | **Total — optimistic**       |                                                                           | **18–28 wk (~4.5–7 mo)** |                                   |


*Phases 12–14 replace the previous 1–2 wk "Capistrano refresh" scope. Net addition to the plan is roughly **+3–4 weeks**, not the full 6–9 weeks those three phases total.*

**B0 target (Rails 7.1)** can realistically land in **months 2–3**, unblocking the frontend team well before the full backend upgrade is complete.

---

## Milestone summary

| ID  | Milestone                              | Owner              | Unblocks                          |
| --- | -------------------------------------- | ------------------ | --------------------------------- |
| B0a | Vite 2 + vite_rails 2.x on Rails 5.2  | Frontend ✓ Done    | Dual bundler                      |
| **B0** | **Rails 7.1+ boots locally & CI** | **Backend**        | **Frontend phases 2b onward**     |
| B1  | `bin/vite dev` + HMR on target stack   | Shared             | Frontend phase 2b                 |
| B2  | Staging deploy includes `vite build`   | DevOps + Frontend  | Staging QA                        |
| B3  | CMS `/admin` works on upgrade branch   | Backend            | CMS pages                         |
| B4  | Rails 8.0 target reached               | **Backend**        | Platform target                   |
| B5  | Webpacker gem removed from deploy      | Shared             | Final cutover                     |

---

## Highest risks

| Risk | Impact | Where |
|------|--------|-------|
| **GDAL / ESRI FileGDB** — `.gdb` downloads depend on a proprietary SDK compiled into GDAL 2.2.3, which will not build on a modern base image | **High** — blocks dockerization; wrong output silently breaks downstream users | [13](./13-gdal-and-spatial-tooling.md) |
| **Postgres major upgrade** — large spatial DB, PostGIS extension must move in step | **High** — data correctness + downtime | [12](./12-infrastructure-migration.md) |
| **CMS port** — Media Surfer is the unreleased Comfy master line; our monkey-patching touches private engine API | Medium — CMS blocks B3 | [09](./09-cms-comfy.md) |
| **PostGIS adapter** — each AR bump needs spatial regression | Medium — data correctness | [06](./06-postgis-and-database.md) |
| **WDPA import pipeline** — complex async chain must survive every bump | Medium — data ingestion | [08](./08-sidekiq-and-workers.md) |
| **Ruby 3 keyword args** — silent breakage across service objects / lib | Medium — runtime errors | [02](./02-ruby-upgrade.md) |
| **Zeitwerk autoloader** (Rails 6) — `autoload_paths` customisations in `application.rb` | Medium — boot errors | [03](./03-rails-6.md) |

The CMS was previously the single highest risk. Adopting Media Surfer moved it from *strategic* (might have to replace the CMS) to *tactical* (how much of our patching still applies). GDAL takes its place at the top.

---

## Detail documents


| Doc                                                              | Contents                                              |
| ---------------------------------------------------------------- | ----------------------------------------------------- |
| [00 Scope & milestones](./00-scope-and-shared-milestones.md)     | Backend vs frontend ownership, B0–B5 milestone detail |
| [01 Gem audit](./01-gem-audit.md)                                | Every Gemfile entry: compat status + action           |
| [02 Ruby upgrade](./02-ruby-upgrade.md)                          | 2.6.3 → 2.7 → 3.3 path, keyword-arg changes          |
| [03 Rails 6](./03-rails-6.md)                                    | 5.2 → 6.0 → 6.1, Zeitwerk, AR changes                |
| [04 Rails 7 (B0)](./04-rails-7.md)                              | 6.1 → 7.0 → 7.1, critical B0 gate, CMS swap          |
| [05 Rails 8 (B4)](./05-rails-8.md)                              | 7.1 → 8.0, Propshaft, final target                   |
| [06 PostGIS & database](./06-postgis-and-database.md)            | Adapter upgrades to 11.x, spatial regression suite    |
| [07 Elasticsearch](./07-elasticsearch.md)                        | Client gem bump; server stays on 7.17.24              |
| [08 Sidekiq & workers](./08-sidekiq-and-workers.md)              | 5 → 7 migration, WDPA pipeline, scheduled jobs        |
| [09 CMS — Comfy → Media Surfer](./09-cms-comfy.md)               | Gem swap, monkey-patch port, B3                       |
| [10 Test suite](./10-test-suite.md)                              | factory_bot, capybara 3, webmock, timecop             |
| [11 Deploy — Docker + Kamal 2](./11-deploy-and-devops.md)        | Production images, Kamal roles, Puma, cron, B2/B5     |
| [12 Infrastructure migration](./12-infrastructure-migration.md)  | Ubuntu 24.04 hosts, Postgres 17/18, cutover plan      |
| [13 GDAL & spatial tooling](./13-gdal-and-spatial-tooling.md)    | Drop ESRI FileGDB SDK, OpenFileGDB, remove `gdal` gem |


*June 2026*
