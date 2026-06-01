Total around 5–7 months for backend if no major surprises (Comfy CMS being the highest risk)

# Protected Planet — Backend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below


|                     |                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------ |
| **Target**          | Rails 8 · Ruby 3.3 · Sidekiq 7 · PostGIS adapter 8.x                                            |
| **Now**             | Rails 5.2 · Ruby 2.6.3 · Sidekiq 5.2.5 · Node v10 · ES client 7.2.0                            |
| **Owner**           | Backend (+ shared deploy/DevOps tasks with frontend)                                             |
| **Not in estimate** | Frontend Vue 3 / Vite migration · CMS content redesign · Elasticsearch server upgrade (stays 7.17) |
| **Critical gate**   | **B0 = Rails 7.1+ boots** — unblocks frontend phases 2b onward (vite_rails 3.x, Vue 3)          |
| **Scope**           | **[Gem audit](./01-gem-audit.md)** — every Gemfile entry with keep/upgrade/remove decision       |


---

## Task plan

*Estimates @ 1 FTE. Phases 3–5 must run sequentially (Rails minor bump order). Phases 6–11 can begin after B0.*


| #   | Phase                        | Key deliverables                                                          | Estimate                | Detail                              |
| --- | ---------------------------- | ------------------------------------------------------------------------- | ----------------------- | ----------------------------------- |
| 0   | Scope & shared milestones    | B0–B5 milestone ownership; shared handoffs documented                     | —                       | [00](./00-scope-and-shared-milestones.md) |
| 1   | Gem audit & inventory        | Every gem: keep / upgrade / remove; Comfy compat verdict                  | 1–2 wk (~0.25–0.5 mo)  | [01](./01-gem-audit.md)             |
| 2   | Ruby 2.6.3 → 2.7             | Keyword arg warnings resolved; CI green on 2.7                            | 1–2 wk (~0.25–0.5 mo)  | [02](./02-ruby-upgrade.md)          |
| 3   | Rails 5.2 → 6.0 → 6.1        | Zeitwerk; AR 6 APIs; PostGIS adapter bump; Sidekiq 5→6                    | 3–5 wk (~0.75–1.25 mo) | [03](./03-rails-6.md)               |
| 4   | Rails 6.1 → 7.0 → **7.1 (B0)** | **B0 delivered**; Comfy compat confirmed; Nokogiri unpinned             | 3–5 wk (~0.75–1.25 mo) | [04](./04-rails-7.md)               |
| 5   | Rails 7.1 → 8.0 **(B4)**     | Propshaft decision; Rails 8 platform target reached                       | 2–3 wk (~0.5–0.75 mo)  | [05](./05-rails-8.md)               |
| 6   | Ruby 2.7 → 3.x               | Keyword arg hard-break fixed; Ruby 3.3 on CI + deploy                     | 1–2 wk (~0.25–0.5 mo)  | [02](./02-ruby-upgrade.md)          |
| 7   | PostGIS & database           | Adapter kept current at each Rails step; spatial regression suite         | 1–2 wk (~0.25–0.5 mo)  | [06](./06-postgis-and-database.md)  |
| 8   | Elasticsearch client         | `elasticsearch` gem → `~> 7.17`; server stays on 7.17.24 (no infra change)| 0.5–1 wk               | [07](./07-elasticsearch.md)         |
| 9   | Sidekiq 5 → 7                | Config DSL updated; WDPA pipeline smoke-tested end-to-end                 | 1–2 wk (~0.25–0.5 mo)  | [08](./08-sidekiq-and-workers.md)   |
| 10  | CMS — Comfy compat           | Rails 7/8 compat confirmed or patch/fork plan agreed                      | 1–4 wk (~0.25–1 mo)    | [09](./09-cms-comfy.md)             |
| 11  | Test suite modernisation     | `factory_bot`; capybara 3.x; webmock/timecop bumped                       | 1–2 wk (~0.25–0.5 mo)  | [10](./10-test-suite.md)            |
| 12  | Deploy & DevOps **(B2, B5)** | Node 20 on servers; Capistrano updated; Webpacker removed from deploy     | 1–2 wk (~0.25–0.5 mo)  | [11](./11-deploy-and-devops.md)     |
|     | **Total — conservative**     |                                                                           | **18–30 wk (~4.5–7.5 mo)** |                                  |
|     | **Total — optimistic**       |                                                                           | **14–22 wk (~3.5–5.5 mo)** |                                  |


