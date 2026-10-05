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

Planned as one entrypoint per page type; **as built** it is one of each:

```text
app/frontend/
  entrypoints/
    application.ts     # the whole island registry
    vitecss.css        # Tailwind + vw-* blocks, a blocking <link>
  components/
  composables/
  constants/
  lib/                 # turboMount, http, pdfReady, ...
  stores/              # Pinia — useDownloadStore only
  styles/              # global/, shared/, views/
  types/               # backend.ts (Rails-shaped props), map.ts, ...
```

`api/` was never created — no axios; see `lib/http.ts` instead. `app/assets/stylesheets/` was planned to stay on Sprockets; the SCSS migration has since completed and only the out-of-scope Comfy CMS admin override remains there.

---

## Passing props from Rails → Vue

**As built:** pass a plain Ruby hash to `turbo_mount`; it serialises to JSON and
arrives as the component's props.

```erb
<%# app/views/search_areas/index.html.erb %>
<%= turbo_mount "SearchAreasPage", props: search_areas_vue_props %>
```

Build the props hash in a presenter/helper/controller, and give the shape a type in
`app/frontend/types/backend.ts` with a comment naming the producing call (see
CODE-CONVENTIONS rule 2a). Hand `turbo_mount` the **hash**, never a pre-`.to_json`'d
string — it serialises itself, so a string gets double-encoded (a bug hit repeatedly
during the migration; see CHANGELOG).

**Note on the original design.** This section previously specified a separate
`<script type="application/json">` props block, precisely to avoid huge
`data-props="..."` attributes (escape bugs, size limits). turbo-mount does inline
the JSON as one HTML attribute, which the 2026-08-17 spike measured at ~65% more
bytes on the wire for a 31 KB payload (and one unreadable line in view-source).
Escaping is correct either way — the payload round-tripped byte-identical — so this
was accepted as a known cost of adopting the library, not an unnoticed regression.
It matters most for the largest payloads: search-areas, PAME and map props.

---

## Mounting mechanism and the turbo-mount decision

**Implemented** — `turbo_mount`, sitewide:

- `<%= turbo_mount "<Name>", props: {...}, html: {...} %>` in the view (helper from the `turbo-mount` gem). Props are a plain Ruby hash, serialised to JSON in a `data-...-props-value` attribute on the host `<div>`, which also carries `data-controller="turbo-mount-<name>"`. Repeated instances of the same component on one page need no extra config — Stimulus gives each matching element its own controller.
- `app/frontend/entrypoints/application.ts` — the name → lazy loader registry. Components rendered on essentially every page are static imports (bundled into the entrypoint chunk); everything else is `() => import(...)`.
- `app/frontend/lib/turboMount.ts` — starts one `TurboMount`, registers a **custom** Vue plugin whose `mountComponent` calls `app.use(pinia)` before `app.mount()` (the stock `turbo-mount/vue` plugin does not, so every Pinia-using island would throw "no active Pinia"), then scans the DOM for host elements actually present and calls only those components' loaders. A `MutationObserver` keeps that scan live.
- `app/frontend/styles/global/turbo-mount.css` — `[data-controller^="turbo-mount-"] { display: contents }`. Stimulus needs the host element to keep its `data-controller`, so the wrapper `<div>` is permanent; `display: contents` keeps it out of the box model. See that file for the residual structural-selector caveat.

**Superseded and deleted (2026-08-20):** the homegrown mounter — `app/helpers/frontend_helper.rb` (`frontend_mount`, which emitted a `<div data-mount>` plus a separate `<script type="application/json">` props block), `app/frontend/lib/readMountProps.ts` and `app/frontend/lib/islands.ts`. It had no call sites left once every view moved to `turbo_mount`. Its one behavioural advantage is gone with it: it replaced its own wrapper with the component's rendered root, so islands left no extra `<div>` — hence the `display: contents` rule above.

