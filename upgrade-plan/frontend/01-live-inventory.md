# 01b — Live pages & components (nav-led inventory)

| | |
|---|---|
| **Method** | Primary nav (`get_nav_primary`) + `config/routes.rb` + CMS seeds |
| **Purpose** | Scope the upgrade to **in-use** UI; exclude dead globals and orphan SFCs |
| **Detail tasks** | [01 — Discovery](./01-discovery-and-inventory.md) |
| **Verified** | Against code, **July 2026** |

[← Summary](./README.md)

---

## Live pages (from navigation)

### Primary nav (`application_helper#get_nav_primary` → `PageSlugs::NAV_PRIMARY`)

The primary nav is **6 items**. `data` and `thematic-areas` are parent slugs whose children are pulled from the CMS.

| Nav item | Slug | Rendered by | Vue? |
|----------|------|-------------|------|
| About | `about` | Pure CMS (comfy catch-all) | **No** — static CMS |
| News & stories | `news-and-stories` | CMS + `layouts/cms/_news-and-stories` | **listing-page** |
| Resources | `resources` | CMS + `layouts/cms/_resources` | **listing-page** |
| Monthly release news | `monthly-release-news` | Pure CMS | Likely static (verify layout) |
| Data | `data` (parent) | CMS children — see Data table | Mixed |
| Thematic areas | `thematic-areas` (parent) | CMS children — see Thematic table | Mixed |

Footer: `FOOTER_LINKS_PRIMARY = [resources, wdpca]`, `FOOTER_LINKS_SECONDARY = [about, legal]`. `legal` is static CMS.

### Rails controllers (not in nav but linked)

| Route / page | Controller#action | Vue entrypoint (target) | Live components |
|--------------|-------------------|-------------------------|-----------------|
| Home `/en` | `home#index` | `home.ts` | `search-areas-home` (via `partials/search/_protected-areas`), `v-map` (via `partials/maps/_main`), `flickity`, `counter`, `ga-link` |
| Site search `/search` | `search#index` | `search-site.ts` | `search-site` |
| PA search `/search-areas` | `search_areas#index` | `search-areas.ts` | `search-areas` (+ download slot — see high-risk) |
| Country `/country/:iso` | `country#show` | `stats-country.ts` | `region-country-pages`, `v-map` (via `partials/maps/_header`), `tooltip` |
| Region `/region/:iso` | `region#show` | `stats-region.ts` | `region-country-pages`, `v-map` (header) |
| PA show `/:id` | `protected_areas#show` | `protected-area.ts` | `attributes-*` (5), `v-map` (header) |
| Compare / country PDF | `country#compare` / `country#pdf` | reuse country entrypoint | map/stats subset |

### Data pages (`/data/*` — `PageSlugs::Data`)

| Slug | URL | Rendered by | Vue |
|------|-----|-------------|-----|
| `wdpca` | `/data/wdpca` | `data/wdpca#index` | `tabs` + `tab-target` (via `thematic_and_data_area/_tabs`); **tab 1 extras** = `search-areas` + `v-map` (`data/wdpca/_tab_extras`) |
| `global-database-on-protected-area-management-effectiveness` | `/data/global-database-on-protected-area-management-effectiveness` | `data/gdpame#index` | `tabs`; **tab 1** = `filtered-table` (PAME, endpoint `/pame/list`) + `pame-modal` |
| other `data` children | `/data/*` | Pure CMS | static |

### Thematic-area pages (`/thematic-areas/*` — `PageSlugs::ThematicAreas`)

