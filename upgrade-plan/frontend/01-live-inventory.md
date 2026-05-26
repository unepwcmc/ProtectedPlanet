# 01b — Live pages & components (nav-led inventory)

| | |
|---|---|
| **Method** | Primary nav (`get_nav_primary`) + routes + thematic footer links |
| **Purpose** | Scope the upgrade to **in-use** UI; exclude dead globals and orphan SFCs |
| **Detail tasks** | [01 — Discovery](./01-discovery-and-inventory.md) |

[← Summary](./README.md)

---

## Live pages (from navigation)

### Primary nav (`application_helper#get_nav_primary`)

| Nav item | URL source | Vue? | Notes |
|----------|------------|------|--------|
| About | CMS `about` | Mostly **no** | Static CMS layout |
| News & stories | CMS `news-and-stories` | **listing-page** | Article children = CMS HTML |
| Resources | CMS `resources` | **listing-page** | Many WDPA update child pages = **no Vue** (downloads/HTML) |
| Monthly release news | CMS `monthly-release-news` | Verify layout | Likely static |
| Thematic areas | CMS children (published) | Mixed | See table below |

### Footer links

`resources`, `oecm`, `wdpa`, `about`, `legal` — same as CMS; **legal** = static.

### Rails controllers (not in nav but linked)

| Route / page | Vue entrypoint (target) |
|--------------|-------------------------|
| Home | `home.ts` — map, search-areas-home, ga-link, flickity, counter |
| Site search `/search` | `search-site.ts` |
| PA search `/search-areas` | `search-areas.ts` |
| Country / Region | `stats-country.ts` / `stats-region.ts` — `region-country-pages`, map |
| PA show `/:id` | `protected-area.ts` — attributes, map |
| Compare / PDF country | Map/stats subset — reuse country/PA entrypoints |

### Thematic areas (CMS slug → controller or CMS-only)

| Slug | Rendered by | Vue |
|------|-------------|-----|
| `wdpa` | `wdpa#index` | **tabs** + search + map (`tabs-thematic-area-database`) |
| `oecm` | `oecm#index` | Same pattern |
| `protected-areas-management-effectiveness-pame` | `pame#index` | **tabs** + `filtered-table` |
| `marine-protected-areas` | `marine#index` | Charts (`chart-row-pa`, `am-chart-multiline`) |
| `global-partnership-on-aichi-target-11` | `target_dashboard#index` | `chart-dial`, `target-11-dashboard` |
| `green-list` | `green_list#index` | `am-chart-line`, `chart-row-pa` |
| `equity` | CMS + `tabs-equity` | **tabs**, `select-equity` |
| `connectivity-conservation` | CMS content | **No** (static) |
| `indigenous-and-community-conserved-areas` | CMS content | **No** (static) |
| Equity study sites (~20 children) | CMS HTML | **No** (static articles) |

### Global chrome (every page)

| Component | Entrypoint |
|-----------|------------|
| `nav-burger`, `search-site-topbar` | `layout.ts` |
| `download-modal` | `layout.ts` |
| `banner-banner` | `layout.ts` |

---

## Vite entrypoints (in scope) — **~14**

| Entrypoint | Pages |
|------------|--------|
| `layout.ts` | Global |
| `home.ts` | Home |
| `search-site.ts` | Site search |
| `search-areas.ts` | PA search |
| `map.ts` | Home, PA, country, region, WDPA/OECM tab 1 |
| `stats-country.ts` / `stats-region.ts` | Country / region (or one `stats-pages.ts`) |
| `protected-area.ts` | PA show |
| `thematic-database.ts` | WDPA, OECM |
| `pame.ts` | PAME |
| `marine.ts` | Marine |
| `green-list.ts` | Green List |
| `target-dashboard.ts` | Aichi 11 |
| `equity-tabs.ts` | Equity hub |
| `listing-page.ts` | News + resources index |

**Not separate entrypoints:** ~100+ CMS resource/news/article URLs (static); equity study sites; connectivity / ICCA-style thematic pages.

---

## Components: in use vs dead

### Registered in `vue.js` (55) — used from ERB (root tags)

