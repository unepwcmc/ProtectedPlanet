**The backend upgrade is complete and live on staging (Sep 2026).** Every phase in the
table below has landed: the Rails ladder ran 5.2 → 6.0 → 6.1 → 7.0 → 7.1 → 7.2 → 8.0 → **8.1**,
Ruby is on **4.0.6**, and the app runs on Docker + Kamal 2 against Postgres 17 / PostGIS 3.5.
Suite: **744 runs, 0 failures, 2 skips**, enforced by GitHub Actions on every push.
What remains is not upgrade work — it is infrastructure decisions (production deploy
target, Memcached → Redis) and test coverage. See [CARRYOVER](./CARRYOVER.md).

# Protected Planet — Backend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below


|                     |                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------ |
| **Target**          | Rails 8 · Ruby 3.3 · Sidekiq 7 · PostGIS adapter 11.x · Postgres 17/18 · Docker + Kamal 2       |
| **Now (Sep 2026)**  | **Rails 8.1.3.1** (`load_defaults 8.1`) · **Ruby 4.0.6** · Sidekiq 7.3.9 · Node 26.8.1 · ES client 7.17.11 · postgis-adapter 11.1.1 · Media Surfer 3.1.7 · vite_rails 3.11.1 · Docker + Kamal 2 on staging · **744 runs / 0 failures, CI enforcing** |
| **Past target**     | Shipped Rails 8.1 rather than stopping at 8.0, and **Ruby 4.0.6** rather than 3.3 — 3.3 went security-only on 2026-04-01 (EOL 2027-03-31), so staying put had a deadline. Capistrano and Webpacker are both gone from the bundle |
| **Owner**           | Backend (+ shared deploy/DevOps tasks with frontend)                                             |
| **Not in estimate** | Frontend Vue 3 / Vite migration · CMS content redesign · Elasticsearch server upgrade (stays 7.17) |
| **Critical gate**   | ~~**B0 = Rails 7.1+ boots**~~ — **cleared Jul 2026**; kept here for the sequencing history below |
| **Scope**           | **[Gem audit](./01-gem-audit.md)** — every Gemfile entry with keep/upgrade/remove decision       |


---

## Task plan

*Estimates @ 1 FTE. **Phase 1 (test suite) is the gate — nothing after it can be verified until it's done.** Phases 4–7 run sequentially (Ruby/Rails bump order). 8–12 begin after B0. 13–15 are the infrastructure track (13 gates 14 gates 15).*


| #   | Phase                        | Outcome                                                                   | Status                  | Detail                              |
| --- | ---------------------------- | ------------------------------------------------------------------------- | ----------------------- | ----------------------------------- |
| 1   | Test suite — green on Rails 5.2 | Revived from not-loading (mocha 1.0.0 vs minitest 5.25); 4 real app bugs fixed en route | ✅ Jul 2026 | [10](./10-test-suite.md) |
| 2   | Scope & shared milestones    | B0–B5 ownership documented; backend/frontend decoupling corrected          | ✅                      | [00](./00-scope-and-shared-milestones.md) |
| 3   | Gem audit & inventory        | Every gem decided; bundle later pruned 423 → 196 gems                      | ✅                      | [01](./01-gem-audit.md)             |
| 4   | Ruby 2.6.3 → 2.7             | Inherited from `feat/upgrade-frontend` (2.7.8)                             | ✅ (banked)             | [02](./02-ruby-upgrade.md)          |
| 5   | Rails 5.2 → 6.0 → 6.1        | Zeitwerk; AR 6 APIs; PostGIS adapter → 7.x; Sidekiq 5→6                    | ✅                      | [03](./03-rails-6.md)               |
| 6   | Ruby 2.7 → **3.3.7**         | Keyword-arg break fixed; `::Data`→`DataPages`; factory_girl→factory_bot    | ✅ Jul 2026             | [02](./02-ruby-upgrade.md)          |
| 6b  | Ruby 3.3.7 → **4.0.6**       | Off a security-only branch. One code change (`gem 'csv'`, now bundled-only); no other gem moved | ✅ Sep 2026 | [CARRYOVER §2b](./CARRYOVER.md) |
| 7   | Rails 6.1 → 7.0 → **7.1 (B0)** | B0 delivered; CMS swapped to Media Surfer; Nokogiri unpinned             | ✅ Jul 2026             | [04](./04-rails-7.md)               |
| 7b  | Rails 7.1 → 7.2              | `Rails.application.secrets` → `config_for(:app_secrets)` (the 7.2 blocker) | ✅                      | [04](./04-rails-7.md)               |
| 8   | Rails 7.2 → 8.0 **(B4)**     | PostGIS adapter → 11.0; rails-i18n 7 → 8; clean, zero code changes         | ✅ Aug 2026             | [05](./05-rails-8.md)               |
| 8b  | **Rails 8.0 → 8.1**          | `load_defaults 8.1`; postgis-adapter 11.1.1; referrer redirect guard added | ✅ Sep 2026             | [05](./05-rails-8.md)               |
| 9   | PostGIS & database           | Adapter current at every step; PG 11 → **17** + PostGIS 2.5 → **3.5**      | ✅                      | [06](./06-postgis-and-database.md)  |
| 10  | Elasticsearch client         | Gem → 7.17.11; server stays 7.17.24 (no infra change)                      | ✅                      | [07](./07-elasticsearch.md)         |
| 11  | Sidekiq 5 → 7                | 7.3.9; config DSL updated; capsules; WDPA pipeline smoke-tested            | ✅                      | [08](./08-sidekiq-and-workers.md)   |
| 12  | CMS — Comfy → Media Surfer   | 3.1.7; monkey-patches, custom tags and categories ported (B3)              | ✅                      | [09](./09-cms-comfy.md)             |
| 13  | GDAL & spatial tooling       | ESRI FileGDB SDK dropped; distro GDAL + OpenFileGDB; `gdal` gem removed    | ✅                      | [13](./13-gdal-and-spatial-tooling.md) |
| 14  | Deploy — Docker + Kamal 2 *(B2, B5)* | Kamal roles, Puma, cron; Capistrano **and** Webpacker gone from the bundle | ✅ staging only  | [11](./11-deploy-and-devops.md)     |
| 15  | Infrastructure migration     | Ubuntu 24.04 staging host; Postgres 17 + PostGIS 3.5                       | ⚠️ staging done, **production outstanding** | [12](./12-infrastructure-migration.md) |