| Slug | URL | Rendered by | Vue |
|------|-----|-------------|-----|
| `marine-protected-areas` | `/thematic-areas/marine-protected-areas` | `thematic/marine#index` | `chart-row-pa`, `am-chart-multiline` (via `_chart-coverage-growth`), `v-map` (`_main`), `flickity`, `counter` — **no tabs** |
| `protected-and-conserved-area-effectiveness` | `/thematic-areas/protected-and-conserved-area-effectiveness` | `thematic/effectiveness#index` | `tabs`; **tab 2** = Green List (`chart-row-pa` + `v-map` via `_green_list_tab`) |
| `oecms` | `/thematic-areas/oecms` | Pure CMS (comfy catch-all) — no controller | **No** (static) |
| `equity` | `/thematic-areas/equity` | CMS layout `layouts/cms/_equity` (marked "TO be removed") | `tabs` (via `partials/tabs/_tabs-equity`). `select-equity` is **commented out** (disabled 14 May 2025) → effectively dead |
| `connectivity-conservation` | CMS content | Pure CMS | **No** (static) |
| `indigenous-and-community-conserved-areas` | CMS content | Pure CMS | **No** (static) |
| `territories-governed-by-indigenous-peoples-and-local-communities` | CMS content | Pure CMS | **No** (static) |
| `green-list` (CMS seed page) | `/thematic-areas/green-list` | Pure CMS seed | Static; the live Green List UI is **tab 2 of `effectiveness#index`**, not this slug |

There is no Aichi Target 11 dashboard, `target_dashboard` controller/route, or `target-11-dashboard` component in the repo. `TabTarget.vue` (`<tab-target>`) is the **tab panel** component of the generic `tabs` widget.

### Tab system (shared)

All tabbed thematic/data pages use **one** reusable pattern, not per-page tab components:

- `partials/thematic_and_data_area/_tabs.html.erb` → `<tabs>` + `<tab-target>` with `slot-scope`.
- Tab list built by `ThematicAndDataAreaHelper#thematic_and_data_area_tabs` from CMS fragments `tab-title-N` / `tab-content-N` (max 5).
- Per-tab "extras" (search, map, filtered-table, green list) injected via a `tab_extras` array of `{ tab_id, partial, locals, replace_content }`.
- Equity uses a **separate** `partials/tabs/_tabs-equity.html.erb` (same `<tabs>`/`<tab-target>` components, hardcoded 2 tabs).

This is a **Pattern B** redesign target (see [14](./14-architecture-and-design.md)): the `slot-scope` + `<%= cms_fragment_render %>` inside `<tab-target>` must become a Vue component tree fed by props.

### Global chrome (every page)

| Component | ERB | Entrypoint |
|-----------|-----|------------|
| `nav-burger`, `search-site-topbar` | `layouts/partials/_topbar` | `layout.ts` |
| `download-modal`, `download` | `layouts/application.html.erb` | `layout.ts` |
| `banner-banner` | `layouts/partials/_banner` | `layout.ts` |

---

## Vite entrypoints (in scope) — **~12**

| Entrypoint | Pages | Key components |
|------------|-------|----------------|
| `layout.ts` | Global | nav-burger, search-site-topbar, download-modal, banner-banner |
| `home.ts` | Home | search-areas-home, v-map, flickity, counter, ga-link |
| `search-site.ts` | `/search` + topbar variant | search-site |
| `search-areas.ts` | `/search-areas` | search-areas + download |
| `map.ts` | Home, PA, country, region, wdpca tab 1, marine, green list | VMap + header/filters/disclaimer/pa-search |
| `stats-country.ts` / `stats-region.ts` | Country / region (or one `stats-pages.ts`) | region-country-pages, tooltip |
| `protected-area.ts` | PA show | attributes-* (5) |
| `data-wdpca.ts` | `/data/wdpca` | tabs + search-areas + map |
| `pame.ts` | `/data/global-database-on-protected-area-management-effectiveness` | tabs + filtered-table + pame-modal |
| `thematic-effectiveness.ts` | `/thematic-areas/protected-and-conserved-area-effectiveness` | tabs + green list (chart-row-pa + map) |
| `thematic-marine.ts` | `/thematic-areas/marine-protected-areas` | chart-row-pa, am-chart-multiline, map |
| `listing-page.ts` | News + resources index | listing-page |

