# 05 — Maps

| | |
|---|---|
| **Estimate** | 4–8 weeks · ~1–2 months |
| **Depends on** | [03](./03-end-runtime-compilation.md), [04](./04-vue3-and-state.md) (partial) |
| **Blocks** | Map-heavy pages sign-off |

[← Back to overview](./README.md)

---

## Goal

Maps work without global `mapboxgl` from CDN v1.4.1. Map logic uses composables. ERB no longer defines map component trees.

---

## Current stack

| Item | Detail |
|------|--------|
| CDN | Mapbox GL **1.4.1** in `layouts/partials/_head.html.erb` |
| Main component | `app/javascript/components/map/VMap.vue` |
| Mixins | `mixin-layers`, `mixin-controls`, `mixin-add-layers`, `mixin-pa-popup`, … |
| Styles | `mapbox://styles/unepwcmc/...` in `default-options.js` |
| Search on map | `VMapPASearch.vue` — POST `/search/autocomplete` |
| ERB | `partials/maps/_main.html.erb`, `_header.html.erb` |

---

## Decision: MapLibre

**Chosen: MapLibre GL JS** (open-source fork, no Mapbox account/licensing dependency). Style URLs
(`mapbox://styles/unepwcmc/...`) need migrating off the `mapbox://` scheme, and PA polygons, zoom
limits, and the RTL text plugin need re-testing against MapLibre's build — track these as the
first tasks below, before wider map work starts.

| Option | Pros | Cons |
|--------|------|------|
| Mapbox GL v2+ | Same vendor, style URLs may port | Licensing, API changes from v1 |
| **MapLibre (chosen)** | Open source GL, no licensing risk | Migrate off `mapbox://` style URLs; re-test PA polygons, zoom limits, RTL plugin |

