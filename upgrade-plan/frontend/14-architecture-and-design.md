# 14 — Architecture & design (Protected Planet–specific)

| | |
|---|---|
| **Purpose** | Target design **without** copying other WCMC apps |
| **Authority** | This repo’s constraints: CMS HTML, SEO, `#v-app`, 125 SFCs, Mapbox CDN |

[← Summary (stakeholders)](./README.md) · task list & estimates in README only

Official/external references to use instead of sister repos:

| Topic | Reference |
|-------|-----------|
| Vite + Rails | [vite_rails](https://vite-ruby.netlify.app/) / [vite-plugin-rails](https://github.com/ElMassimo/vite-plugin-rails) |
| Vue 3 migration | [Vue 3 migration guide](https://v3-migration.vuejs.org/) |
| Pinia | [pinia.vuejs.org](https://pinia.vuejs.org/) |
| Vitest + Vue | [Vitest](https://vitest.dev/guide/) + [@vue/test-utils](https://test-utils.vuejs.org/) |
| amCharts 4→5 | [amCharts migration docs](https://www.amcharts.com/docs/v5/) |

---

## Recommended architecture: hybrid “islands”

**Not a full SPA.** Protected Planet is mostly server-rendered pages (Comfortable Mexican Sofa + ERB stats). Only interactive regions need Vue.

```text
┌─────────────────────────────────────────┐
│  Rails layout (ERB) — static chrome      │
│  ├── Sprockets: application.css (SCSS)   │
│  ├── yield: static + mount placeholders  │
│  └── vite_javascript_tag per page group  │
└─────────────────────────────────────────┘
         │ each mount:
         ▼
┌─────────────────────────────────────────┐
│  createApp(FeatureRoot, props).mount(el) │
│  └── .vue tree (build-time only)         │
└─────────────────────────────────────────┘
```

### Why this fits PP (not because other apps do it)

| PP fact | Design consequence |
|---------|-------------------|
| SEO + CMS pages | Keep HTML in Rails; don’t client-render whole pages |
| Today: one `#v-app` root | Split into **many small roots** — fixes Vue 3 runtime compile issue |
| ~125 SFCs | Reuse files; group by **entrypoint**, not one global `vue.js` |
| Downloads span pages | Shared **Pinia** store loaded from `layout` entrypoint only |

### Alternatives considered (rejected for PP)

| Approach | Why not |
|----------|---------|
| Full SPA + vue-router | Fights CMS URLs, SEO, and massive rewrite |
| Inertia.js | Would replace ERB patterns; too large a programme |
| Keep runtime `#v-app` + Vue 3 compiler | Fragile, large bundle, discouraged by Vue team |
| Livewire / Stimulus-only rewrite | Replaces Vue investment; not requested |

---

## Folder layout (vite_rails convention)

```text
app/frontend/
  entrypoints/
    layout.ts          # nav, topbar search, download modal
    search-areas.ts
    map.ts
    stats-country.ts   # optional grouped entrypoints
  components/          # migrate from app/javascript/components/
  composables/
  stores/              # Pinia
  api/                 # axios client + CSRF
  types/
```

Keep `app/assets/stylesheets/` on **Sprockets** initially (phase 8 decision). Vite handles JS + Vue `<style>` only until SCSS migration is agreed.

---

## Passing props from Rails → Vue (preferred pattern)

**Avoid** huge `data-props="..."` attributes (escape bugs, size limits).

**Use** a JSON script block + helper:

```erb
<%# app/views/search_areas/index.html.erb %>
<%= frontend_mount "search-areas",
      entrypoint: "search-areas",
      props: search_areas_vue_props %>

<%# renders: %>
<div id="mount-search-areas"></div>
<script type="application/json" id="props-search-areas">
  <%= raw json_escape(search_areas_vue_props.to_json) %>
</script>
```

```typescript
// app/frontend/lib/readMountProps.ts
export function readMountProps<T>(id: string): T {
  const el = document.getElementById(`props-${id}`)
  if (!el?.textContent) throw new Error(`Missing props: ${id}`)
  return JSON.parse(el.textContent) as T
}
```

Implement `frontend_mount` + `search_areas_vue_props` in a presenter/helper (integration backend — you).

---

## Entrypoint strategy

| Entrypoint | Mounts | Loads on |
|------------|--------|----------|
| `layout.ts` | Nav, topbar search, download modal | Every page |
| `search-areas.ts` | `SearchAreas` | Search areas page only |
| `map.ts` | `MapPage` wrapper | Map partials |
| `listing-page.ts` | `ListingPage` | CMS listing layouts |
| `stats-*.ts` | Chart groups | Country/region/marine (batch by page type) |

**Rule:** one entrypoint per **page type**, not per component — keeps HTTP payload small.

---

## State (Pinia)

| Store | Replaces Vuex | Loaded by |
|-------|---------------|-----------|
| `useDownloadStore` | `download` | `layout.ts` |
| `useMapStore` | `map` | `map.ts` (or layout if needed globally) |
| `usePameStore` | `pame` | `pame.ts` entrypoint |
| `useTableStore` | `table` | pages with `VTable` |

Use **setup stores** + composables for map layer logic (replaces mixins).

---

## Maps (decision framework for PP)

Current: Mapbox GL **1.4.1** CDN, custom styles `mapbox://styles/unepwcmc/...`.

| Option | When to choose |
|--------|----------------|
| **Mapbox GL v2+** (bundled) | Keep existing styles & team Mapbox account; accept license |
| **MapLibre** | Need open-source GL; budget to migrate styles and re-test polygons/zoom |

Evaluate against **PP** acceptance criteria (layer toggles, RTL, PA search, popups) — not another product’s MapLibre pins.

---

## Charts

1. **Custom SVG/D3 components** — port to Vue 3 SFC syntax first (lower risk).
2. **amCharts 4 → 5** — follow vendor migration guide per chart type.
3. Group stats partials under one `StatsPage.vue` per page type to reduce ERB tag sprawl.

---

## CMS + frontend integration

PP uses **Comfortable Mexican Sofa** + ERB, not a single JSON blob that drives all widgets. The upgrade **must not** adopt a global “register every component type on every page” approach.

### Anti-patterns (do not build)

| Anti-pattern | Why |
|--------------|-----|
| `window.cmsData` with every map/chart/tab on all pages | Large JS payload, many unused `createApp` calls |
| Hidden DOM for every CMS block + scrape `outerHTML` into Vue | Works for report-style products; wrong for PP site surface |
| Reintroduce `#v-app` to compile CMS HTML as Vue template | Breaks Vue 3; fragile with editor HTML |
| Vue tags pasted in Comfy WYSIWYG body | Won’t compile unless you ship runtime compiler |

### Pattern A — CMS HTML in ERB only

- `<%= cms_fragment_render(:content) %>` in layout.
- No Vue inside the fragment output.
- **Entrypoint:** none, or only `layout.ts` for global chrome.

### Pattern B — Vue wraps CMS (tabs, complex pages)

**Today:** `<tabs>` + `slot-scope` + `<%= cms_fragment_render %>` + nested partials (map, search).

**Target (pick one per page in discovery):**

1. **Page SFC (recommended for thematic database)**  
   - ERB: `<%= frontend_mount "thematic-database", props: @props %>`.  
   - `ThematicDatabasePage.vue` imports `Tabs`, `SearchAreas`, `MapPage`; tab copy from props or `v-html` per tab.  
   - Nested Vue is a **normal component tree**, not ERB in slots.

2. **CMS as string props**  
   - Rails: `tabs: [{ id: 1, label: "...", bodyHtml: cms_fragment_render(...) }]`.  
   - Vue `Tabs` renders active panel with `v-html` (trusted CMS source only).

3. **ERB-only tab panels, Vue toggles visibility**  
   - Rails renders all panels as `<div id="tab-panel-1">`; lightweight tab controller toggles `hidden`.  
   - No CMS inside Vue compilation.

**Rule:** after migration, **no** `<%= render partial %>` inside Vue `v-slot` (same as search-areas download).

### Pattern C — CMS fragments → Vue props

Example: `cms/_child_dropdown.html.erb` builds options from fragments → `<select-with-content :options="...">`.

**Target:** `frontend_mount` + JSON props; component in `layout.ts` or page entrypoint.

### Vue inside CMS HTML (editor content)

| Approach | Use |
|----------|-----|
| **Discourage** | Default: editors use layouts/partials, not component tags in body |
| **Comfy snippets** | Snippet renders `frontend_mount` server-side in preview/publish pipeline |
| **Allowlist scan** | Post-process HTML for approved mount IDs (heavy; last resort) |

Phase 1: spot-check **production** Comfy pages for accidental `<chart-` / `<v-` in body HTML.

### Lazy mount (optional, per entrypoint)

For maps/charts below the fold on a **single page**:

```typescript
// app/frontend/lib/mountWhenVisible.ts — use only in that page's entrypoint
export function mountWhenVisible(el: HTMLElement, mount: () => void) {
  const io = new IntersectionObserver(([e]) => {
    if (e.isIntersecting) { mount(); io.disconnect() }
  })
  io.observe(el)
}
```

Not a global loop over all CMS widget types.

### Entrypoint examples (CMS-heavy pages)

| Page / layout | Entrypoint | Pattern |
|---------------|------------|---------|
| `layouts/cms/_resources` | `listing-page.ts` | Vue only; CMS in ERB hero |
| `partials/tabs/_tabs-thematic-area-database` | `thematic-database.ts` | B — page SFC |
| `partials/tabs/_tabs-equity` | `equity-tabs.ts` | B — CMS as `bodyHtml` props |
| `pame/index` | `pame.ts` | B/C — inventory in phase 1 |
| Country/region stats | `stats-country.ts` etc. | CMS copy in ERB; charts in Vue |

### Comfy layout contract (`db/cms_seeds/protected-planet`)

| Layout seed | Role of fragments | Vue integration |
|-------------|-------------------|-----------------|
| `template-thematic-area-database` | `tab-title-*`, `tab-content-*` (wysiwyg), hero fields, optional `tab-show-*` checkboxes | Controller (`wdpa`, `oecm`) builds tab array → mount **one** SFC; wysiwyg → `bodyHtml` |
| `template-thematic-area-basic` | `summary`, `image`, `content` (wysiwyg) | ERB partial only — **pattern A** |
| `template-resource` | `published_date`, `content`, resource file/link fields | ERB partial only — **pattern A** |
| `page-equity` | `tab-title-*`, `tab-content-*` | **pattern B** via `tabs-equity` |
| `page-resources` | listing filters via categories | `listing-page` mount; CMS for hero |

`{{ cms:partial layouts/cms/... }}` in layout seed → `app/views/layouts/cms/_*.html.erb`. Those partials remain Rails; add `frontend_mount` only where Vue is needed.

`render: false` on `{{ cms:text }}` / `{{ cms:wysiwyg }}` means editors manage copy in admin; developers pull values in helpers/controllers — unchanged after upgrade.

---


## Events (replace `$eventHub`)

| Old | New |
|-----|-----|
| `Vue.prototype.$eventHub` | Pinia action, `mitt` for leaf cases, or props/emits inside subtree |

No global event bus in Vue 3.

---

## Local spikes (while Rails &lt; 7)

Use a **sandbox inside this repo**, not another application:

```text
frontend-spike/          # optional folder on a branch
  package.json           # vite + vue3 only
  src/MapLibreTrial.vue
  src/AmCharts5Trial.vue
```

Or Vitest tests with mocked DOM for composables. Do **not** require cloning other WCMC frontends.

---

## Documentation to add in PP repo (after phase 2)

- `docs/frontend-architecture.md` — link to this file’s decisions
- `docs/frontend-mount-props.md` — helper contract
- Page table: URL → entrypoints → components

---

## Exit criteria

- [ ] Team agrees islands + JSON script props (not `#v-app`, not huge `data-*` attrs).
- [ ] Entrypoint list matches [01](./01-discovery-and-inventory.md) inventory.
- [ ] Map and chart choices recorded with PP-specific acceptance tests.
- [ ] Every CMS+Vue page has pattern **A/B/C** and no mount-all-widgets design.
- [ ] Thematic/equity tabs work without ERB inside Vue slots.
