Total around 6 months for frontend if no surprises then it can be shorter to 5 months

# Protected Planet — Frontend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below · **Wave-by-wave history:** [CHANGELOG.md](./CHANGELOG.md) · **Coding style:** [CODE-CONVENTIONS.md](./CODE-CONVENTIONS.md)


|                     |                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Target**          | Vite 7 · Vue 3 · island mounts (Rails 7/8 desirable but **not required** for the frontend — see gates)                          |
| **Now**             | Rails 5.2 · **Ruby 2.7.8 ✓ · Node 24.4.1 ✓ · Vite 7 + vite-plugin-rails ✓** · Webpacker⇄Vite dual bundler ✓ · Waves 0–10 done (see status below) |
| **Owner**           | Frontend (+ Vite/ERB integration, Comfy admin JS)                                                                               |
| **Not in estimate** | Backend Rails 5→8 · CMS redesign                                                                                               |
| **Scope**           | **[Live inventory](./01-live-inventory.md)** — nav-led; ~12 entrypoints; dead code + **Vue 2–only npm** replacements in phase 4 |
| **Real gates**      | **Ruby 2.7+** (for `vite_rails` 3.x) + **Node 18+** (for Vite 5) — *not* Rails 7. See [Version gates](#version-gates--execution-order) |


---

## Status — G1 gate done (Jul 2026)

**Stack today:** Ruby 2.7.8, Node 24.4.1, Vite 7 + `vite-plugin-rails` (`vite_rails` 3.11.1) running
**alongside** Webpacker/Vue 2 (dual bundler, cold-start safe). Islands foundation built —
`frontend_mount` helper + `readMountProps` + `app/frontend/lib/islands.ts` (registry, lazy Vue,
`MutationObserver`), registered in `entrypoints/layout.ts`. Tailwind v4 added via Vite (preflight
disabled, additive to the legacy SCSS — [08 Styles](./08-styles-and-assets.md#decision-tailwind-v4--added-additive-july-2026)).
Vitest set up (282 tests, all green).

**Waves 0–10 are done.** Full narrative — decisions made, bugs found and fixed, how each wave was
verified — lives in **[CHANGELOG.md](./CHANGELOG.md)**; this table is just the current state:

| Wave | Scope | Status |
|---|---|---|
| 0 | Delete dead code | ✓ done |
| 1 | Simple leaves (Banner, ga-link, counter, listing cards) | ✓ done |
| 2 | Mixin-only leaves (tooltip, tooltip-second) | ✓ done — both now wired live (tooltip-second in Wave 8, tooltip in Wave 10) |
| 3 | Global chrome (nav, search topbar), break `#v-app` | mostly done — `search-site` deferred (still Vue2) |
| 4 | Pinia + downloads | ✓ done |
| 5 | Listings + tabs | ✓ done — `Tabs` island only covers pages without `tab_extras` |
| 6 | Maps (MapLibre) | ✓ done |
| 7 | Search areas | ✓ done |
| 8 | Charts + stats | ✓ done — amCharts stays on v4 |
| 9 | PA show `attributes-*` | ✓ done |
| 10 | PAME | ✓ done |
| 11 | Carousel (flickity → Swiper/CSS) | not started — next up |
| 12 | Finish (remove `#v-app`, Webpacker) | not started, blocked on 3 and 11 landing |

**Next:** the entire Vue 2→3 migration (Waves 0–12) and Webpacker removal are done. Remaining frontend
work: **[16 — SCSS → Tailwind migration](./16-scss-to-tailwind-migration.md)** (retire the ~8.1k-line
legacy SCSS pipeline in waves T0–T10, closing the CODE-CONVENTIONS.md rule-4 exceptions along the way)
and amCharts 4→5 (deferred out of Wave 8, still not started).

### Decisions made
- **Vite/Rails glue — `vite-plugin-rails`** (not `vite-plugin-ruby`) is the npm package actually wired up (`vite.config.mts`) alongside the `vite_rails` gem. [02](./02-vite-on-rails-8.md) corrected to match.
- **Maps — MapLibre GL JS** (open source, no Mapbox account/licensing dependency) over Mapbox GL v2+. Requires migrating `mapbox://` style URLs and re-testing RTL/polygons/zoom. Detail: [05](./05-maps.md#decision-maplibre).
- **Analytics — `vue-gtag`** (GA4) replaces `vue-analytics`. Detail: [04](./04-vue3-and-state.md#dependency-replacements).

### Decisions to revisit later
- **Mounting library — homegrown for now; revisit `turbo-mount` after Ruby 3 / Rails 6+.** We use a small in-house mounter (`frontend_mount` + `islands.ts`). [`turbo-mount`](https://github.com/skryukov/turbo-mount) (Evil Martians, Stimulus-based) is the "batteries-included" equivalent, but its **gem requires Ruby ≥ 3.0 and railties ≥ 6.0** — won't install on our **Ruby 2.7.8 / Rails 5.2** — and it pulls in Hotwire/Stimulus. Because views only ever call `frontend_mount`, adopting it later is a ~2-file swap (Vue SFCs never move). Detail: [14 Architecture](./14-architecture-and-design.md#mounting-mechanism-and-the-turbo-mount-decision).

---

## Task plan

*Estimates @ 1 FTE with **AI assistance**, scoped to **[live pages/components](./01-live-inventory.md)**. Format: **weeks (months in brackets)**. Phases 4–7 overlap — do not sum the column.*


| #   | Phase                    | Key deliverables                                                       | Estimate                 | Detail                                                                    |
| --- | ------------------------ | ---------------------------------------------------------------------- | ------------------------ | ------------------------------------------------------------------------- |
| —   | Rails 5.2 prep           | Vue 2 refactors; Comfy Coffee→JS; remove dead globals/SFCs             | 2–5 wk (~0.5–1.25 mo)    | [13](./13-work-while-rails-upgrades.md)                                   |
| 1   | Discovery                | Confirm [live inventory](./01-live-inventory.md); CMS A/B/C            | 1–2 wk (~0.25–0.5 mo)    | [01](./01-discovery-and-inventory.md)                                     |
| 2a  | Vite foundation          | Dual bundler; Docker **vite** service; `frontend_mount`; entrypoints   | 1–2 wk (~0.25–0.5 mo)    | [02a](./02a-vite-spike-rails-5.md) · [15 Docker](./15-docker-vite-dev.md) |
| 2b  | Vite target stack        | Ruby 2.7; `vite_rails` 3.x; Vite 5; Vue plugin; **Node 24 LTS** Docker  | 1–2 wk (~0.25–0.5 mo)    | [02](./02-vite-on-rails-8.md)                                             |
| 3   | Islands                  | **~12 entrypoints**; drop `#v-app`                                     | 5–8 wk (~1.25–2 mo)      | [03](./03-end-runtime-compilation.md)                                     |
| 4   | Vue 3 + state            | **~110** SFCs (not 125); drop ~9 dead/child-only globals               | 6–9 wk (~1.5–2.25 mo)    | [04](./04-vue3-and-state.md)                                              |
| 5   | Maps                     | Mapbox/MapLibre; bundle via Vite                                       | 4–7 wk (~1–1.75 mo)      | [05](./05-maps.md)                                                        |
| 6   | Charts                   | **4 live** chart families; no dial/sunburst/treemap/bar (dead)         | 3–5 wk (~0.75–1.25 mo)   | [06](./06-charts-and-visualisations.md)                                   |
| 7   | Search & CMS UI          | Listings + wdpca/gdpame/marine/effectiveness (not 127 CMS URLs)        | 3–6 wk (~0.75–1.5 mo)    | [07](./07-search-listings-downloads.md)                                   |
| 8   | Styles & Sass            | Dart Sass; drop sassc / Webpacker CSS                                  | 3–5 wk (~0.75–1.25 mo)   | [08](./08-styles-and-assets.md)                                           |
| 9   | Testing                  | Vitest; Playwright on **live page list**                               | 2–4 wk (~0.5–1 mo)       | [09](./09-testing-and-qa.md)                                              |
| 10  | Release                  | Deploy vite build; PDF smoke                                           | 2–3 wk (~0.5–0.75 mo)    | [10](./10-deploy-and-devops.md)                                           |
|     | **Total — conservative** | AI + normal review; overlap included                                   | **24–34 wk (~6–8.5 mo)** |                                                                           |
|     | **Total — optimistic**   | AI-native; few surprises                                               | **19–27 wk (~5–7 mo)**   |                                                                           |


*Add **+15–25%** on conservative total if the wdpca/gdpame/effectiveness tabs are harder than expected. Phase **2b onward** is gated on **Ruby 2.7 + Node 18+**, not on the Rails major — see [Version gates](#version-gates--execution-order).*

**Out of scope (no estimate):** ~100+ static CMS resource/news pages, equity study-site articles, connectivity/ICCA thematic copy-only pages, orphan Vue files listed in [01-live-inventory](./01-live-inventory.md).

---

## Version gates & execution order

### The real dependency gates

The modern frontend stack is **not** gated on Rails 7/8. The actual technical requirements are:

| Want | Requires | Not |
|------|----------|-----|
| `vite_rails` 3.x | **Ruby 2.7+** (`filter_map`) | any specific Rails major |
| Vite 5+ | **Node 18+** | — |
| Vue 3 + `@vitejs/plugin-vue` | Vite 5 | — |

Rails 5.2 officially supports Ruby up to 2.7, so **bumping Ruby 2.6.3 → 2.7 while staying on Rails 5.2** is enough to unlock the modern gem. The Rails major can lag. *(Rails 7 is still worth doing later — Comfy, `dartsass-rails`, security — but it does not block this work. Validate `vite_rails` 3.x on Rails 5.2 with a short spike.)*

### The Node ↔ Webpacker constraint

Today **one `Dockerfile` (`ruby:2.6.3`, Node 12), one `package.json`, one shared `node_modules`** serve `weba` + `webpacker` + `vite`. Bumping Node to 18+ breaks Webpacker 4 (webpack 4's `md4`/OpenSSL 3 error, `ERR_OSSL_EVP_UNSUPPORTED`).

**Good news:** this app does **not** use `node-sass` (SCSS compiles Ruby-side via `sassc`/`sass-rails`), so the only fix needed to keep Webpacker 4 alive on modern Node is one flag on the **webpacker service only**:

```
NODE_OPTIONS=--openssl-legacy-provider
```

With that, a single bumped Node (24 LTS) runs **both** Webpacker 4 (Vue 2, with the flag) and Vite 5 (Vue 3) during the migration overlap. Expect minor `yarn install` peer-dep friction, but no native-module wall. Use **Node 24 LTS**, not 26 (26 is not LTS until ~Oct 2026).

### Recommended execution order (constrained path — current Ruby/Rails)

> **Status (Jul 2026):** steps **1–6 ✓ done** (Waves 0–10, see status table above) · step **7 pending** (Webpacker removal, blocked on Waves 3, 11–12).

1. **Delete genuinely-dead code now ✓ done** (safe on Rails 5.2): orphan `.vue` files, dead globals (`ChartDial`, carousel, sunburst/treemap/bar, `select-equity`/`select-dropdown`), `leaflet`, plus the last orphaned SCSS (`_select-equity.scss`). Browser polyfills (`babel-polyfill`/`es6-promise`/`url-search-params-polyfill`) are a separate, not-yet-done audit — [01](./01-live-inventory.md), [13](./13-work-while-rails-upgrades.md).
2. **Add Vite as a Docker dev service alongside Webpacker** (dual bundler, already spiked) — [15](./15-docker-vite-dev.md).
3. **Ruby 2.6.3 → 2.7** on Rails 5.2 (rebuild image on `ruby:2.7` base). Unlocks `vite_rails` 3.x.
4. **Node 12 → 24 LTS** in the Dockerfile; add `--openssl-legacy-provider` to the webpacker service.
5. **`vite_rails` 2→3, Vite 2.9→5** + `@vitejs/plugin-vue`.
6. **Migrate Vue 2→3 island by island**; swap each component's Vue2-only deps (vuex→Pinia, vue-analytics→GA4, …) and drop each package once unused — [04](./04-vue3-and-state.md).
7. **Remove Webpacker last** — service, gem, `@rails/webpacker`, config, and the legacy flag together — [03](./03-end-runtime-compilation.md), [15](./15-docker-vite-dev.md) D3.

**Webpack removal is the finish line, not the first step** — it stays until the last Vue component is on Vite. Keep the dual-Node overlap window short.

---

## Component migration order (Vue 2 → Vue 3)

Order derived from a coupling scan (mixin / Vuex `$store` / `$eventHub` / maps / charts) over the
live components. **Principle:** leaf & zero-coupling first → mixin-only → global chrome (then break
`#v-app`) → **state stores before the components that use them** → maps & charts (gated on their
library decisions) → Webpacker removed last. Every component is rewritten to the conventions:
**TypeScript `<script setup>` (Composition API) + Tailwind + mixins replaced by composables/utils**
(not ported as-is) — see **[CODE-CONVENTIONS.md](./CODE-CONVENTIONS.md)** for the full 20-point list.

Full detail (decisions, bugs found/fixed, verification) per wave: **[CHANGELOG.md](./CHANGELOG.md)**.

| Wave | Components (ERB tag) | Prereq / why |
|------|----------------------|--------------|
| **0 · Delete dead code first ✓** | `chart-dial`, carousel/`carousel-slide`, `sticky-nav`, `chart-bar`/`chart-bar-simple`, `chart-sunburst`/`chart-treemap-*`/`chart-rectangles`, `select-equity`/`select-dropdown`, ~10 orphan `.vue` | Don't migrate the dead — shrinks phase 4. Safe on Rails 5.2. |
| **1 · Simple leaves ✓** (zero coupling) | `banner-banner`, `ga-link`, `counter`, `select-with-content`, `listing-page-card-news`, `listing-page-card-resources` | Establish the Composition-API + Tailwind + composable pattern on the lowest-risk surface. |
| **2 · Mixin-only leaves ✓** (⚠️ `tooltip` still not wired live) | `tooltip`, `tooltip-second` | First mixin→composable extractions; no store/bus. |
| **3 · Global chrome → break `#v-app`** ⚠️ mostly done | `nav-burger`, `search-site-topbar`, `search-site` | mixin→composable, `$eventHub`→`mitt`/emits. Once chrome is islands, **dismantle `#v-app`**. `search-site` deferred — still Vue2, still imports legacy `TabsFake.vue`. |
| **4 · Pinia + downloads ✓** | `useDownloadStore` (port Vuex `download`), `download`, `download-item`, `download-csv`, `download-modal` | Set up **Pinia** first; downloads span pages (loaded from `layout`). |
| **5 · Listings + tabs ✓** | `listing-page`, `tabs`/`tab-target`/`tab-trigger` | `$eventHub 'map:resize'`→composable; wire news/resources + a real tab page. `Tabs` island only replaces pages with no `tab_extras`. |
| **6 · Maps ✓** (phase 5) | `v-map` (+ `-header`/`-filters`/`-pa-search`/`-disclaimer`/`-baselayer-controls`/`-toggler`) | **MapLibre chosen** + `useMapStore` (Pinia) first. |
| **7 · Search areas ✓** | `search-areas`, `search-areas-home`, `search-areas-input-autocomplete` (+ filters/tabs-fake/pagination leaves) | Closes the Wave 4 download-store bridge. Separate from the Map PA-search box (Wave 6). |
| **8 · Charts + stats ✓** | `chart-row-pa`, `chart-row-stacked`, `am-chart-multiline`, `am-chart-pie`, `region-country-pages` (+ `Stats*`) | Custom SVG charts + stats are lower-risk than amCharts. **amCharts 4→5 deferred** to its own follow-up. |
| **9 · PA show — done** | `attributes-*` (5) | mixin→composable; page's map/download pieces already Vue3 (Waves 4/6). |
| **10 · PAME — done** | `usePameStore` (port Vuex `pame`), `filtered-table`, `pame-modal` (+ table subcomponents) | gdpame page. Also wired in the previously-unwired `tooltip` from Wave 2 (PAME table header uses it) — legacy `Tooltip.vue`/`TooltipSecond.vue` deleted. |
| **11 · Carousel — not started** | replace `flickity` (`vue-flickity`) → Swiper/CSS | affects home + marine hero carousels. No spike done yet. |
| **12 · Finish — not started** | remove `#v-app`, `vue.js`, Vuex, `vue-analytics`/`vue2-touch-events`/`vue-lazyload`, Webpacker + packs | Webpacker removed last, once nothing is left on Vue 2 — blocked on Wave 3's `search-site` and Wave 11 landing first. |

---

## Code conventions (Vue 3 / TypeScript)

Every component written or migrated from Wave 1 onward follows a 20-point style guide covering
TypeScript, types placement, component/folder naming, BEM+Tailwind CSS rules, props/events casing,
and template conventions. It's the coding-style reference for this project — read it before writing
or migrating a component: **[CODE-CONVENTIONS.md](./CODE-CONVENTIONS.md)**.

---

## Detail documents


| Doc                                                          | Contents                                             |
| ------------------------------------------------------------ | ---------------------------------------------------- |
| [CHANGELOG](./CHANGELOG.md)                                  | Wave-by-wave history — decisions, bugs found/fixed, verification |
| [CODE-CONVENTIONS](./CODE-CONVENTIONS.md)                     | 20-point Vue 3 / TypeScript coding-style guide       |
| [00 Scope reference](./00-scope-and-backend-dependencies.md) | You vs backend, B0–B5 milestones (not a gated phase) |
| [01b Live inventory](./01-live-inventory.md)                 | Nav-led pages, entrypoints, dead vs live components  |
| [14 Architecture](./14-architecture-and-design.md)           | Islands, CMS patterns, mounts                        |
| [12 Gems & assets](./12-gemfile-frontend-dependencies.md)    | Gemfile / npm / Sprockets / Comfy admin              |
| [15 Docker Vite dev](./15-docker-vite-dev.md)                | Replace webpacker container with vite (phased)       |
| [16 SCSS → Tailwind](./16-scss-to-tailwind-migration.md)     | Wave-by-wave plan to retire legacy SCSS entirely      |


*Updated July 2026*
