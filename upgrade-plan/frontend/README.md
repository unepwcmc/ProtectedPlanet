Total around 6 months for frontend if no surprises then it can be shorter to 5 months

# Protected Planet — Frontend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below


|                     |                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Target**          | Vite 5+ · Vue 3 · island mounts (Rails 7/8 desirable but **not required** for the frontend — see gates)                          |
| **Now**             | Rails 5.2 · Ruby 2.6.3 · Node 12 · Webpacker · `#v-app` · Vite 2 spike ✓                                                        |
| **Owner**           | Frontend (+ Vite/ERB integration, Comfy admin JS)                                                                               |
| **Not in estimate** | Backend Rails 5→8 · CMS redesign                                                                                                |
| **Scope**           | **[Live inventory](./01-live-inventory.md)** — nav-led; ~12 entrypoints; dead code + **Vue 2–only npm** replacements in phase 4 |
| **Real gates**      | **Ruby 2.7+** (for `vite_rails` 3.x) + **Node 18+** (for Vite 5) — *not* Rails 7. See [Version gates](#version-gates--execution-order) |


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
| 7   | Search & CMS UI          | Listings + wdpca/gdpame/marine/effectiveness/equity (not 127 CMS URLs) | 3–6 wk (~0.75–1.5 mo)    | [07](./07-search-listings-downloads.md)                                   |
| 8   | Styles & Sass            | Dart Sass; drop sassc / Webpacker CSS                                  | 3–5 wk (~0.75–1.25 mo)   | [08](./08-styles-and-assets.md)                                           |
| 9   | Testing                  | Vitest; Playwright on **live page list**                               | 2–4 wk (~0.5–1 mo)       | [09](./09-testing-and-qa.md)                                              |
| 10  | Release                  | Deploy vite build; PDF smoke                                           | 2–3 wk (~0.5–0.75 mo)    | [10](./10-deploy-and-devops.md)                                           |
|     | **Total — conservative** | AI + normal review; overlap included                                   | **24–34 wk (~6–8.5 mo)** |                                                                           |
|     | **Total — optimistic**   | AI-native; few surprises                                               | **19–27 wk (~5–7 mo)**   |                                                                           |


*Add **+15–25%** on conservative total if the wdpca/gdpame/effectiveness/equity tabs are harder than expected. Phase **2b onward** is gated on **Ruby 2.7 + Node 18+**, not on the Rails major — see [Version gates](#version-gates--execution-order).*

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

Today **one `Dockerfile` (`ruby:2.6.3`, Node 12), one `package.json`, one shared `node_modules`** serve `web` + `webpacker` + `vite`. Bumping Node to 18+ breaks Webpacker 4 (webpack 4's `md4`/OpenSSL 3 error, `ERR_OSSL_EVP_UNSUPPORTED`).

**Good news:** this app does **not** use `node-sass` (SCSS compiles Ruby-side via `sassc`/`sass-rails`), so the only fix needed to keep Webpacker 4 alive on modern Node is one flag on the **webpacker service only**:

```
NODE_OPTIONS=--openssl-legacy-provider
```

With that, a single bumped Node (24 LTS) runs **both** Webpacker 4 (Vue 2, with the flag) and Vite 5 (Vue 3) during the migration overlap. Expect minor `yarn install` peer-dep friction, but no native-module wall. Use **Node 24 LTS**, not 26 (26 is not LTS until ~Oct 2026).

### Recommended execution order (constrained path — current Ruby/Rails)

1. **Delete genuinely-dead code now** (safe on Rails 5.2): orphan `.vue` files, dead globals (`ChartDial`, carousel, sunburst/treemap/bar), `leaflet`, polyfills — [01](./01-live-inventory.md), [13](./13-work-while-rails-upgrades.md).
2. **Add Vite as a Docker dev service alongside Webpacker** (dual bundler, already spiked) — [15](./15-docker-vite-dev.md).
3. **Ruby 2.6.3 → 2.7** on Rails 5.2 (rebuild image on `ruby:2.7` base). Unlocks `vite_rails` 3.x.
4. **Node 12 → 24 LTS** in the Dockerfile; add `--openssl-legacy-provider` to the webpacker service.
5. **`vite_rails` 2→3, Vite 2.9→5** + `@vitejs/plugin-vue`.
6. **Migrate Vue 2→3 island by island**; swap each component's Vue2-only deps (vuex→Pinia, vue-analytics→GA4, …) and drop each package once unused — [04](./04-vue3-and-state.md).
7. **Remove Webpacker last** — service, gem, `@rails/webpacker`, config, and the legacy flag together — [03](./03-end-runtime-compilation.md), [15](./15-docker-vite-dev.md) D3.

**Webpack removal is the finish line, not the first step** — it stays until the last Vue component is on Vite. Keep the dual-Node overlap window short.

---

## Detail documents


| Doc                                                          | Contents                                             |
| ------------------------------------------------------------ | ---------------------------------------------------- |
| [00 Scope reference](./00-scope-and-backend-dependencies.md) | You vs backend, B0–B5 milestones (not a gated phase) |
| [01b Live inventory](./01-live-inventory.md)                 | Nav-led pages, entrypoints, dead vs live components  |
| [14 Architecture](./14-architecture-and-design.md)           | Islands, CMS patterns, mounts                        |
| [12 Gems & assets](./12-gemfile-frontend-dependencies.md)    | Gemfile / npm / Sprockets / Comfy admin              |
| [15 Docker Vite dev](./15-docker-vite-dev.md)                | Replace webpacker container with vite (phased)       |


*Updated July 2026*