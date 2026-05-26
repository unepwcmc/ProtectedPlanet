Total around 6 months for frontend if no surprises then it can be shorter to 5 months

# Protected Planet — Frontend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below


|                     |                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Target**          | Rails 8 · Vite 5 · Vue 3 · island mounts                                                                                        |
| **Now**             | Rails 5.2 · Webpacker · `#v-app` · Vite 2 spike ✓                                                                               |
| **Owner**           | Frontend (+ Vite/ERB integration, Comfy admin JS)                                                                               |
| **Not in estimate** | Backend Rails 5→8 · CMS redesign                                                                                                |
| **Scope**           | **[Live inventory](./01-live-inventory.md)** — nav-led; ~14 entrypoints; dead code + **Vue 2–only npm** replacements in phase 4 |
| **Backend gates**   | [00 — Scope reference](./00-scope-and-backend-dependencies.md) (B0a done; **B0** = Rails 7.1+ for Vite 5 / Vue 3)               |


---

## Task plan

*Estimates @ 1 FTE with **AI assistance**, scoped to **[live pages/components](./01-live-inventory.md)**. Format: **weeks (months in brackets)**. Phases 4–7 overlap — do not sum the column.*


| #   | Phase                    | Key deliverables                                                       | Estimate                 | Detail                                                                    |
| --- | ------------------------ | ---------------------------------------------------------------------- | ------------------------ | ------------------------------------------------------------------------- |
| —   | Rails 5.2 prep           | Vue 2 refactors; Comfy Coffee→JS; remove dead globals/SFCs             | 2–5 wk (~0.5–1.25 mo)    | [13](./13-work-while-rails-upgrades.md)                                   |
| 1   | Discovery                | Confirm [live inventory](./01-live-inventory.md); CMS A/B/C            | 1–2 wk (~0.25–0.5 mo)    | [01](./01-discovery-and-inventory.md)                                     |
| 2a  | Vite foundation          | Dual bundler; Docker **vite** service; `frontend_mount`; entrypoints   | 1–2 wk (~0.25–0.5 mo)    | [02a](./02a-vite-spike-rails-5.md) · [15 Docker](./15-docker-vite-dev.md) |
| 2b  | Vite target stack        | `vite_rails` 3.x; Vite 5; Vue plugin; Node 20 Docker                   | 1–2 wk (~0.25–0.5 mo)    | [02](./02-vite-on-rails-8.md)                                             |
| 3   | Islands                  | **~14 entrypoints**; drop `#v-app`                                     | 5–8 wk (~1.25–2 mo)      | [03](./03-end-runtime-compilation.md)                                     |
| 4   | Vue 3 + state            | **~110** SFCs (not 125); drop 6 dead globals                           | 6–9 wk (~1.5–2.25 mo)    | [04](./04-vue3-and-state.md)                                              |
| 5   | Maps                     | Mapbox/MapLibre; bundle via Vite                                       | 4–7 wk (~1–1.75 mo)      | [05](./05-maps.md)                                                        |
| 6   | Charts                   | **6 live** chart families (+ stats pies); no sunburst/treemap/bar dead | 3–5 wk (~0.75–1.25 mo)   | [06](./06-charts-and-visualisations.md)                                   |
| 7   | Search & CMS UI          | Listings + thematic/equity **Vue pages** (not 127 static CMS URLs)     | 3–6 wk (~0.75–1.5 mo)    | [07](./07-search-listings-downloads.md)                                   |
| 8   | Styles & Sass            | Dart Sass; drop sassc / Webpacker CSS                                  | 3–5 wk (~0.75–1.25 mo)   | [08](./08-styles-and-assets.md)                                           |
| 9   | Testing                  | Vitest; Playwright on **live page list**                               | 2–4 wk (~0.5–1 mo)       | [09](./09-testing-and-qa.md)                                              |
| 10  | Release                  | Deploy vite build; PDF smoke                                           | 2–3 wk (~0.5–0.75 mo)    | [10](./10-deploy-and-devops.md)                                           |
|     | **Total — conservative** | AI + normal review; overlap included                                   | **24–34 wk (~6–8.5 mo)** |                                                                           |
|     | **Total — optimistic**   | AI-native; few surprises                                               | **19–27 wk (~5–7 mo)**   |                                                                           |


*Add **+15–25%** on conservative total if WDPA/OECM/equity tabs are harder than expected. **B0** (Rails 7.1+) delay affects **2b onward** only — see [00](./00-scope-and-backend-dependencies.md).*

**Out of scope (no estimate):** ~100+ static CMS resource/news pages, equity study-site articles, connectivity/ICCA thematic copy-only pages, orphan Vue files listed in [01-live-inventory](./01-live-inventory.md).

---

## Detail documents


| Doc                                                          | Contents                                             |
| ------------------------------------------------------------ | ---------------------------------------------------- |
| [00 Scope reference](./00-scope-and-backend-dependencies.md) | You vs backend, B0–B5 milestones (not a gated phase) |
| [01b Live inventory](./01-live-inventory.md)                 | Nav-led pages, entrypoints, dead vs live components  |
| [14 Architecture](./14-architecture-and-design.md)           | Islands, CMS patterns, mounts                        |
| [12 Gems & assets](./12-gemfile-frontend-dependencies.md)    | Gemfile / npm / Sprockets / Comfy admin              |
| [15 Docker Vite dev](./15-docker-vite-dev.md)                | Replace webpacker container with vite (phased)       |


*May 2026*