Recorded in [14](./14-architecture-and-design.md#maps-decision-framework-for-pp).

---

## Tasks

### Build & config

- [x] Bundle **`maplibre-gl`** via Vite (`maplibre-gl/dist/maplibre-gl.css` imported from `useMapInstance.ts`); the CDN `mapbox-gl.js`/`.css` `<script>`/`<link>` tags removed from `_head.html.erb` (Jul 2026) — `mapboxgl` global had zero remaining references once the last Vue2 `VMap` usage (`partials/maps/_main.html.erb`) was deleted.
- [x] `mapbox://styles/unepwcmc/...` style URLs are **not** migrated off the `mapbox://` scheme — instead handled at runtime via the `maplibregl-mapbox-request-transformer` npm package (`Map/Base.vue`), which transforms Mapbox Studio style JSON for MapLibre on the fly. Deliberate: keeps using Mapbox Studio for style authoring without an export step.
- [ ] Token/URL via `import.meta.env.VITE_MAPLIBRE_STYLE_URL` (or equivalent) via Rails → `config/vite.rb` — not needed yet; style URLs are hardcoded in `app/frontend/constants/map.ts`.
- [ ] RTL text plugin URL update for MapLibre's RTL plugin — not yet revisited.

### Architecture

- [x] `Map/Index.vue` (not `MapPage.vue`) composes `MapHeader`, `MapBase`, `MapPanel` (which renders `MapFilter`×N + `MapDisclaimer` internally) + `MapPaSearch` (in the panel's top slot, gated on `type`/autocomplete props being provided and `!isHidden`) — the Vue3 equivalents of `VMapHeader`/`VMap`/`VMapFilters`/`VMapPASearch`/`VMapDisclaimer`.
- [x] Single `frontend_mount "Map"` call replaces both `_main.html.erb` (home, wdpca tab 1, marine, Green List tab — all now on Vue3) and `_header.html.erb` (PA show/country/region, via `showHeader: false`) — no separate `map.ts` entrypoint; `Map` is registered as an island in `layout.ts` like everything else.
- [x] Mixins → composables: `useMapInstance`, `useMapLayers`, `useMapBoundingBox`, `useMapPopups`, `useMapOverlays` (replaces the Vuex `map` module). Shipped first as a Pinia store (`useMapStore`); **retired 2026-08-20** in favour of provide/inject scoped to the `Map/Index.vue` tree — see "Overlay state is tree-scoped, not app-scoped" below.

#### Overlay state is tree-scoped, not app-scoped

`visibleOverlays`/`visibleLayers` are shared between `MapBase` (draws the layers) and
`MapPanel > MapOverlay` (toggles them) — two sibling subtrees of the same
`Map/Index.vue`, and nothing outside it. As a Pinia store that state was an app-wide
singleton outliving any single island mount while the island itself was rebuilt per
map, which produced two separate "the highlighted area disappeared" bugs (see
`upgrade-plan/backend/CARRYOVER.md` §8y and its follow-up) — each patched with a
manual `reset()` plus a resync-on-init.

`composables/useMapOverlays.ts` replaces it: `Map/Index.vue` calls
`provideMapOverlays()`, `MapBase`/`MapOverlay` call `useMapOverlays()`. Every mount
gets its own state, so there is nothing stale to reset, and two maps on one page no
longer share one global. `useMapOverlays()` **throws** outside a `Map/Index.vue` tree
rather than falling back to a private instance — the silent-fallback version of that
mistake is what made the original bugs hard to find. Tests mounting `MapBase`,
`MapPanel` or `MapOverlay` standalone pass a context via `global.provide`.

Baselayer selection did not need shared state at all: `MapBase` owns the ref (it is
what swaps the MapLibre style) and `MapBaselayerControls` is a `v-model` picker for it.


### Vue 3 / Map API

- [x] Popup HTML generation ported to `useMapPopups.ts` (click-to-query) — plain template strings, same escaping behaviour as the legacy mixin (attribute values are trusted backend data, not user input).
- [x] Layer visibility toggling retested — `useMapLayers` + `useMapOverlays().visibleLayers` watcher in `Base.vue`, covered by Vitest.
- [x] `MapPaSearch.vue` (not `VMapPASearch`) — autocomplete error messages/placeholder threaded through `MapProps`/`map_yml` from Rails, same as the legacy component.
- [x] A map mounted inside a CSS-hidden inactive tab (`.tab__target { display: none }` — wdpca/Green List tab extras still render via the **legacy Vue2** `<tabs>`/`<tab-target>` slot-scope pattern, since they have `tab_extras`; see `_tabs.html.erb`) now resizes itself via an `IntersectionObserver` in `Map/Base.vue` once its container gets a real layout box — replaces the legacy `TabTarget.vue`'s `$eventHub.emit('map:resize')`, decoupled from that specific Vue2 component.

### QA scenarios

- [x] Main explore map (was `_main.html.erb`) — home, wdpca tab 1, marine, Green List tab all verified rendering the right `type`/overlays/autocomplete props via curl smoke test (Jul 2026); PA-search + tab-resize behaviour covered by Vitest, not yet manually verified in a real browser.
- [x] Header / embedded map (was `_header.html.erb`) — PA show/country/region, `showHeader: false`.
- [ ] Marine vs terrestrial style options — not re-verified visually.
- [ ] PA search autocomplete and popup links — unit-tested; not yet manually verified end-to-end (needs Elasticsearch-backed `/search/autocomplete` data).
- [x] Disclaimer display (embedded + standalone) — `MapPanel` renders `MapDisclaimer` internally for both.

---

## Exit criteria

- [x] No Mapbox CDN scripts in `_head.html.erb`.
- [x] Map entrypoint loads (dev-verified via curl on home/wdpca/marine/effectiveness; not yet staging/production).
- [ ] QA checklist signed off for map journeys — automated coverage in place, manual/product sign-off still pending.

---

## Reference

- [MapLibre GL JS docs](https://maplibre.org/maplibre-gl-js/docs/) — chosen library
- [Mapbox → MapLibre migration guide](https://maplibre.org/maplibre-gl-js/docs/guides/migrate-to-maplibre/)
- `app/javascript/components/map/default-options.js` — existing style IDs
- [14 — Architecture](./14-architecture-and-design.md) — `map.ts` entrypoint + `MapPage.vue` wrapper
