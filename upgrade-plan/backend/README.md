Total around 6–9.5 months for backend. **Phase 1 is complete — the test suite is revived and fully green on Rails 5.2** (624 runs, 0 failures, Jul 2026), and CI now enforces it. GDAL/FileGDB and the Postgres server move are now the highest remaining risks.

# Protected Planet — Backend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below


|                     |                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------ |
| **Target**          | Rails 8 · Ruby 3.3 · Sidekiq 7 · PostGIS adapter 11.x · Postgres 17/18 · Docker + Kamal 2       |
| **Now**             | Rails 5.2 · **Ruby 2.7.8** · Sidekiq 5.2.5 · **Node 24** · ES client 7.2.0 · Capistrano + Passenger · **test suite green + CI enforcing** |
| **Owner**           | Backend (+ shared deploy/DevOps tasks with frontend)                                             |
| **Not in estimate** | Frontend Vue 3 / Vite migration · CMS content redesign · Elasticsearch server upgrade (stays 7.17) |
| **Critical gate**   | **B0 = Rails 7.1+ boots** — sequencing pivot for backend phases 6–14. **Does not gate the frontend** (corrected Jul 2026, see below) |
| **Scope**           | **[Gem audit](./01-gem-audit.md)** — every Gemfile entry with keep/upgrade/remove decision       |


---

## Task plan

*Estimates @ 1 FTE. **Phase 1 (test suite) is the gate — nothing after it can be verified until it's done.** Phases 4–7 run sequentially (Ruby/Rails bump order). 8–12 begin after B0. 13–15 are the infrastructure track (13 gates 14 gates 15).*


| #   | Phase                        | Key deliverables                                                          | Estimate                | Detail                              |
| --- | ---------------------------- | ------------------------------------------------------------------------- | ----------------------- | ----------------------------------- |
| **1** | **✅ Test suite — green on Rails 5.2** | **DONE (Jul 2026).** 624 runs, 0 failures. Revived from not-loading; 4 real app bugs fixed en route; Jenkins Test stage now actually runs | **done** | [10](./10-test-suite.md) |
| 2   | Scope & shared milestones    | B0–B5 milestone ownership; shared handoffs documented                     | —                       | [00](./00-scope-and-shared-milestones.md) |
| 3   | Gem audit & inventory        | Every gem: keep / upgrade / remove                                        | 1–2 wk (~0.25–0.5 mo)  | [01](./01-gem-audit.md)             |
| 4   | Ruby 2.6.3 → 2.7             | ✓ **Done on `feat/upgrade-frontend`** (2.7.8) — inherit + verify           | (banked)                | [02](./02-ruby-upgrade.md)          |
| 5   | Rails 5.2 → 6.0 → 6.1        | Zeitwerk; AR 6 APIs; PostGIS adapter → 7.x; Sidekiq 5→6                   | 3–5 wk (~0.75–1.25 mo) | [03](./03-rails-6.md)               |
| 6   | Ruby 2.7 → 3.3               | Keyword arg hard-break fixed. Before Rails 7 — Media Surfer needs ≥ 3.2   | 1–2 wk (~0.25–0.5 mo)  | [02](./02-ruby-upgrade.md)          |
| 7   | Rails 6.1 → 7.0 → **7.1 (B0)** | **B0 delivered**; CMS swapped to Media Surfer; Nokogiri unpinned         | 3–5 wk (~0.75–1.25 mo) | [04](./04-rails-7.md)               |
| 8   | Rails 7.1 → 8.0 **(B4)**     | Propshaft decision; PostGIS adapter → 11.x; Rails 8 target reached        | 2–3 wk (~0.5–0.75 mo)  | [05](./05-rails-8.md)               |
| 9   | PostGIS & database           | Adapter kept current at each Rails step; spatial regression suite         | 1–2 wk (~0.25–0.5 mo)  | [06](./06-postgis-and-database.md)  |
| 10  | Elasticsearch client         | `elasticsearch` gem → `~> 7.17`; server stays on 7.17.24 (no infra change)| 0.5–1 wk               | [07](./07-elasticsearch.md)         |
| 11  | Sidekiq 5 → 7                | Config DSL updated; WDPA pipeline smoke-tested end-to-end                 | 1–2 wk (~0.25–0.5 mo)  | [08](./08-sidekiq-and-workers.md)   |
| 12  | CMS — Comfy → Media Surfer   | Gem swapped; monkey-patches, custom tags and categories ported (B3)       | 2–3 wk (~0.5–0.75 mo)  | [09](./09-cms-comfy.md)             |
| 13  | **GDAL & spatial tooling**   | ESRI FileGDB SDK dropped; distro GDAL 3.8 + OpenFileGDB; `gdal` gem removed | 1–2 wk (~0.25–0.5 mo) | [13](./13-gdal-and-spatial-tooling.md) |
| 14  | **Deploy — Docker + Kamal 2** *(B2, B5)* | Production images; Kamal roles; Puma; cron; Capistrano removed  | 3–4 wk (~0.75–1 mo)    | [11](./11-deploy-and-devops.md)     |
| 15  | **Infrastructure migration** | Ubuntu 24.04 web + DB hosts; Postgres → 17/18 + PostGIS 3.5/3.6           | 2–3 wk (~0.5–0.75 mo)  | [12](./12-infrastructure-migration.md) |
|     | **Total remaining — conservative** |                                                                     | **23–37 wk (~5.75–9.25 mo)** |                          |
|     | **Total remaining — optimistic**   |                                                                     | **17–26 wk (~4.25–6.5 mo)** |                            |