*(`equity` currently has no live interactive component — `select-equity` is commented out — so it needs only `layout.ts` until NC re-enables the chart.)*

**Not separate entrypoints:** `oecms`, `about`, `legal`, `monthly-release-news`, connectivity, ICCA/indigenous, `green-list` CMS seed, equity study sites, and ~100+ CMS resource/news/article URLs (all static HTML).

---

## Components: in use vs dead

### Registered in `vue.js` (46 imports) — used from ERB as root tags

`nav-burger`, `search-site-topbar`, `search-site`, `search-areas`, `search-areas-home`, `tabs`, `tab-target`, `v-map`, `v-map-header`, `v-map-filters`, `v-map-disclaimer`, `v-map-pa-search`, `region-country-pages`, `attributes-*` (5), `download`, `download-modal`, `listing-page`, `listing-page-card-news`, `listing-page-card-resources`, `filtered-table`, `pame-modal`, `select-with-content`, `chart-row-pa`, `am-chart-multiline` (via partial), `counter`, `flickity`, `ga-link`, `banner-banner`, `sticky-bar`, `tooltip`, `tooltip-second` (country stats overview), `v-select-searchable`.

### Registered but **child-import only** — drop global registration, keep as local import

| Component | Imported by | Live? |
|-----------|-------------|-------|
| `ChartRowStacked` | `StatsDesignations.vue` | Live (country/region stats) |
| `AmChartPie` | `StatsGovernance.vue`, `StatsIucnCategories.vue` | Live (country/region stats) |
| `AmChartLine` | `StatsGrowth.vue` | **Disabled** — `StatsGrowth` is commented out in `RegionCountryPages.vue` (ticket #265) |

### Globally registered but **unused** (remove on upgrade — do not migrate)

| Component | Notes |
|-----------|--------|
| `Carousel`, `CarouselSlide` | Home/themes use `flickity` directly |
| `StickyNav` | No ERB tag; no imports from live tree |
| `ChartBar`, `ChartBarSimple` | No template usage |
| `ChartSunburst`, `ChartTreemapInteractive`, `ChartRectangles` | No imports from live components |
| `ChartDial` | **Only imported in `vue.js`** — no ERB tag, no child import → **dead** |
| `SelectEquity` (+ `SelectDropdown`) | **Removed** — only usage (`_tabs-equity`) was commented out (NC decision 14 May 2025); `SelectDropdown` was its only child |

### Orphan `.vue` files (no import found — **~10**, delete or archive)

- `carousel/Agile.vue`
- `charts/chart-line/ChartLegend.vue`, `ChartLineDataset.vue`, `ChartLineTab.vue`, `ChartPopup.vue`
- `form-fields/RadioButtonSearch.vue`
- `map/MapSearch.vue`, `map/MapTrigger.vue`
- `pagination/PaginationMore.vue`
- `pame/SelectedFilter.vue`

### Commented / disabled in code

| Item | Location |
|------|----------|
| `stats-growth` / growth chart (`AmChartLine`) | `RegionCountryPages.vue` (ticket #265) |
| Region marine stats / iucn / governance / designations | commented in `region/show.html.erb` |

---

## Live chart families (for phase 6)

Charts actually rendered on a live page — **4 families**:

| Chart | Where | Type |
|-------|-------|------|
| `chart-row-pa` | Marine, Green List tab | Custom SVG/CSS |
| `am-chart-multiline` | Marine coverage growth (`_chart-coverage-growth`) | amCharts 4 |
| `ChartRowStacked` | Country/region stats (`StatsDesignations`) | Custom |
| `AmChartPie` | Country/region stats (`StatsGovernance`, `StatsIucnCategories`) | amCharts 4 |

`AmChartLine` (growth) is present but disabled (#265). `ChartDial`, `ChartSunburst`, `ChartTreemap*`, `ChartBar*`, `ChartRectangles` are **dead**.

---

## Counts (for estimates)

| | In scope (verified) |
|--|----------------------|
| Vue SFC files | **~110** (excl. ~10 orphan + growth) |
| Global `vue.js` registrations | **46 imports**; drop **~9 dead/child-only** globals |
| Vite entrypoints | **~12** |
| Live chart families | **4** |
| CMS URLs | **~10–15 interactive**; rest static HTML |

---

## Vue 2–only npm packages (must replace for Vue 3)

Covered in detail in [04 — Vue 3 + state](./04-vue3-and-state.md#dependency-replacements). Summary for planning:

| Package | Used today | Vue 3 path |
|---------|------------|------------|
| `vue@2.7` | All SFCs | `vue@3` + `@vitejs/plugin-vue` |
| `vue-loader@15` | Webpacker | Remove with Webpacker |
| `vuex@3` | download, map, pame, table stores | **Pinia** |
| `vue-analytics` | `vue.js` (UA IDs per env — see below) | GA4 / GTM (no Vue 2 plugin) |
| `vue-lazyload` | `vue.js` global | `@vueuse/core` or native lazy images |
| `vue2-touch-events` | `vue.js` global | Remove or `@vueuse/gesture` |
| `vue-flickity` | Home/marine carousel (`<flickity>`) | Replace lib (e.g. Swiper) or CSS carousel |
| `vue-demi` | In `package.json` | Remove after Vue 3 (was for dual-version libs) |
| `eslint-plugin-vue@5` | Lint | `eslint-plugin-vue` 9.x+ + Vue 3 rules |

> **Analytics note:** `vue.js` still uses **Universal Analytics** IDs (`UA-12920389-5` staging, `UA-12920389-2` production). UA was shut down by Google in 2023, so these are already dead — migration must move to **GA4/GTM**, not port the UA config.

**Not Vue-specific but tied to Vue 2 era stack** (audit during phase 4):

| Package | Notes |
|---------|--------|
| `scrollmagic` | Scroll animations — replace with CSS/`IntersectionObserver` or drop where dead |
| `@rails/webpacker` | Removed with Webpacker |
| `leaflet` | **In `package.json` but not imported anywhere** in `app/javascript` — remove |
| `babel-polyfill`, `es6-promise`, `es6-object-assign`, `url-search-params-polyfill` | Droppable on modern browsers |
| `@amcharts/amcharts4` | Stays usable; amCharts 5 migration is separate — see [06](./06-charts-and-visualisations.md) |
| `d3@5` | Audit actual usage — grep `import.*d3`; likely removable |
| `puppeteer@5` | Live PDF path — upgrade in phase 10 |

Phase **4** estimate includes swapping these packages and retesting affected UI (carousel, analytics, lazyload, touch). Phase **2b** only adds `vue@3` tooling — do not expect Vue 3 components until phase 4.

---

## Phase impact

| Phase | Scoped |
|-------|--------|
| 3 Islands | **~12 entrypoints**, not 40+ page types |
| 4 Vue 3 | **~110** SFCs; drop orphan/dead first |
| 6 Charts | **4 live families**; no dial/sunburst/treemap/bar |
| 7 Search/CMS | **Listings + wdpca/gdpame/marine/effectiveness + equity tabs**; not 127 CMS pages |

---

## Exit criteria (inventory)

- [ ] Confirm `monthly-release-news` layout (Vue or static).
- [ ] Production Comfy check: no `<chart-bar>` / dead tags in CMS HTML.
- [ ] Confirm with NC whether `select-equity` / `stats-growth` (#265) will be re-enabled — affects equity + stats scope.
- [ ] PR to remove dead globals (`ChartDial`, carousel, sticky-nav, chart-bar/sunburst/treemap/rectangles) + orphan SFCs (optional prep on Rails 5.2).
