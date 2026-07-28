Total around 6 months for frontend if no surprises then it can be shorter to 5 months

# Protected Planet — Frontend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below


|                     |                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Target**          | Vite 7 · Vue 3 · island mounts (Rails 7/8 desirable but **not required** for the frontend — see gates)                          |
| **Now**             | Rails 5.2 · **Ruby 2.7.8 ✓ · Node 24.4.1 ✓ · Vite 7 + vite-plugin-rails ✓** · Webpacker⇄Vite dual bundler ✓ · `#v-app` (Vue 2) intact · **dead code removed ✓** (Wave 0) · first island **Banner ✓** · Tabs island proven · Vitest ✓                                                        |
| **Owner**           | Frontend (+ Vite/ERB integration, Comfy admin JS)                                                                               |
| **Not in estimate** | Backend Rails 5→8 · CMS redesign                                                                                                |
| **Scope**           | **[Live inventory](./01-live-inventory.md)** — nav-led; ~12 entrypoints; dead code + **Vue 2–only npm** replacements in phase 4 |
| **Real gates**      | **Ruby 2.7+** (for `vite_rails` 3.x) + **Node 18+** (for Vite 5) — *not* Rails 7. See [Version gates](#version-gates--execution-order) |


---

## Status — G1 gate done (Jul 2026)

**Done this cycle** (branch `feat/upgrade-frontend`): Ruby 2.6.3→**2.7.8**, Node 12→**24.4.1**, **Vite 7 + `vite-plugin-rails`** (`vite_rails` 3.11.1) running **alongside Webpacker/Vue 2** (dual bundler, cold-start safe). Islands foundation built — `frontend_mount` helper + `readMountProps` + `app/frontend/lib/islands.ts` (registry, lazy Vue, `MutationObserver`), registered in `entrypoints/layout.ts`. **First real island migrated: `Banner`** (lifted out of `#v-app`, on every page). **Tabs island proven** (real `v-if` panels; verified live on wdpca with dummy search/map mounts, then reverted) — confirms hidden / late / nested mounts work with no `v-show`. **Vitest** set up (60 tests, all green — also covers Waves 1–3 below). Everything else still runs under Vue 2 / `#v-app`.

**Also added: Tailwind v4** via Vite (preflight disabled, **additive** alongside the legacy SCSS — not a redesign) for styling new/migrated components. Detail + caveats: [08 Styles](./08-styles-and-assets.md#decision-tailwind-v4--added-additive-july-2026).

**Also done: Wave 1 · simple leaves** (`ga-link`, `counter`, `select-with-content`, `listing-page-card-news`,
`listing-page-card-resources`) — migrated to Vue 3 islands alongside `Banner`. `Counter` dropped its
`scrollmagic` dependency for a native `IntersectionObserver`; `frontend_mount` gained a `key:` option so
repeated-instance components (the two card types, rendered in a loop) each get their own DOM id/props block
while resolving to one registry entry — see [FrontendHelper](../../app/helpers/frontend_helper.rb).

**Also done: Wave 2 · mixin-only leaves** (`tooltip`, `tooltip-second`) — migrated to Vue 3 (`app/frontend/components/Tooltip/Index.vue` → `<Tooltip>`, `Tooltip/Second.vue` → `<TooltipSecond>`). Their only Vue 2 coupling, `mixin-popup-close-listeners`, became `app/frontend/composables/usePopupCloseListeners.ts` (click-outside + Escape-to-close, reusable by later waves — `nav`, `search`, `select` mixins share the same legacy mixin). Registered as islands in `layout.ts` but **not yet wired to a live page**: their current callers (PAME table header's `<tooltip>`, `_stats-overview-country.html.erb`'s `<tooltip-second>`) still run under Webpacker/Vue 2 and haven't reached their own wave (8/10) yet — swap the callers over then.

**Wave 3 · global chrome, in progress:** `nav-burger` (+ `NavDropdown`, `NavLink`) and `search-site-topbar` (+ `SearchSiteInput`) migrated to Vue 3 (`app/frontend/components/NavBar/{Index,Dropdown,Link}.vue`, `app/frontend/components/Search/{SiteTopbar,SiteInput}.vue`). The top-level component is named `NavBar` (not `NavBurger`) since it's the whole nav — pane, link list, and burger trigger — not just the burger button; per the Nuxt folder convention it's `NavBar/Index.vue`→`<NavBar>`, `NavBar/Dropdown.vue`→`<NavBarDropdown>`, `NavBar/Link.vue`→`<NavBarLink>`, matching `Tabs/Index.vue`→`<Tabs>`. `mixin-focus-capture` (Tab-trap accessibility) and `mixin-responsive` (breakpoint tracking, previously broadcast via a global `$eventHub` Vue 3 doesn't need here) became `app/frontend/composables/{useFocusCapture,useBreakpoint}.ts`; `mixin-popup-close-listeners` reused from Wave 2. Legacy `_nav.scss`/`_search-main.scss` kept as-is (unprefixed BEM classes, no `ct-`/Tailwind rewrite) rather than a from-scratch reimplementation — deliberate exception given this is global, every-page chrome where a visual regression has outsized blast radius; revisit once it's proven live. **Wired live:** `_topbar.html.erb` now calls `frontend_mount "NavBar"`/`frontend_mount "SearchSiteTopbar"` directly — no Vue 2 tags left in that partial — and the `_topbar` render moved outside `#v-app` in `application.html.erb` (same as Banner). `get_nav_primary` now returns the raw links array instead of a pre-`.to_json`'d string, since `frontend_mount` serializes props itself. Old Vue 2 `Nav{Burger,Dropdown,Link}.vue`/`SearchSiteTopbar.vue` deleted (zero remaining references); `SearchSiteInput.vue` kept since un-migrated `SearchSite.vue` still uses it. Along the way, found+fixed a real bug in `app/frontend/lib/islands.ts`: the mount-unwrap logic carried `id`/`dataset` from the `frontend_mount` wrapper onto the real mounted root but silently dropped `class` — would have broken `.topbar__nav`/`.topbar__search` CSS; fixed with a covering test. `search-site` (the full results page, pulls in `Pagination`/`TabsFake`) remains deferred to a later pass given its size. `@vueuse/core` (already used by `pp-data-management-portal`) was added as a dependency (Jul 2026) and `useBreakpoint`/`usePopupCloseListeners` were rewritten on top of it (`useWindowSize`, `onClickOutside`, `onKeyStroke`) — same public API, less hand-rolled listener bookkeeping. It only resolves inside the Vite/Vue 3 build (`vue` → `vue3` alias); `vitest.config.mts`'s `server.deps.inline` needed `/@vueuse\//` added alongside the existing `@vue/test-utils` entry so its internal `import ... from 'vue'` goes through the same alias instead of resolving the real Vue 2.7 package. `onClickOutside` also briefly guards against double-firing on rapid clicks (touch+click protection) — `Tooltip`/`TooltipSecond`/`NavBar`'s "closes when clicking outside" tests needed a macrotask tick (`await new Promise(resolve => setTimeout(resolve, 0))`) between the trigger click and the outside click to account for it.

**Status note (Jul 2026):** the prose above undersells where things actually are — Waves 4–6 are done in code even though this file hadn't caught up. `useDownloadStore`/`useMapStore` (Pinia), `Download`/`DownloadModal`, `Listing` (news/resources), and `Map` (home/PA-show/country/region + wdpca/marine/Green List) are all live via `frontend_mount`. **Wave 6 (maps) completed this session:** `MapPaSearch.vue` (Vue3 port of `VMapPASearch`+`Autocomplete`, reusing the legacy `.v-map-pa-search`/`.autocomplete__*` SCSS as-is) now renders inside `Map/Index.vue`'s panel top slot, wired to `Map/Base.vue`'s exposed `zoomTo` (jump-to-result + open a name-only popup via `useMapBoundingBox`'s `onPopupFromExtent` callback + `useMapPopups.addPopup`). This closed the last three `partials/maps/_main.html.erb` call sites (`home`, `data/wdpca` tab 1, `thematic/marine`, `thematic/effectiveness`'s Green List tab) — that partial and the entire dead `app/javascript/components/map/` Vue2 tree (`VMap*`, its mixins) are deleted, along with the now-unused Mapbox CDN `<script>`/`<link>` tags in `_head.html.erb` (MapLibre's own bundled CSS was already imported via Vite). Also fixed: a map mounted inside a CSS-hidden (`display: none`, not `v-if`) inactive tab — the wdpca/Green List `tab_extras` still render through the **legacy Vue2** `<tabs>`/`<tab-target>` slot-scope path, since `_tabs.html.erb` only uses the new Vue3 `Tabs` island when a page has no `tab_extras` — now resizes itself via an `IntersectionObserver` in `Map/Base.vue` once its container gets a real layout box, replacing the legacy `TabTarget.vue`'s `$eventHub.emit('map:resize')`. Verified via `yarn typecheck`/`vitest` (172 tests green) and a dev-server curl smoke test confirming correct props on all four pages; not yet checked in a real browser or on staging. Detail: [05 Maps](./05-maps.md).

**Wave 7 (search areas) completed this session:** `search-areas` (the full filterable/paginated PA search results page) and `search-areas-home` (the input-only autocomplete box, shared by the home page and the wdpca tab_extras) are both live via `frontend_mount`. All ~15 supporting Vue2 leaves (`FilterTrigger`, `FiltersSearch`/`vFilter`, `Checkboxes`/`RadioButtons`/`CheckboxSearch`, `TabsFake`/`TabFake`, `CardSearchResultArea`, `PaginationInfinityScroll`, plus the legacy `Download.vue`) were ported to Vue3, colocated under `app/frontend/components/SearchAreas/` — mirroring the Wave 5 `Listing/` precedent (feature-scoped copies, not a shared top-level `Filters`/`Pagination` folder) rather than the module-per-mixin split originally sketched for this wave. `$eventHub` broadcasts (`reset:filter-options`, `reset:pagination`) became a `resetKey` counter prop threaded down each tree (same pattern as `Listing/Checkboxes`); `scrollmagic` in `PaginationInfinityScroll` was replaced with `IntersectionObserver` (as in `Counter`/`Listing/PaginationInfinityScroll`); axios/`mixin-axios-helpers` replaced with `lib/http.ts`. The `v-slot:download` + `partials/download/download` ERB-slot pattern is gone — `SearchAreas/Index.vue` now composes the Vue3 `Download` island directly and calls `useDownloadStore()` itself, so the temporary `window.__downloadStoreBridge` (Wave 4) and the legacy Vue2 `Download.vue` are both deleted. `search_areas_controller.rb`/`home_controller.rb`/`data/wdpca_controller.rb` now hand `frontend_mount` plain Ruby hashes instead of pre-`.to_json`'d strings, matching every other island. Along the way, found+deleted the orphaned Vue2 `ListingPage.vue`/`ListingPageList.vue` (dead since the Wave 5 `Listing` island shipped, still imported in `vue.js` with no ERB tag left). `TabsFake.vue`/`TabFake.vue` were briefly deleted then restored — `SearchSite.vue` (deferred Wave 3) still imports the **legacy** copies (`RegionCountryPages` no longer does, see Wave 8 below), so both Vue2 and Vue3 `TabsFake` trees coexist until `search-site` lands. Verified via `yarn typecheck`/`yarn lint`/`vitest` (210 tests green, 40 new) and dev-server curl smoke tests on `/search-areas`, `/` (home), and `/data/wdpca` confirming correct props/mounts; Webpacker recompiles clean. Not yet checked in a real browser or on staging.

**Follow-up (same day): `Listing`/`SearchAreas` overlap extracted into `app/frontend/components/Filters/`.** Diffed every same-named `Listing`/`SearchAreas` sibling pair — `FilterTrigger`, `Checkboxes/{Index,Item}`, and `PaginationInfinityScroll` turned out to be byte-identical (only cosmetic style differences), so they moved to a shared `Filters/{Trigger,Checkboxes/{Index,Item},PaginationInfinityScroll}.vue` used by both `Listing/` and `SearchAreas/`. `FilterGroup.vue`/`FiltersPanel.vue` were left colocated per-feature since they genuinely differ (`Listing`'s is checkbox-only with a nested `filter` prop; `SearchAreas`'s supports checkbox/radio/checkbox-search with flat props and its own resetKey-merge logic) — merging those would mean one component juggling two feature sets via conditionals. Added a shared `FilterOption` type in `types/backend.ts`. `SearchAreas`'s `smTriggerElement` prop was renamed to `triggerClass` on the shared pagination component (it's just a CSS class). Consolidated duplicate Vitest suites into `Filters/__tests__/`; 210 tests → 201 after removing exact duplicates, all green; `yarn typecheck`/`yarn lint` clean.

**Wave 8 (charts + stats) completed this session:** `region-country-pages` (country/region `#show` stats block) and its custom-chart family (`chart-row-pa`, `chart-row-stacked`) are live via `frontend_mount`; amCharts stay on **amCharts 4** for now (a v5 port is a separate follow-up, not bundled into this wave). New: `RegionCountryPages/Index.vue` (composes `Stats/{Coverage,Message,IucnCategories,Governance,Sources,Designations,Sites}.vue`), reusing the Wave 7 `SearchAreas/TabStrip` island directly for the WDPA/WDPA+OECM database switcher rather than a duplicate copy (it's generic, not SearchAreas-specific) — `RegionCountryPages.vue` no longer imports the legacy `TabsFake.vue` at all. `ChartRowPa`/`ChartRowStacked`/all `Stats/*` components keep their **legacy unprefixed BEM classes** (`card--stats-*`, `chart--row-pa`, `list--underline*`, …) as a deliberate `ct-`-convention exception (README point 4) — same precedent as `ListingPageCard`: the SCSS (tooltip-arrow mixins, `nth-child` colour cycling for designation bars) is too deep to safely rewrite in this pass. `AmChart/{Pie,Multiline}.vue` port the amCharts4 wrapper components to `<script setup lang="ts">` (template refs instead of global DOM ids, `onUnmounted` disposal) without touching the charting library itself. The legacy `related_countries` Vue2 slot (country page only) is gone — `frontend_mount` has no slot-content equivalent, so `country_controller`'s view renders `partials/stats/stats-related-countries` to a string and passes it as `relatedCountriesHtml`, rendered with `v-html` (Pattern B "CMS as string props"). The WDPA/OECM info tooltips in `_stats-overview-country.html.erb` are wired live for the first time — `StatsTooltipInfo.vue` wraps the already-built `TooltipSecond`/`IconExclamationCircle` (closing out the Wave 2 "component built, never wired" note) since the description/designations-count copy that used to live in ERB `<template #content>` slots has to come in as props instead. `chart-row-pa`/`chart-coverage-growth` partials (marine ocean coverage, Green List tab, marine growth chart) now call `frontend_mount` per chart directly (with `key:` for the marine page's two side-by-side bars) rather than wrapping the whole partial in a page-level component — title/legend/CMS content stay plain ERB since only the bar/chart itself is dynamic. Along the way, found+fixed two real bugs: `Thematic::MarineController`'s growth-chart cache stored a pre-`.to_json`'d string (would have double-encoded once handed to `frontend_mount`'s own `.to_json` — fixed to cache the plain Hash, matching every other Wave 7+ controller); and the designations jurisdiction tooltip read `jurisdiction.link_title`, a key `CountriesHelper#chart_link` never produces (it merges `title`), always rendering an empty `title` attribute — fixed to `jurisdiction.title`. `StatsIucnCategoriesProps`/`StatsGovernanceProps` are picked from the raw TabPresenter hash (which also carries an unused `country` key) rather than `v-bind`-spread wholesale, so `country` doesn't leak onto the DOM as a stray attribute. Verified via `yarn typecheck`/`yarn lint`/`vitest` (226 tests green, 25 new) and dev-server curl smoke tests on `/country/USA`, `/region/AF`, `/thematic-areas/marine-protected-areas`, and `/thematic-areas/protected-and-conserved-area-effectiveness` confirming correct mounts/props (including the fixed growth-chart JSON shape); not yet checked in a real browser or on staging.

**Follow-up (same day): point 20 (`props.xxx` in templates) retrofitted across Wave 8.** The `Stats/*`/`Chart/*`/`AmChart/Pie.vue`/`RegionCountryPages/Index.vue` components landed in Wave 8 with `props.title`/`props.chart`/etc. littered through their templates instead of the bare prop name point 20 requires (`<script setup>` exposes every declared prop directly to the template's render context, so the `props.` prefix is only needed inside `<script setup>` itself). Fixed across all of them; `defineProps<T>()`'s return value was dropped (no `const props =`) wherever nothing in `<script setup>` needed it anymore, kept where a `computed` still reads `props.*` (`Chart/RowStacked.vue`, `Stats/Coverage.vue`, `RegionCountryPages/Index.vue`). Also removed dead code found along the way: `AmChartPieProps.id` (a leftover from the pre-`<script setup>` `am4core.create(id, ...)` pattern, unused now that `Pie.vue` mounts via a template `ref`) and the redundant `class="am-chart--pie"` passed from `Stats/Governance.vue`/`Stats/IucnCategories.vue` (Vue already falls through a parent `class` onto `Pie.vue`'s own hardcoded-class root). Verified via `yarn typecheck`/`yarn lint`/`vitest` (25 tests green across the touched files).

**Wave 9 (PA show `attributes-*`) completed this session:** all 5 `protected_areas#show` attributes islands (`AttributesParcelsDropdown`, `AttributesProtectedArea`, `AttributesPameList`, `AttributesAffiliations`, `AttributesProtectedAreaSources`) are live via `frontend_mount`, under `app/frontend/components/Attributes/`. The Vue2 `parcelSelectionListener` mixin (`$root.$emit('parcel-selected', ...)`) doesn't survive the split into separate `frontend_mount` apps — no shared `$root` across islands — so `useParcelSelection` (`app/frontend/composables/useParcelSelection.ts`) replaces it: the `site_pid` URL query param is the single source of truth (`AttributesParcelsDropdown` writes it via `history.replaceState`; every other island re-reads it independently), with a payload-less `window` custom event used only to tell the other islands "something changed, go re-read the URL." Chosen over a shared composable singleton or a Pinia store because the dropdown already half-implemented URL sync, and it's the only option that also gives reload/bookmark/back-button persistence for free. The underlying `Dropdown` UI component (`app/javascript/components/dropdown/Dropdown.vue` + `Options.vue` + `icon/Arrow.vue`) was ported to `app/frontend/components/Dropdown/{Index,Options}.vue` + `Icon/Arrow.vue`, using `defineModel` + the existing `usePopupCloseListeners` composable instead of the legacy `v-click-outside` global directive (now deleted from `app/javascript/vue.js` along with the `$eventHub`-adjacent Vue2 registrations, since Dropdown was its only consumer). Legacy SCSS (`_dropdown.scss`, already `ct-`-namespaced, plus the unprefixed `card--*`/`list--*` Stats-family classes) was kept as-is — same Wave 8 exception, not a redesign. Two latent bugs fixed along the way: `AttributesPames`' fallback read `this.list` instead of `this.pamesAttributesList` (always harmless since the dropdown always sets an initial selection, but wrong regardless), and two sibling files both carried the copy-pasted Options-API `name: "statsAttributes"` (one of them on the wrong component entirely) — both vanish naturally since `<script setup>` has no `name` option. `show.html.erb`'s `sources_attributes_for_current_pa_and_all_parcels` call site was pre-`.to_json`'d before being handed to the (also-`.to_json`-ing) partial — fixed to pass the raw Hash, same double-encoding bug class as Wave 7/8. Verified via `yarn typecheck`/`yarn lint`/`vitest` (254 tests green, 28 new) and dev-server curl smoke tests against a single-parcel PA and a 3-parcel PA in both normal and `for_pdf=true` modes, confirming correct props/mount shapes and no server errors.

**Next:** finish Wave 3 (`search-site`, deferred — still on Vue2, still imports the legacy `TabsFake.vue`); rewrite migrated components onto Tailwind (including the Wave 8 "reuse legacy SCSS" exceptions, once a rewrite is deliberately scheduled); amCharts 4→5 (deferred out of Wave 8); **Wave 10 (PAME)**; Webpacker removed last.

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

> **Status (Jul 2026):** steps **1–5 ✓ done** · step **6 in progress** (`Banner` island ✓, `Tabs` proven, Vitest ✓, dead-code cleanup ✓) · step **7 pending**.

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
(not ported as-is) — see [Code conventions](#code-conventions-vue-3--typescript) below for the full list.

| Wave | Components (ERB tag) | Prereq / why |
|------|----------------------|--------------|
| **0 · Delete dead code first ✓ done** | `chart-dial`, carousel/`carousel-slide`, `sticky-nav`, `chart-bar`/`chart-bar-simple`, `chart-sunburst`/`chart-treemap-*`/`chart-rectangles`, `select-equity`/`select-dropdown`, ~10 orphan `.vue` | Don't migrate the dead — shrinks phase 4. Safe on Rails 5.2. See [01](./01-live-inventory.md). |
| **1 · Simple leaves** (zero coupling) **✓ done** | `banner-banner`, `ga-link`, `counter`, `select-with-content`, `listing-page-card-news`, `listing-page-card-resources` | Establish the Composition-API + Tailwind + composable pattern on the lowest-risk surface. |
| **2 · Mixin-only leaves ⚠️ `tooltip` still not wired live** | `tooltip`, `tooltip-second` | First mixin→composable extractions; no store/bus. **Note:** Vue3 `Tooltip`/`TooltipSecond` exist and are registered as islands. `tooltip-second` is now **wired live** (Wave 8) — `_stats-overview-country.html.erb`'s WDPA/OECM info tooltips render via `StatsTooltipInfo` (a small wrapper composing `TooltipSecond`/`IconExclamationCircle`, since the description/designations copy has to come in as props rather than the old ERB `<template #content>` slot). `tooltip`'s only caller (PAME table header) is still the **old Vue2** tag — swap that whenever Wave 10 (PAME) touches that view. |
| **3 · Global chrome → break `#v-app` ⚠️ mostly done** | `nav-burger`, `search-site-topbar`, `search-site` | mixin→composable, `$eventHub`→`mitt`/emits. Once chrome is islands, **dismantle `#v-app`**. **Note:** `nav-burger`/`search-site-topbar` are done and wired live (`_topbar.html.erb` calls `frontend_mount` directly, old Vue2 nav/search-topbar tags deleted). `search-site` (the full results page, pulls in `Pagination`/`TabsFake`) is still **deferred** — left on Vue 2 given its size; it's now the **only** remaining importer of the legacy `app/javascript/components/tabs/TabsFake.vue` (`RegionCountryPages`, Wave 8, uses the Vue3 `SearchAreas/TabStrip` island instead), which stays alongside the new Vue3 `SearchAreas/TabsFake/` tree until `search-site` lands. |
| **4 · Pinia + downloads ✓ done** | `useDownloadStore` (port Vuex `download`), `download`, `download-item`, `download-csv`, `download-modal` | Set up **Pinia**; downloads span pages (loaded from `layout`). Live via `frontend_mount`; the `window.__downloadStoreBridge` used to bridge from the legacy Vue2 `search-areas` page is gone — `SearchAreas/Index.vue` (Wave 7) calls `useDownloadStore()` directly. |
| **5 · Listings + tabs ✓ done** | `listing-page`, `tabs`/`tab-target`/`tab-trigger` (**`Tabs.vue` proven**) | `$eventHub 'map:resize'`→composable; wire news/resources + a real tab page. Listing (news/resources) and `Tabs` are both live. **Note:** `Tabs` island only replaces `_tabs.html.erb` on pages with no `tab_extras`; pages whose tabs carry `tab_extras` (wdpca/GDPAME/Green List) still run the legacy Vue2 `<tabs>`/`<tab-target>` slot-scope path — closing that gap needs those tab_extras widgets (maps, PAME table, stats) migrated first, which is already tracked as their own waves. |
| **6 · Maps** (phase 5) **✓ done** | `v-map` (+ `-header`/`-filters`/`-pa-search`/`-disclaimer`/`-baselayer-controls`/`-toggler`) | **MapLibre chosen** (see decisions above) + `useMapStore` (Pinia) first. Live on home/PA-show/country/region + wdpca/marine/Green List tabs; legacy `_main.html.erb` partial and the whole Vue2 `VMap*` tree deleted. |
| **7 · Search areas ✓ done** | `search-areas`, `search-areas-home`, `search-areas-input-autocomplete` (+ filters/tabs-fake/pagination leaves) | Live via `frontend_mount`, colocated under `app/frontend/components/SearchAreas/`; separate from the Map PA-search box (Wave 6). The `download` store bridge (deferred from Wave 4) is closed out — `SearchAreas/Index.vue` calls `useDownloadStore()` directly. `search-site` (deferred from Wave 3) is **not** closed out — it's a separate page/component (`SearchSite.vue`) that still imports the legacy `TabsFake.vue`; picks up in its own pass. |
| **8 · Charts + stats ✓ done** | `chart-row-pa`, `chart-row-stacked`, `am-chart-multiline`, `am-chart-pie`, `region-country-pages` (+ `Stats*`) | Custom SVG charts + `region-country-pages`/`Stats*` are live via `frontend_mount` on country/region/marine/effectiveness pages. **amCharts 4→5 deferred** — `AmChartPie`/`AmChartMultiline` were ported to Vue3/TS but kept on amCharts **4**; the v5 migration is a separate follow-up, not bundled into this wave. |
| **9 · PA show — not started** | `attributes-*` (5) | mixin→composable; protected-area page. The page's map/download pieces are already Vue3 (Waves 4/6); only these attribute components remain on Vue2. |
| **10 · PAME — not started** | `usePameStore` (port Vuex `pame`), `filtered-table`, `pame-modal` (+ table subcomponents) | gdpame page. Good opportunity to also wire in the still-unwired `tooltip` from Wave 2 (PAME table header uses it). |
| **11 · Carousel — not started** | replace `flickity` (`vue-flickity`) → Swiper/CSS | affects home + marine hero carousels. No spike done yet on the Swiper/CSS replacement approach. |
| **12 · Finish — not started** | remove `#v-app`, `vue.js`, Vuex, `vue-analytics`/`vue2-touch-events`/`vue-lazyload`, Webpacker + packs | Webpacker removed last, once nothing is left on Vue 2 — blocked on Waves 7–11 above all landing first. |

*Retrofit note: `Banner.vue` and `Tabs.vue` were migrated earlier in **Options API** with global SCSS — bring them in line with the conventions (Composition API + Tailwind) as the reference examples when Wave 1 starts.*

*Wave 0 note: `stats-growth`/`AmChartLine` (growth chart, ticket #265) has been removed — component, registration, and SCSS all deleted from `RegionCountryPages.vue`/`vue.js`.*

---

## Code conventions (Vue 3 / TypeScript)

Binding rules for every component written or migrated from Wave 1 onward. These extend the
"Composition API + Tailwind + composables" note above with the specifics:

1. **TypeScript everywhere.** New/migrated SFCs use `<script setup lang="ts">` — no plain JS.
2. **Types live in `app/frontend/types/`, not inline in components/composables.** Split by who owns
   the shape:
   - **Backend-shaped types → `app/frontend/types/backend.ts`.** Anything shaped by Rails (a
     `frontend_mount` props payload, a serializer's JSON, a controller-built hash) goes here, even
     when only one component currently reads it — a comment above each type says which
     `frontend_mount` call / controller / serializer produces it, so a backend contract change is
     easy to find and update in one place. Example: `MapProps`/`MapBaseProps` (props for
     `frontend_mount "Map"`, and its inner bare-map-instance piece), `MapFilterProps` (one item of
     `@main_map[:overlays]`, from `MapOverlaysSerializer`), `PointQueryService` (one entry of
     `MapHelper::ALL_SERVICES_FOR_POINT_QUERY`).
   - **Frontend-only shared types stay colocated with the module that owns them** — the composable,
     store, or lib file that defines the behaviour around that type — and get imported (`import type
     { X } from '@/composables/useX'`), never copy-pasted. Only promote one of these into
     `app/frontend/types/` if it stops having a single clear owner (e.g. two unrelated features both
     need to define it from scratch). Example: `MapControlsOptions` (`useMapInstance.ts`), `MapLayer`
     (`useMapLayers.ts`), `BoundsUrl`/`ZoomToOptions` (`useMapBoundingBox.ts`), `MapOverlay`
     (`useMapStore.ts`), `MapBaselayer` (`lib/mapDefaultOptions.ts`) — all Map-feature-internal, not
     Rails-shaped, so they stay put even though several of them are imported across multiple Map
     components/composables.
   - **A type that's genuinely local to one component** (never imported elsewhere) can stay defined
     in that file, per point 12 below.
3. **Component naming = Nuxt-style flattened path.** A component's folder path becomes its tag name:
   `app/frontend/components/Chart/Circle.vue` is used as `<ChartCircle />`. Nested folders flatten to
   PascalCase in the order they nest (`Chart/Circle.vue` → `ChartCircle`, not `CircleChart`).
   **Once a component has its own sub-components**, move it into its own folder as `Index.vue` and
   keep its sub-components alongside it there (each already named with its full tag name), instead
   of leaving a flat `Tabs.vue` sitting next to a `Tabs/` folder. `Index.vue` maps to the bare folder
   name: `components/Tabs/Index.vue` → `<Tabs />`, `components/Tabs/TabsTitle.vue` → `<TabsTitle />`.
   This applies from the first sibling on, even with no shared/base component: a family of leaf
   components that only share a name prefix (no bare `<ListingPageCard />` itself) still goes in a
   folder with no `Index.vue` — e.g. `components/ListingPageCard/{News,Resources}/Index.vue` →
   `<ListingPageCardNews />`/`<ListingPageCardResources />` (the mounted list wrapper) and
   `components/ListingPageCard/{News,Resources}/Card.vue` → the individual card, used internally —
   never a flat `ListingPageCardNews.vue` file. (This pair started as a single flat `.vue` file per
   type in Wave 1 — one `frontend_mount` per card in an ERB loop — and was split into `Index`/`Card`
   in a Wave-1 follow-up once a second use case (a `cards` array with one list-level mount) came up;
   see the roadmap memory note.)
4. **CSS is BEM, namespaced `ct-`.** Class names follow `ct-block__element--modifier` (e.g.
   `ct-banner__nav`, `ct-banner-content--is-active`) for any component-scoped classes in new SFCs —
   the `ct-` prefix is enforced by Stylelint (`@namics/stylelint-bem`, `namespaces: ["app", "ct-"]`
   in `stylelint.config.mjs`). Legacy SCSS keeps its existing unprefixed BEM (`chart-circle__label--active`).
   **Reminder for future waves:** `ListingPageCard/{News,Resources}/Card.vue` (Wave 1) kept their
   unprefixed legacy classes (`card__date`, `card__h3`, ...) as a one-off exception because they reuse
   existing shared Webpacker SCSS mixins as-is. That's the exception, not the pattern — don't copy it
   forward. A component migrated from here on writes fresh component-scoped styles and must use the
   `ct-` prefix (`ct-card__date`, not `card__date`), even when its markup/classes started life copied
   from a legacy `.vue` file.
   A sub-component gets its **own** top-level BEM block rather than nesting under the parent's:
   `Banner/Content.vue`'s root is `ct-banner-content`, not `ct-banner__content`.
   **Test-only hook classes may skip the namespace.** When two elements are visually identical and
   only need a stable selector for tests/JS (not a style), add a second, plain (non-`ct-`) class
   purely for that — e.g. `class="ct-banner__nav banner__nav--prev"`, where `ct-banner__nav` carries
   all the `@apply` styling and `banner__nav--prev` exists only so a spec can tell prev from next.
   Never put Tailwind/`@apply` rules on the unnamespaced class.
5. **Shared Tailwind classes live in `app/frontend/styles/shared/<name>.css`, prefixed `tw-shared-`.**
   Reusable utility/component classes (built with `@apply`, custom properties, etc.) that more than
   one component needs go in a dedicated file there, declared with `@utility tw-shared-<name>` (e.g.
   `tw-shared-base-container` in `styles/shared/base.css`) — don't duplicate them per-component or
   inline them ad hoc in a single SFC.
6. **Imports use the `@/` alias, never relative paths.** e.g.
   `import ChartCircle from "@/components/Chart/Circle.vue"`,
   `import { ProtectedArea } from "@/types/backend"` — not `../../../`.
7. **Tailwind inside an SFC `<style>` block needs `@reference "tailwindcss"`.** This project's
   Tailwind entry (`app/frontend/styles/tailwind.css`) is customised (preflight disabled — see
   [08 Styles](./08-styles-and-assets.md#decision-tailwind-v4--added-additive-july-2026)), so
   both `vite.config.mts` and `vitest.config.mts` alias the bare `tailwindcss` specifier
   (exact-match only, via regex — subpaths like `tailwindcss/theme.css` stay untouched) to that
   file. Any `<style>` block using `@apply`/`theme()` starts with:
   ```css
   @reference "tailwindcss";
   ```
   instead of a relative path back to the real entry file.
8. **Tailwind utility classes never sit in the template.** A component's `<template>` only ever
   carries semantic BEM classes (`ct-banner__title`, `ct-banner-content--is-active`, plus state
   toggles bound via `:class="{ ... }"`). Every Tailwind utility backing those classes lives in the
   SFC's own `<style scoped>` block, one rule per BEM class, using `@apply`:
   ```css
   @reference "tailwindcss";

   .ct-banner-content__title {
     @apply mt-0 mb-[0.5em] text-[1.125rem] font-bold leading-[1.3] text-theme-grey-black md:text-[1.25rem];
   }
   ```
   This keeps templates readable (class names describe *what*, not a long utility soup), keeps BEM
   selectors stable for tests that query them directly, and keeps the styling colocated with the
   component like any other scoped CSS. Only actual state flags that Vue needs to toggle (`is-active`,
   `active`, `:class="{ ... }"` bindings) belong in the template — never a raw utility class like
   `flex` or `text-theme-primary`.
9. **One attribute per line once an element has more than one.** Any tag with two or more
   attributes/bindings (including a single `v-if`/`v-for` plus a class) wraps each onto its own line,
   closing `>` on its own line too:
   ```html
   <button
     v-if="hasMultipleBanners"
     class="ct-banner__nav banner__nav--prev"
     @click="previousBanner"
   >
   ```
   A tag with exactly one attribute (e.g. `class="ct-banner__slides"`) can stay on one line.
10. **`defineProps` is assigned to `props`, never destructured.** Use
    `const props = defineProps<BannerProps>()` and reference `props.banners`/`props.signature`
    throughout the rest of `<script setup>` — destructuring props directly loses reactivity outside
    of Vue's opt-in reactive-props-destructure compiler transform, which this project doesn't enable.
11. **Boolean computed values are named `has`/`is` + noun.** e.g. `hasMultipleBanners`, not
    `multipleBanners` or `showNav`.
12. **Always re-declare an imported props type as a local alias before `defineProps<T>()`.**
    Every migrated component must do this:
    ```ts
    import type { ListingPageCardResourcesListProps } from '@/types/backend'

    type ListingPageCardResourcesList = ListingPageCardResourcesListProps
    defineProps<ListingPageCardResourcesList>()
    ```
    rather than `defineProps<ListingPageCardResourcesListProps>()` directly. **This is now a hard
    rule (Jul 2026), superseding the earlier "consistency convention, not a hard requirement" note**
    — passing an imported type straight into `defineProps<T>()` can compile fine at first but the
    Vue SFC compiler surfaces errors on it later (as the type is re-exported/re-shaped across
    changes), so alias it up front rather than fixing it under pressure later.
13. **Use `v-text`/`v-html` instead of `{{ }}` mustache interpolation** for rendering a single
    dynamic value into an element, e.g. `<span v-text="textDownload.title" />` rather than
    `<span>{{ textDownload.title }}</span>` (and `v-html` when the string contains markup, e.g. CMS
    copy). `Download/Modal.vue` is the reference example. Only exception: a string that mixes static
    text with more than one interpolated part (`{{ i + 1 }}. {{ category.iucn_category_name }}`) —
    `v-text` can't express that directly, so either mustaches or a single template-literal expression
    bound via `v-text` (`v-text="\`${i + 1}. ${category.iucn_category_name}\`"`) are fine there.
14. **A static class always goes in a plain `class="..."` attribute, never inside a `:class="[...]"`
    array.** Only genuinely dynamic/conditional classes belong in `:class`, and when both are needed
    on the same element, split them: `class="ct-card"` `:class="{ 'ct-card--link': url }"` —
    not `:class="['ct-card', { 'ct-card--link': url }]"`.
15. **List/single-item split naming extends point 3.** When a component renders a collection and each
    item is its own SFC, the folder's `Index.vue` is the list/collection (owns shared state —
    selection, reset keys, GA aggregation, etc.) and the per-item sibling is named plain `Item.vue`
    (not `<Folder>Item.vue`) — e.g. `Listing/Checkboxes/{Index,Item}.vue`, mirroring how
    `ListingPageCard/{News,Resources}/{Index,Card}.vue` is Index-owns-the-list / per-item-file (there
    the per-item file is `Card.vue`, since that's what a single result renders as). `Item.vue` takes
    the single data item + its own selection state as props and emits a plain `change` event — it
    doesn't know about siblings or the overall selection array; that bookkeeping stays in `Index.vue`.
    Root element tags must match their container (`<ul>` parent → `<li>` item root, not `<div>`/`<p>`).
16. **Prop names are camelCase everywhere — in `defineProps` AND in every parent template's binding.**
    Never kebab-case or snake_case, regardless of how a JSON source names the field:
    `:groupId="id"`, `:preSelected="..."`, `:gaId="..."`, `:filterCloseText="..."` — not `:group-id`,
    `:pre-selected`, `:ga-id`, `:filter-close-text`. This applies project-wide, not per-feature.
    **Exception: native HTML/ARIA/`data-*` attributes on plain (lowercase) elements stay kebab-case**
    (`:aria-expanded`, `:aria-describedby`, `:data-tab-panel`) — those are real DOM attribute names, not
    Vue component props, and camelCasing them would render a nonstandard attribute instead of the real
    one.
17. **Custom event names are camelCase too — in `defineEmits`, every `emit(...)` call, and every parent
    template's listener.** `defineEmits<{ requestMore: [page: number] }>()` /
    `emit('requestMore', ...)` / `@requestMore="..."` — not `'request-more'`/`@request-more`. For Vue's
    colon-namespaced event convention (`update:x`, `toggle:x`), camelCase only the part(s) after the
    colon — the colon itself stays: `update:filterGroup`, `toggle:filterPane`, not
    `update:filter-group`/`toggle:filter-pane`. Applies project-wide alongside point 16 — props and
    events are both camelCase everywhere, no kebab-case left in any component-to-component binding.
18. **Use Vue 3.4+ same-name shorthand for a prop binding whose value is the identically-named
    local variable.** `:title` rather than `:title="title"`, `:accessToken` rather than
    `:accessToken="accessToken"` — the shorthand only applies when the bound identifier and the prop
    name match exactly; anything else (a different expression, a renamed value, a literal) still
    needs the full `:prop="expression"` form. Not currently caught by lint (`yarn lint` passes either
    way) — a manual review point until/unless a rule for it is added. `Map/Index.vue` is the
    reference example.
19. **No direct function calls or inline logic in `v-on`/template expressions — only a bare handler
    name defined in `<script setup>`.** `@click="toggle"` / `@change="onChange"`, never
    `@click="emit('toggle')"`, `@click="$emit('toggle:filterPane')"`,
    `@click="mapStore.updateSelectedBaselayer(layer)"`, `@toggle="show = !show"`, or an inline
    arrow function. Wrap the call (including any `$event`/cast) in a named function in `<script
    setup>` and reference that function bare in the template:
    ```ts
    const onChange = (event: Event) => emit('change', (event.target as HTMLInputElement).checked)
    ```
    ```html
    <input @change="onChange">
    ```
    A handler that just forwards a `$event`/args still needs this wrapper — `@requestMore="onRequestMore"`
    with `const onRequestMore = (page: number) => emit('requestMore', page)`, not
    `@requestMore="emit('requestMore', $event)"`. Calling an existing setup function with a plain
    argument (`@click="select(option)"`, `@click="toggleTooltip(true)"`) is already compliant — only
    calls to `emit`/`$emit`/store methods/refs and inline assignments/arrow functions need wrapping.
    Not currently caught by lint — a manual review point until/unless a rule for it is added.
20. **Reference props bare in the template — never `props.xxx`.** `<span v-text="title" />`, not
    `<span v-text="props.title" />`; `v-if="url"`, not `v-if="props.url"`. This works because `<script
    setup>` exposes every declared prop directly to the template's render context — the `props.`
    prefix (point 10) is only needed inside `<script setup>` itself, where destructuring would lose
    reactivity. Combine with point 18's same-name shorthand for bindings: `:title`, not `:title="title"`
    or `:title="props.title"`. If removing `props.` leaves `defineProps<T>()`'s return value completely
    unused elsewhere in `<script setup>`, drop the `const props = ` assignment too rather than leaving
    an unused variable. Not currently caught by lint — a manual review point until/unless a rule for it
    is added.
*Setup status: all of the above is built and verified (Jul 2026) — `app/frontend/types/backend`, the `@/` alias (`vite.config.mts` + `vitest.config.mts` `resolve.alias`,
`tsconfig.json` `paths`), the `typescript`/`vue-tsc` devDependencies + `yarn typecheck` script, and
the `tailwindcss` bare-specifier alias for point 7 all exist and were confirmed working (a scratch
`@reference "tailwindcss"` + `@apply` component built correctly, then removed). `Banner/Index.vue` +
`Banner/Content.vue` and `Tabs.vue` are the first components retrofitted to these conventions,
including point 8 — their templates carry only `ct-`-namespaced BEM classes, with every Tailwind
utility moved into each component's `<style scoped>` block via `@apply`. `app/frontend/styles/shared/base.css`
now exists, providing `tw-shared-base-container` (point 5) to both `Banner/Index.vue` and `Tabs.vue`.*

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