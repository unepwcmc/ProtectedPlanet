# 07 — Search, listings, and downloads

| | |
|---|---|
| **Estimate** | 4–8 weeks · ~1–2 months |
| **Depends on** | [03](./03-end-runtime-compilation.md), [04](./04-vue3-and-state.md) |
| **Blocks** | High-traffic user journeys |

[← Back to overview](./README.md)

---

## Goal

Search, CMS listings, and download flows work without the global `#v-app` root or ERB inside Vue slots.

---

## Features map

| Feature | View | Component | Controller / notes |
|---------|------|-----------|-------------------|
| Site search | `search/index.html.erb` | `SearchSite` | Search controller |
| Topbar search | `_topbar.html.erb` | `SearchSiteTopbar` | In `layout.ts` |
| Area search | `search_areas/index.html.erb` | `SearchAreas` | **Slot + download partial** |
| Home area search | `partials/search/_protected-areas.html.erb` | `SearchAreasHome` | `home_controller` |
| CMS resources | `layouts/cms/_resources.html.erb` | `ListingPage` | `template="resources"` |
| CMS news | `layouts/cms/_news-and-stories.html.erb` | `ListingPage` | `template="news"` |
| Download button | `partials/download/_download.html.erb` | `Download` | Nested in many pages |
| Download modal | `application.html.erb` | `DownloadModal` | Vuex `download` module |
| PAME | `pame/index.html.erb` | `FilteredTable`, modals | Multiple PAME components |

---

## Priority tasks

### 1. Search areas (highest integration risk)

- [ ] Build `search_areas_props` helper in controller or presenter (single hash for `data-props`).
- [ ] `entrypoints/search-areas.ts` + mount `#search-areas-app`.
- [ ] Move download UI into `SearchAreas.vue` using existing `Download.vue` — remove:

  ```erb
  <template v-slot:download="{ downloadDisabled }">
    <%= render partial: "partials/download/download" ... %>
  </template>
  ```

- [ ] Pass `downloadTexts` (button, commercial) via JSON from `t()` / `download_text` helper.
- [ ] Retest: filters, tabs, infinite scroll (`sm-trigger-infinite-scroll`), pagination endpoints.

### 2. CMS listing

- [ ] `listing-page.ts` for CMS layouts.
- [ ] Props: `endpointSearch`, `filterGroups`, `results`, `template` (`news` | `resources`), etc.
- [ ] `ListingPageList.vue` already branches on `template` string — keep behaviour.

### 3. Site search

- [ ] `search-site.ts` for full page + topbar variant.
- [ ] Autocomplete endpoint parity.

### 4. Downloads (global)

- [ ] Pinia store from Vuex `download` module.
- [ ] `#download-modal-app` in layout + `layout.ts` or dedicated entrypoint.
- [ ] `Download.vue` / `DownloadItem.vue` — Vue 3 + still opens modal via store.
- [ ] Poll endpoints: `/downloads`, `/downloads/poll` (from layout modal attrs).

### 5. PAME

- [ ] `pame.ts` entrypoint.
- [ ] `FilteredTable`, `PameModal`, table head mixins → composables.
- [ ] Filter state and GA events.

---

## API / Rails stability

Coordinate with backend — these endpoints must not break during migration:

- `POST /search/autocomplete`
- Search areas results paths (pagination)
- `POST /downloads`, `GET /downloads/poll`
- CMS `/en/search-cms`

---

## Exit criteria

- Search areas and site search pass manual + automated smoke tests.
- Download modal + file download flow works from search and country pages.
- No `v-slot` in ERB under `app/views`.
- PAME index functional on staging.

---

## Reference files

- `app/javascript/components/search/SearchAreas.vue` — slot at line 11
- `app/views/search_areas/index.html.erb`
- `app/javascript/store/_store-download.js`