> **Test suite was moved to phase 1 and is now complete (Jul 2026).** It was 100% dead at load (`mocha 1.0.0` vs `minitest 5.25`), which meant no "run tests, confirm green" checkpoint in any Rails phase could actually be honoured. It is now **fully green on Rails 5.2** and enforced by CI. Test work still continues *through* the Rails bumps (capybara 3, Ruby-3 gem compat, `factory_girl` → `factory_bot`), but the gate is cleared.

*Totals exclude the completed phase 1. Phases 13–15 replace the previous 1–2 wk "Capistrano refresh" scope; net addition there is ~+3–4 weeks.*

**B0 target (Rails 7.1)** can realistically land in **months 2–3**.

> ### ⚠️ Correction (Jul 2026) — B0 is not the frontend's gate
>
> This plan previously treated B0 as the project's most time-critical item because `vite_rails` 3.x and Vue 3 were believed to need Rails 7.1+. **They don't.** `feat/upgrade-frontend` runs `vite_rails 3.11.1` + Vite 7 + Vue 3 islands on **Rails 5.2.0** — the gem only requires `railties >= 5.1, < 9`. The real gates were **Ruby ≥ 2.7** and **Node ≥ 18**, both already delivered there (Ruby 2.7.8, Node 24.4.1).
>
> - The frontend and backend tracks are **decoupled**; frontend is not waiting on us.
> - **Phase 2 stage 1 (Ruby 2.6.3 → 2.7.8) is already done** — inherit it, don't redo it.
> - Rails bumps can now be sequenced on risk and review capacity rather than against a handoff date.
> - The remaining cross-team dependency runs the other way: **don't break the existing Vite/island setup** while bumping Rails.

---

## Milestone summary

| ID  | Milestone                              | Owner              | Unblocks                          |
| --- | -------------------------------------- | ------------------ | --------------------------------- |
| B0a | Vite 2 + vite_rails 2.x on Rails 5.2  | Frontend ✓ Done    | Dual bundler                      |
| **G1** | **Ruby 2.7.8 + Node 24 + Vite 7 + vite_rails 3.11.1** | Frontend ✓ **Done** | The actual frontend gate — already met |
| **B0** | **Rails 7.1+ boots locally & CI** | **Backend**        | Backend phases 6–14               |
| B1  | `bin/vite dev` + HMR on target stack   | Shared ✓ Done      | Delivered on `feat/upgrade-frontend` |
| B2  | Staging deploy includes `vite build`   | DevOps + Frontend  | Staging QA                        |
| B3  | CMS `/admin` works on upgrade branch   | Backend            | CMS pages                         |
| B4  | Rails 8.0 target reached               | **Backend**        | Platform target                   |
| B5  | Webpacker gem removed from deploy      | Shared             | Final cutover                     |

---

## Highest risks

| Risk | Impact | Where |
|------|--------|-------|
| ~~**Test suite is dead**~~ — **RESOLVED Jul 2026.** Revived to 624 runs / 0 failures on Rails 5.2; CI enforces it | was Critical — the safety net now exists | [10](./10-test-suite.md) |
| **GDAL / ESRI FileGDB** — `.gdb` downloads depend on a proprietary SDK compiled into GDAL 2.2.3, which will not build on a modern base image | **High** — blocks dockerization; wrong output silently breaks downstream users | [13](./13-gdal-and-spatial-tooling.md) |
| **Postgres major upgrade** — large spatial DB, PostGIS extension must move in step. *Local dev + CI are on 17 as of Aug 2026, and the PostGIS 2.5 → 3.x path is now a tested runbook ([06](./06-postgis-and-database.md)); production remains on 10* | **High** — data correctness + downtime | [12](./12-infrastructure-migration.md) |
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
| [10 Test suite](./10-test-suite.md)                              | **Phase 1 — DONE.** Revival log, 4 app bugs found, remaining gem work (capybara 3, factory_bot) |
| [11 Deploy — Docker + Kamal 2](./11-deploy-and-devops.md)        | Production images, Kamal roles, Puma, cron, B2/B5     |
| [12 Infrastructure migration](./12-infrastructure-migration.md)  | Ubuntu 24.04 hosts, Postgres 17/18, cutover plan      |
| [13 GDAL & spatial tooling](./13-gdal-and-spatial-tooling.md)    | Drop ESRI FileGDB SDK, OpenFileGDB, remove `gdal` gem |


*June 2026*