**The upgrade itself is finished.** The original estimate was 23–37 weeks remaining as of June 2026;
the work ran from June to September 2026 and landed past target (8.1 rather than 8.0).

### The one phase not fully closed

Phase 15 covers staging only. `config/deploy.yml` and `config/deploy.staging.yml` both set
`RAILS_ENV: staging`, and there is **no Kamal production destination** — while Capistrano has
already been removed from the bundle. So production currently has no deploy path defined in
this repo. That is a DevOps task and an EM decision, not backend upgrade work, but it is the
one thing standing between "done on staging" and "done".


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
| **B0** | Rails 7.1+ boots locally & CI | Backend ✓ **Done** Jul 2026 | Backend phases 6–14 — all landed |
| B1  | `bin/vite dev` + HMR on target stack   | Shared ✓ Done      | Delivered on `feat/upgrade-frontend` |
| B2  | Staging deploy includes `vite build`   | DevOps + Frontend ✓ Done | Staging QA — live on Kamal 2 |
| B3  | CMS `/admin` works on upgrade branch   | Backend ✓ Done     | CMS pages — Media Surfer 3.1.7    |
| B4  | Rails 8.0 target reached               | Backend ✓ **Done** — now on 8.1.3.1 | Platform target exceeded |
| B5  | Webpacker gem removed from deploy      | Shared ✓ Done      | Gone from the bundle entirely     |

---

## Highest risks

| Risk | Impact | Where |
|------|--------|-------|
| ~~**Test suite is dead**~~ — **RESOLVED Jul 2026.** Revived to 624 runs / 0 failures on Rails 5.2; CI enforces it | was Critical — the safety net now exists | [10](./10-test-suite.md) |
| ~~**GDAL / ESRI FileGDB**~~ — **RESOLVED.** SDK dropped for distro GDAL + OpenFileGDB; `gdal` gem removed; image builds on Ubuntu 24.04 | was High — *`.gdb` output still wants data-team acceptance sign-off* | [13](./13-gdal-and-spatial-tooling.md) |
| **Postgres major upgrade** — dev, CI and **staging** are on 17 + PostGIS 3.5; the 2.5 → 3.x soft-upgrade is a tested runbook ([06](./06-postgis-and-database.md)). **Production remains on 10** | **High** — the largest remaining risk; data correctness + downtime | [12](./12-infrastructure-migration.md) |
| **CMS port** — Media Surfer is the unreleased Comfy master line; our monkey-patching touches private engine API | Medium — ported and live, but still pinned to an unreleased line | [09](./09-cms-comfy.md) |
| **PostGIS adapter** — each AR bump needs spatial regression | Medium — data correctness | [06](./06-postgis-and-database.md) |
| **WDPA import pipeline** — complex async chain must survive every bump | Medium — data ingestion | [08](./08-sidekiq-and-workers.md) |
| ~~**Ruby 3 keyword args**~~ — **RESOLVED** on 3.3.7; Mocha configured with `strict_keyword_argument_matching` so expectations cannot silently mismatch | was Medium | [02](./02-ruby-upgrade.md) |
| ~~**Zeitwerk autoloader**~~ — **RESOLVED**; `lib/modules` eager loaded and `zeitwerk:check` clean | was Medium | [03](./03-rails-6.md) |

GDAL is resolved and the CMS is ported. **The production Postgres 10 host is now the single highest risk** — it is the last piece of the old stack still carrying live traffic, and it has no deploy path defined in this repo since Capistrano was removed.

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


*Written June 2026 · status refreshed 14 September 2026*