`nav-burger`, `search-site-topbar`, `search-site`, `search-areas`, `search-areas-home`, `tabs`, `tab-target`, `v-map`, `v-map-header`, `v-map-filters`, `v-map-disclaimer`, `v-map-pa-search`, `region-country-pages`, `attributes-*` (5), `download`, `download-modal`, `listing-page`, `listing-page-card-*`, `filtered-table`, `pame-modal`, `select-equity`, `select-with-content`, `chart-row-pa`, `chart-dial`, `chart-row-target`, `chart-row-stacked`, `am-chart-line`, `am-chart-multiline`, `target-11-dashboard`, `counter`, `flickity`, `ga-link`, `banner-banner`, `sticky-bar`, `tooltip`, `tooltip-second`, `icon-exclamation-circle`, `v-table`, `table-head`, `v-select-searchable`.

### Globally registered but **unused** (remove on upgrade — do not migrate)

| Component | Notes |
|-----------|--------|
| `Carousel`, `CarouselSlide` | Home/themes use **`flickity`** directly |
| `StickyNav` | No ERB tag; no imports from live tree |
| `ChartBar`, `ChartBarSimple` | No template usage |
| `ChartSunburst`, `ChartTreemapInteractive`, `ChartRectangles` | No imports from live components |

`ChartBarStacked`, `ChartRowTarget`, `AmChartPie` are used **only via child imports** (e.g. `StatsDesignations`, `TableRow`, stats cards) — drop global registration; keep as local imports in Vue 3.

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
| `stats-growth` / growth chart | `RegionCountryPages.vue` (ticket #265) |
| Green List `chart-coverage-growth` | Commented in `green_list/index.html.erb` |

---

## Counts (for estimates)

| | Full repo (old plan) | **In scope** |
|--|---------------------|--------------|
| Vue SFC files | ~125 | **~110** (excl. ~10 orphan + growth) |
| Global `vue.js` registrations | 55 | **~46 live** + drop **6 dead** globals |
| Vite entrypoints | “all pages” | **~14** |
| CMS URLs | 127+ seeds | **~15–20 interactive**; rest static HTML |

---

## Vue 2–only npm packages (must replace for Vue 3)

Covered in detail in [04 — Vue 3 + state](./04-vue3-and-state.md#dependency-replacements). Summary for planning:

| Package | Used today | Vue 3 path |
|---------|------------|------------|
| `vue@2.7` | All SFCs | `vue@3` + `@vitejs/plugin-vue` |
| `vue-loader@15` | Webpacker | Remove with Webpacker |
| `vuex@3` | download, map, pame, table stores | **Pinia** |
| `vue-analytics` | `vue.js` (UA IDs per env) | GA4 / GTM (no Vue 2 plugin) |
| `vue-lazyload` | `vue.js` global | `@vueuse/core` or native lazy images |
| `vue2-touch-events` | `vue.js` global | Remove or `@vueuse/gesture` |
| `vue-flickity` | Home/themes carousel (`<flickity>`) | Replace lib (e.g. Swiper) or CSS carousel |
| `vue-demi` | In `package.json` | Remove after Vue 3 (was for dual-version libs) |
| `eslint-plugin-vue@5` | Lint | `eslint-plugin-vue` 9.x + Vue 3 rules |

**Not Vue-specific but tied to Vue 2 era stack** (audit during phase 4):

| Package | Notes |
|---------|--------|
| `scrollmagic` | Scroll animations in charts, sticky bar, table — replace with CSS/`IntersectionObserver` or drop where component is dead |
| `@rails/webpacker` | Removed with Webpacker |
| `babel-polyfill`, `es6-promise`, `url-search-params-polyfill` | Likely droppable on modern browsers |
| `@amcharts/amcharts4` | Stays usable; integration may change — see [06](./06-charts-and-visualisations.md) (amCharts 5 migration is separate) |

Phase **4** estimate includes swapping these packages and retesting affected UI (carousel, analytics, lazyload, touch). Phase **2b** only adds `vue@3` tooling — do not expect Vue 3 components until phase 4.

---

## Phase impact (estimates reduced)

| Phase | Old assumption | Scoped |
|-------|----------------|--------|
| 3 Islands | All ERB tags | **~14 entrypoints**, not 40+ page types |
| 4 Vue 3 | Migrate 125 SFCs | **~110**; drop orphan/dead first |
| 6 Charts | All chart types | **6 live chart families** (+ amCharts in stats) |
| 7 Search/CMS | Every CMS page | **Listings + 6 thematic + equity tabs**; not 127 CMS pages |

---

## Exit criteria (inventory)

- [ ] Confirm `monthly-release-news` layout (Vue or static).
- [ ] Production Comfy check: no `<chart-bar>` / dead tags in CMS HTML.
- [ ] PR to remove dead globals + orphan SFCs (optional prep on Rails 5.2).
