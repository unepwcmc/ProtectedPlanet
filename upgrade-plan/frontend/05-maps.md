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

## Decision required

| Option | Pros | Cons |
|--------|------|------|
| **Mapbox GL v2+** | Same vendor, style URLs may port | Licensing, API changes from v1 |
| **MapLibre** | Open source GL | Migrate off `mapbox://` style URLs; re-test PA polygons, zoom limits, RTL plugin |

Document decision in [README](./README.md#decisions) and [14](./14-architecture-and-design.md).

---

## Tasks

### Build & config

- [ ] Bundle map library via Vite (remove `<script src="mapbox-gl.js">` from layout).
- [ ] Token via `import.meta.env.VITE_MAPBOX_TOKEN` or Rails → `config/vite.rb`.
- [ ] RTL plugin URL update for chosen GL version.

### Architecture

- [ ] Create `MapPage.vue` — composes `VMapHeader`, `VMap`, `VMapFilters`, `VMapPASearch`, `VMapDisclaimer`.
- [ ] `entrypoints/map.ts` — mount `#map-main-app` with `data-props` from controller/presenter.
- [ ] Convert mixins → `useMapInstance`, `useMapLayers`, `useMapPopups`, etc.

### Vue 3 / Map API

- [ ] Popup HTML generation in `mixin-pa-popup.js` — review XSS and Vue 3 lifecycle.
- [ ] Layer visibility toggling — retest after GL upgrade.
- [ ] `VMapPASearch` autocomplete error messages from i18n YAML via props.

### QA scenarios

- [ ] Main explore map (`_main.html.erb`).
- [ ] Header / embedded map (`_header.html.erb`).
- [ ] Marine vs terrestrial style options.
- [ ] PA search autocomplete and popup links.
- [ ] Disclaimer display (embedded + standalone).

---

## Exit criteria

- No Mapbox CDN scripts in `_head.html.erb`.
- Map entrypoint loads on staging/production.
- QA checklist signed off for map journeys.

---

## Reference

- [Mapbox GL JS migration](https://docs.mapbox.com/mapbox-gl-js/guides/) or [MapLibre](https://maplibre.org/maplibre-gl-js/docs/)
- `app/javascript/components/map/default-options.js` — existing style IDs
- [14 — Architecture](./14-architecture-and-design.md) — `map.ts` entrypoint + `MapPage.vue` wrapper
