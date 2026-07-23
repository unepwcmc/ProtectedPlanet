# 01 — Discovery and inventory

| | |
|---|---|
| **Estimate** | 2–3 weeks · ~0.5–0.75 month |
| **Depends on** | Nothing |
| **Blocks** | All other phases |
| **Rails 5.2?** | **Yes — start immediately** ([13](./13-work-while-rails-upgrades.md)) |

[← Back to overview](./README.md)

---

## Goal

Document exactly how Rails and Vue connect today so nothing is discovered mid-migration.

**Nav-led baseline:** [01b — Live inventory](./01-live-inventory.md) (pages, ~12 entrypoints, dead components excluded from estimates).

---

## Tasks

### Codebase inventory

- [ ] Grep `app/views` for custom tags: `<v-`, `<search-`, `<chart-`, `<listing-`, `<download`, `<nav-`, `<stats-`, etc.
- [ ] Build a spreadsheet:

  | ERB file | Component | Controller / ivars | HTTP endpoints | Vuex module | CMS pattern (A/B/C) | Entrypoint |
  |----------|-----------|-------------------|----------------|-------------|----------------------|------------|

- [ ] Map `#v-app` in `app/views/layouts/application.html.erb`:
  - What lives in `yield` vs layout-only (`download-modal`, topbar via partials).
- [ ] List globally registered components in `app/javascript/vue.js` (~40).

### High-risk patterns

- [ ] **Slot + Rails partial** (must redesign):
  - `app/views/search_areas/index.html.erb` — `v-slot:download` + `partials/download/download`
- [ ] **Named slots (Vue-only children)** — easier:
  - `app/views/partials/maps/_main.html.erb` — `v-slot:top` / `v-slot:bottom`
- [ ] Props without `:` in ERB (string vs boolean/number), e.g. `chart-row-pa` partial.

### Integration details

- [ ] CSRF + axios: `app/javascript/helpers/axios-helpers.js`, `mixin-axios-helpers.js`.
- [ ] Vuex modules: `download`, `map`, `pame`, `table` in `app/javascript/store/`.
- [ ] `$eventHub` usage across components.
- [ ] Mixins on map/search/table — list files for composable migration sizing.

### External scripts

- [ ] Mapbox CDN 1.4.1 in `layouts/partials/_head.html.erb`.
- [ ] Google Analytics (layout + `vue-analytics` in `vue.js`).
- [ ] Hotjar, cookieconsent, Font Awesome CDN.

### PDF & downloads

- [ ] `@for_pdf` on `#v-app` — PDF layout behaviour.
- [ ] Puppeteer: `lib/modules/download/generators/pdf.rb`, `vendor/assets/javascripts/rasterize*.js`.

### CMS + Vue (see [README](./README.md#cms--frontend-important--read-before-phase-3) · [14](./14-architecture-and-design.md#cms--frontend-integration))

- [ ] List every view that uses **`cms_fragment_render`** on the same page as a Vue custom tag.
- [ ] Assign pattern **A / B / C** per page (definitions in [14](./14-architecture-and-design.md#cms--frontend-integration)).
- [ ] **Pattern B (high priority)** — document target redesign:
  - `app/views/partials/thematic_and_data_area/_tabs.html.erb` — shared `<tabs>`/`<tab-target>` with `slot-scope` + `cms_fragment_render` + per-tab extras (search/map/filtered-table); drives `data/wdpca`, `data/gdpame`, `thematic/effectiveness`
  - `app/views/data/gdpame/index.html.erb` + `_tab_content.html.erb` — tabs + `filtered-table` + `pame-modal`
- [x] **Pattern C:** ~~`app/views/cms/_child_dropdown.html.erb`~~ — deleted, was orphaned (never rendered by any CMS layout)
- [x] `app/views/partials/tabs/_tabs-equity.html.erb` + `layouts/cms/_equity` — deleted, dead code (no CMS layout used them; **Removed Jul 2026**)
- [ ] **Pattern A + Vue listing:** `layouts/cms/_resources.html.erb`, `_news-and-stories.html.erb` — `listing-page` + CMS hero
- [ ] Comfortable Mexican Sofa — spot-check **production** body HTML for accidental `<v-` / `<chart-` tags (seeds look clean).
- [ ] Confirm plan rejects **global mount-all-widgets** / `window.cmsData` for entire site.
- [ ] Map each **Comfy layout** in `db/cms_seeds/protected-planet/layouts/` → pattern A/B/C (see [README table](./README.md#comfy-layout-types-from-db_cms_seedsprotected-planet--plan-fit)).
- [ ] Tab-driven pages (`data/wdpca`, `data/gdpame`, `thematic/effectiveness`): document how `ThematicAndDataAreaHelper#thematic_and_data_area_tabs` builds tabs from CMS `tab-title-N`/`tab-content-N` fragments, and how controllers inject per-tab `tab_extras` (search/map/filtered-table) — app hardcodes these extras today.
- [ ] **Gemfile / admin assets** — [12](./12-gemfile-frontend-dependencies.md): `tinymce-rails`, Coffee → JS in Comfy admin.

---

## Deliverables

1. **Migration backlog** — ordered by risk and dependency.
2. **Integration contract** per feature — JSON shape for `data-props` per island.
3. **Entrypoint naming** — e.g. `layout.ts`, `search-areas.ts`, `map.ts`, `stats-country.ts`.
4. Input for [decision checklist](./README.md#decisions-to-lock-early).

---

## Exit criteria

- Every page with interactivity has an owner and a proposed Vite entrypoint name.
- Slot + Rails partial cases have a written redesign (no “figure out later”).
- Every **CMS + Vue** page has pattern A/B/C + entrypoint name (no global widget registry).
- Backend team has a list of endpoints that must stay stable during migration.

---

## Key files to read first

- `app/javascript/vue.js`
- `app/views/layouts/application.html.erb`
- `app/views/search_areas/index.html.erb`
- `app/views/partials/maps/_main.html.erb`
- `config/webpacker.yml`