**Why the `MutationObserver`:** a host element can enter the DOM *after* first paint — inside a `v-if` region revealed later, nested in another island's `v-html` prop (see `RegionCountryPages`' `relatedCountriesHtml`), or in CMS-injected markup. A one-shot scan would miss those, so `turboMount.ts` keeps observing. Because it does, **`v-if` is safe** (true unmount/remount via Stimulus's own connect/disconnect) and hidden regions never need `v-show` to stay in the DOM — proven live on wdpca, where a Tabs island's search/map mounts appear only when their tab is revealed, then unmount on leave. Turbo Drive is **not** a reason — it was removed (CARRYOVER §8ac).

**`turbo_mount` is the stable seam.** Views only ever call `turbo_mount`; the name → component wiring lives in `application.ts`. Swapping the *mechanism* underneath again would touch that registry and `turboMount.ts`, never the views or the Vue SFCs — though the 2026-08 migration showed that estimate understates it once the mounter grows real behaviour (lazy loading, Pinia wiring, wrapper handling).

### Decision: `turbo-mount` — ADOPTED (2026-08-17); Turbo Drive — REMOVED (2026-08-20)

[`turbo-mount`](https://github.com/skryukov/turbo-mount) (skryukov / Evil Martians, MIT — v0.4.4 Dec 2025) is the "batteries-included" equivalent of our mounter: a `turbo_mount(...)` Rails helper plus a Stimulus controller that mounts React/Vue/Svelte components and manages their lifecycle.

It was originally rejected because the gem declares `required_ruby_version >= 3.0.0` / `railties >= 6.0.0` and we were on Ruby 2.7.8 / Rails 5.2. The backend moved to Ruby 3.3.7 / Rails 8.0.5.1, that gate lifted, and after a spike it was **adopted**: every view now calls `turbo_mount`, wired in `entrypoints/application.ts` through `lib/turboMount.ts` (a custom Vue plugin, so each island's `createApp` gets the shared `pinia`). `frontend_mount`/`islands.ts` were deleted on 2026-08-20 once the last call site was gone.

**These are two separate decisions.** turbo-mount's only runtime dependency is **Stimulus**, which reacts to elements entering and leaving the DOM — it needs nothing from Turbo. Turbo Drive was tried alongside it and **removed** (`@hotwired/turbo-rails` and the `turbo-rails` gem are both gone): its measured benefit was skipping the parse of the eager JS/CSS per navigation, against five production incidents in three days, every one of them state or assets outliving a navigation. Navigation is now an ordinary full document load. See CARRYOVER §8y–§8ac for the incidents and §8ac for what the removal let us delete.

Refs: `turbo-mount.gemspec` · https://github.com/skryukov/turbo-mount

---

## Entrypoint strategy

**As built: two entrypoints, both loaded on every page** (`layouts/partials/_head.html.erb`):

| Entrypoint | Contains | Why |
|------------|----------|-----|
| `vitecss.css` | Tailwind + the `vw-*` block styles + the turbo-mount wrapper rule | A real blocking `<link>`, so it applies before first paint |
| `application.ts` | The whole island registry | One module graph; per-page code-splitting is handled by lazy loaders, not by entrypoint count |

The per-page-type plan above was dropped: `turbo_mount` hosts can appear anywhere (including in CMS content), so the page type is not known at entrypoint-selection time. Payload is kept small the other way instead — only the components whose host elements are actually on the page get their chunk fetched, decided at runtime by `turboMount.ts`'s DOM scan.

---

## State (Pinia)

**As built there is exactly one store:** `useDownloadStore` (`stores/useDownloadStore.ts`, a setup store replacing the Vuex `download` module), used by `Download/*` and `SearchAreas/Page.vue`. It earns its place because the download modal in the layout and the trigger in the page body are separately-mounted islands that must share state. The planned `pame` and `table` stores were not built — that state turned out to live inside a single component tree, so it stayed there.

Pinia is for state that genuinely outlives a single component tree (downloads span
pages). The `map` module was ported to a store and then moved back out (2026-08-20):
every reader and writer lived inside the one `Map/Index.vue` tree, and the store's
app-wide lifetime — outliving any single island mount — caused two "the highlighted
area disappeared" bugs. It is now `composables/useMapOverlays.ts` — provide/inject scoped
to that tree. Default to tree-scoped provide/inject; reach for a store only when two
independently-mounted islands must share state.

---

## Maps (decision framework for PP)

Current: Mapbox GL **1.4.1** CDN, custom styles `mapbox://styles/unepwcmc/...`.

**Chosen: MapLibre GL JS** — open source, no Mapbox account/licensing dependency. Requires migrating
off `mapbox://` style URLs and re-testing layer toggles, RTL, PA search, and popups against PP's own
acceptance criteria (not another product's MapLibre setup). Detail: [05 — Maps](./05-maps.md#decision-maplibre).

| Option | When to choose |
|--------|----------------|
| Mapbox GL v2+ (bundled) | Keep existing styles & team Mapbox account; accept license |
| **MapLibre (chosen)** | Open-source GL; no licensing dependency; budget to migrate styles and re-test polygons/zoom |

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
- **Entrypoint:** none — `application.ts` is loaded on every page and carries the registry.

### Pattern B — Vue wraps CMS (tabs, complex pages)

**Today:** `<tabs>` + `slot-scope` + `<%= cms_fragment_render %>` + nested partials (map, search).

**Target (pick one per page in discovery):**

1. **Page SFC (recommended for thematic database)**  
   - ERB: `<%= turbo_mount "ThematicDatabase", props: @props %>`.  
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

Example (historical — `cms/_child_dropdown.html.erb` was deleted as dead code, never wired into a live CMS page): built options from fragments → `<select-with-content :options="...">`.

**Target:** `turbo_mount` + a props hash; register the component in `application.ts`.

### Vue inside CMS HTML (editor content)

| Approach | Use |
|----------|-----|
| **Discourage** | Default: editors use layouts/partials, not component tags in body |
| **Comfy snippets** | Snippet renders `turbo_mount` server-side in preview/publish pipeline |
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
| `partials/thematic_and_data_area/_tabs` (shared) | `data-wdpca.ts` / `thematic-effectiveness.ts` | B — page SFC |
| `data/gdpame/index` | `pame.ts` | B/C — inventory in phase 1 |
| Country/region stats | `stats-country.ts` etc. | CMS copy in ERB; charts in Vue |

### Comfy layout contract (`db/cms_seeds/protected-planet`)

| Layout seed | Role of fragments | Vue integration |
|-------------|-------------------|-----------------|
| `template-thematic-area-database` (+ `page-database-areas`, `page-pame`) | `tab-title-*`, `tab-content-*` (wysiwyg), hero fields | Controllers `data/wdpca`, `data/gdpame` build tab array via `thematic_and_data_area_tabs` → mount **one** SFC; wysiwyg → `bodyHtml` |
| `template-thematic-area-basic` | `summary`, `image`, `content` (wysiwyg) | ERB partial only — **pattern A** |
| `template-resource` | `published_date`, `content`, resource file/link fields | ERB partial only — **pattern A** |
| `page-resources` | listing filters via categories | `listing-page` mount; CMS for hero |

`{{ cms:partial layouts/cms/... }}` in layout seed → `app/views/layouts/cms/_*.html.erb`. Those partials remain Rails; add `turbo_mount` only where Vue is needed.

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
- [x] ~~Thematic/equity tabs work without ERB inside Vue slots.~~ Moot — equity layout/tabs were dead code, deleted Jul 2026.
