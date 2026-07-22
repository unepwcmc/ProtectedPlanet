# 03 — End runtime compilation

| | |
|---|---|
| **Estimate** | 6–10 weeks · ~1.5–2.5 months |
| **Depends on** | [02 — Rails + Vite](./02-rails-and-vite-integration.md) |
| **Blocks** | Stable Vue 3 migration |

[← Back to overview](./README.md)

**Prep on Rails 5.2:** slot removal, `frontend_mount` helper — [13](./13-work-while-rails-upgrades.md), [14](./14-architecture-and-design.md).  
**Vite foundation (dual bundler):** now on Rails 5.2 ([02a](./02a-vite-spike-rails-5.md)).  
**Full cutover (Vue 3, drop `#v-app`):** Rails 7+ ([02b](./02-vite-on-rails-8.md#phase-2b--on-upgrade-branch-rails-71)).

---

## Goal

Remove `new Vue({ el: '#v-app' })` and the Vue 2 **full compiler** (`vue/dist/vue.esm`). Rails serves static HTML + mount points; Vite compiles all UI at build time.

---

## Current architecture (problem)

```
application.html.erb
  └── <div id="v-app">
        ├── topbar (nav-burger, search-site-topbar)
        ├── <%= yield %>  ← dozens of <search-areas>, <v-map>, <chart-*>, …
        └── <download-modal>
```

- `app/javascript/vue.js` registers ~40 components globally.
- Inner HTML of `#v-app` is compiled as **one runtime template**.
- Vue 3 does not support this pattern in production.

---

## Target architecture

```
application.html.erb
  ├── topbar mount: #nav-burger-app[data-props]
  ├── <main><%= yield %></main>   ← only page-specific #*-app divs
  ├── footer (static or mount)
  └── #download-modal-app
```

```typescript
// app/frontend/entrypoints/search-areas.ts
const el = document.getElementById('search-areas-app')
const props = JSON.parse(el.dataset.props!)
createApp(SearchAreas, props).mount(el)
```

```erb
<%# app/views/search_areas/index.html.erb — see 14-architecture-and-design.md %>
<%= frontend_mount "search-areas", entrypoint: "search-areas", props: search_areas_vue_props %>
<%= vite_javascript_tag 'search-areas' %>
```

---

## Tasks

### Layout split

- [ ] Remove or empty `#v-app` wrapper around full `yield`.
- [ ] Move `download-modal` to its own mount + entrypoint (or include in `layout.ts`).
- [ ] Keep `@for_pdf` class behaviour on a wrapper if PDF CSS depends on it.

### Entrypoints (from inventory)

| Priority | Entrypoint | Source ERB / component |
|----------|------------|------------------------|
| 1 | `layout.ts` | `_topbar.html.erb` — `NavBurger`, `SearchSiteTopbar` |
| 2 | `listing-page.ts` | `layouts/cms/_resources.html.erb` |
| 3 | `search-areas.ts` | `search_areas/index.html.erb` |
| 4 | `map.ts` | `partials/maps/_main.html.erb` → wrapper `MapPage.vue` |
| 5 | `search-site.ts` | `search/index.html.erb` |
| 6 | `data-wdpca.ts` / `pame.ts` / `thematic-effectiveness.ts` | `partials/thematic_and_data_area/_tabs.html.erb` (shared) → tab-page SFC ([14](./14-architecture-and-design.md#cms--frontend-integration)) |
| 7+ | Per stats/chart partial | Country, region, marine |

### Eliminate ERB ↔ Vue slot coupling

- [ ] **search_areas**: remove `v-slot:download` + Rails partial; render `<Download>` inside `SearchAreas.vue` with texts from mount props ([14](./14-architecture-and-design.md)).
- [ ] **maps**: replace `v-slot:top/bottom` with `MapPage.vue` composing `VMapPASearch` + `VMapDisclaimer`.

### Retire `vue.js`

- [ ] Delete global `components: { ... }` block as features migrate.
- [ ] Remove `import Vue from 'vue/dist/vue.esm'`.
- [ ] Production bundle: `vue.runtime.esm-bundler.js` only (no compiler).

---

## Example: nav-burger (simplest spike)

Use `frontend_mount` + `readMountProps` from [14](./14-architecture-and-design.md).

**ERB** — `app/views/layouts/partials/_topbar.html.erb`:

```erb
<%= frontend_mount "nav-burger",
      entrypoint: "layout",
      props: { links: get_nav_primary },
      html_class: "topbar__nav nav--primary" %>
```

**Entrypoint** — `app/frontend/entrypoints/layout.ts`:

```typescript
import { createApp } from 'vue'
import NavBurger from '@/components/nav/NavBurger.vue'
import { readMountProps } from '@/lib/readMountProps'

document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('mount-nav-burger')
  if (!el) return
  createApp(NavBurger, readMountProps('nav-burger')).mount(el)
})
```

---

## Exit criteria

- No production page requires in-DOM component tags or `#v-app` compilation.
- `app/javascript/packs/application.js` → `vue.js` path unused.
- CI rule (optional): no new `<kebab-component>` tags in ERB without matching entrypoint.

---

## See also

- [04 — Vue 3](./04-vue3-and-state.md) — syntax changes inside migrated SFCs
- [07 — Search & downloads](./07-search-listings-downloads.md) — search_areas detail