*Add **+20%** if ComfortableMexicanSofa has no Rails 7/8 compat path and requires patching or replacing — see [09](./09-cms-comfy.md).*

**B0 target (Rails 7.1)** can realistically land in **months 2–3**, unblocking the frontend team well before the full backend upgrade is complete.

---

## Milestone summary

| ID  | Milestone                              | Owner              | Unblocks                          |
| --- | -------------------------------------- | ------------------ | --------------------------------- |
| B0a | Vite 2 + vite_rails 2.x on Rails 5.2  | Frontend ✓ Done    | Dual bundler                      |
| **B0** | **Rails 7.1+ boots locally & CI** | **Backend**        | **Frontend phases 2b onward**     |
| B1  | `bin/vite dev` + HMR on target stack   | Shared             | Frontend phase 2b                 |
| B2  | Staging deploy includes `vite build`   | DevOps + Frontend  | Staging QA                        |
| B3  | Comfy `/admin` works on upgrade branch | Backend            | CMS pages                         |
| B4  | Rails 8.0 target reached               | **Backend**        | Platform target                   |
| B5  | Webpacker gem removed from deploy      | Shared             | Final cutover                     |

---

## Highest risks

| Risk | Impact | Where |
|------|--------|-------|
| **ComfortableMexicanSofa** — no maintained Rails 7/8 compat path | High — CMS blocks B3 | [09](./09-cms-comfy.md) |
| **PostGIS adapter** — each AR bump needs spatial regression | Medium — data correctness | [06](./06-postgis-and-database.md) |
| **WDPA import pipeline** — complex async chain must survive every bump | Medium — data ingestion | [08](./08-sidekiq-and-workers.md) |
| **Ruby 3 keyword args** — silent breakage across service objects / lib | Medium — runtime errors | [02](./02-ruby-upgrade.md) |
| **Zeitwerk autoloader** (Rails 6) — `autoload_paths` customisations in `application.rb` | Medium — boot errors | [03](./03-rails-6.md) |

---

## Detail documents


| Doc                                                              | Contents                                              |
| ---------------------------------------------------------------- | ----------------------------------------------------- |
| [00 Scope & milestones](./00-scope-and-shared-milestones.md)     | Backend vs frontend ownership, B0–B5 milestone detail |
| [01 Gem audit](./01-gem-audit.md)                                | Every Gemfile entry: compat status + action           |
| [02 Ruby upgrade](./02-ruby-upgrade.md)                          | 2.6.3 → 2.7 → 3.3 path, keyword-arg changes          |
| [03 Rails 6](./03-rails-6.md)                                    | 5.2 → 6.0 → 6.1, Zeitwerk, AR changes                |
| [04 Rails 7 (B0)](./04-rails-7.md)                              | 6.1 → 7.0 → 7.1, critical B0 gate                    |
| [05 Rails 8 (B4)](./05-rails-8.md)                              | 7.1 → 8.0, Propshaft, final target                   |
| [06 PostGIS & database](./06-postgis-and-database.md)            | Adapter upgrades, spatial regression suite            |
| [07 Elasticsearch](./07-elasticsearch.md)                        | Client gem bump; server stays on 7.17.24              |
| [08 Sidekiq & workers](./08-sidekiq-and-workers.md)              | 5 → 7 migration, WDPA pipeline, scheduled jobs        |
| [09 CMS — Comfy](./09-cms-comfy.md)                              | Rails 7/8 compat risk, patch/fork/replace options     |
| [10 Test suite](./10-test-suite.md)                              | factory_bot, capybara 3, webmock, timecop             |
| [11 Deploy & DevOps](./11-deploy-and-devops.md)                  | Capistrano, Node 20, B2/B5, Passenger/Puma            |


*June 2026*
