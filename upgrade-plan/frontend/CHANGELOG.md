# Frontend upgrade — detailed changelog

Full wave-by-wave narrative: what shipped, decisions made, bugs found/fixed, and how each wave
was verified. For the current status snapshot, task plan, and coding conventions, see
**[README.md](./README.md)**.

Waves are listed oldest-first; each is otherwise self-contained if you only need one.

---

## Wave 0 — Delete dead code (done)

Removed before Wave 1 so nothing dead gets migrated: `chart-dial`, carousel/`carousel-slide`,
`sticky-nav`, `chart-bar`/`chart-bar-simple`, `chart-sunburst`/`chart-treemap-*`/`chart-rectangles`,
`select-equity`/`select-dropdown`, ~10 orphan `.vue` files, plus the orphaned
`_select-equity.scss`/`_am-chart-line.scss`/`_card-stats-growth-chart.scss`. Landed as `701f6f31` +
a follow-up cleanup commit. Full inventory: [01-live-inventory](./01-live-inventory.md).

`stats-growth`/`AmChartLine` (growth chart, ticket #265) was removed in the same pass — component,
registration, and SCSS all deleted from `RegionCountryPages.vue`/`vue.js` (it was HTML-commented
out, never live).

---

## Wave 1 — Simple leaves (done)

`ga-link`, `counter`, `select-with-content`, `listing-page-card-news`, `listing-page-card-resources`
migrated to Vue 3 islands alongside `Banner`. `Counter` dropped its `scrollmagic` dependency for a
native `IntersectionObserver`. `frontend_mount` gained a `key:` option so repeated-instance
components (the two card types, rendered in a loop) each get their own DOM id/props block while
resolving to one registry entry — see [FrontendHelper](../../app/helpers/frontend_helper.rb).

`ListingPageCard/{News,Resources}` started as a single flat `.vue` file per type (one
`frontend_mount` per card in an ERB loop) and was later split into `Index`/`Card` once a second use
case (a `cards` array with one list-level mount) came up — see
[CODE-CONVENTIONS §3](./CODE-CONVENTIONS.md).

`Banner.vue` and `Tabs.vue` were migrated earlier in Options API with global SCSS, then retrofitted
to the Composition API + Tailwind conventions when Wave 1 started — they're the reference examples
for those conventions (see [CODE-CONVENTIONS.md](./CODE-CONVENTIONS.md), "Setup status" section).

---

## Wave 2 — Mixin-only leaves (done, not fully wired)

`tooltip`, `tooltip-second` migrated to Vue 3
(`app/frontend/components/Tooltip/Index.vue` → `<Tooltip>`, `Tooltip/Second.vue` → `<TooltipSecond>`).
Their only Vue 2 coupling, `mixin-popup-close-listeners`, became
`app/frontend/composables/usePopupCloseListeners.ts` (click-outside + Escape-to-close), reused by
later waves (`nav`, `search`, `select` mixins share the same legacy mixin).

Registered as islands in `layout.ts` but **not wired to a live page at the time** — their callers
(PAME table header's `<tooltip>`, `_stats-overview-country.html.erb`'s `<tooltip-second>`) still ran
under Webpacker/Vue 2. `tooltip-second` was later wired live in Wave 8 (see below); `tooltip`'s only
caller (PAME table header) is still the old Vue2 tag — swap when Wave 10 (PAME) touches that view.

---

## Wave 3 — Global chrome, break `#v-app` (mostly done)

`nav-burger` (+ `NavDropdown`, `NavLink`) and `search-site-topbar` (+ `SearchSiteInput`) migrated to
Vue 3: `app/frontend/components/NavBar/{Index,Dropdown,Link}.vue`,
`app/frontend/components/Search/{SiteTopbar,SiteInput}.vue`.

**Naming:** the top-level component is `NavBar` (not `NavBurger`) since it's the whole nav — pane,
link list, and burger trigger — not just the burger button. Per the Nuxt folder convention:
`NavBar/Index.vue` → `<NavBar>`, `NavBar/Dropdown.vue` → `<NavBarDropdown>`,
`NavBar/Link.vue` → `<NavBarLink>`, matching `Tabs/Index.vue` → `<Tabs>`.

`mixin-focus-capture` (Tab-trap accessibility) and `mixin-responsive` (breakpoint tracking,
previously broadcast via a global `$eventHub` Vue 3 doesn't need here) became
`app/frontend/composables/{useFocusCapture,useBreakpoint}.ts`; `mixin-popup-close-listeners` reused
from Wave 2.

Legacy `_nav.scss`/`_search-main.scss` kept as-is (unprefixed BEM, no `ct-`/Tailwind rewrite) — a
deliberate exception given this is global, every-page chrome where a visual regression has outsized
blast radius. Revisit once it's proven live.

**Wired live:** `_topbar.html.erb` now calls `frontend_mount "NavBar"`/`frontend_mount "SearchSiteTopbar"`
directly — no Vue 2 tags left in that partial — and the `_topbar` render moved outside `#v-app` in
`application.html.erb` (same as Banner). `get_nav_primary` now returns the raw links array instead of
a pre-`.to_json`'d string, since `frontend_mount` serializes props itself. Old Vue 2
`Nav{Burger,Dropdown,Link}.vue`/`SearchSiteTopbar.vue` deleted (zero remaining references);
`SearchSiteInput.vue` kept since un-migrated `SearchSite.vue` still uses it.

**Bug found + fixed:** the mount-unwrap logic in `app/frontend/lib/islands.ts` carried `id`/`dataset`
from the `frontend_mount` wrapper onto the real mounted root but silently dropped `class` — would
have broken `.topbar__nav`/`.topbar__search` CSS; fixed with a covering test.

**Deferred:** `search-site` (the full results page, pulls in `Pagination`/`TabsFake`) remains on
Vue 2 given its size.

**Dependency:** `@vueuse/core` (already used by `pp-data-management-portal`) was added and
`useBreakpoint`/`usePopupCloseListeners` were rewritten on top of it (`useWindowSize`,
`onClickOutside`, `onKeyStroke`) — same public API, less hand-rolled listener bookkeeping. It only
resolves inside the Vite/Vue 3 build (`vue` → `vue3` alias); `vitest.config.mts`'s
`server.deps.inline` needed `/@vueuse\//` added alongside the existing `@vue/test-utils` entry so its
internal `import ... from 'vue'` goes through the same alias instead of resolving the real Vue 2.7
package. `onClickOutside` also briefly guards against double-firing on rapid clicks (touch+click
protection) — `Tooltip`/`TooltipSecond`/`NavBar`'s "closes when clicking outside" tests needed a
macrotask tick (`await new Promise(resolve => setTimeout(resolve, 0))`) between the trigger click and
the outside click to account for it.

---

## Wave 4 — Pinia + downloads (done)

`useDownloadStore` (Pinia, replacing the Vuex `download` module) and `Download`/`DownloadModal` are
live via `frontend_mount`. The `window.__downloadStoreBridge` used to bridge from the legacy Vue2
`search-areas` page was a temporary shim — closed out in Wave 7, when `SearchAreas/Index.vue` started
calling `useDownloadStore()` directly.

---

## Wave 5 — Listings + tabs (done)

`Listing` (news/resources) and `Tabs` are live via `frontend_mount`. **Caveat:** the `Tabs` island
only replaces `_tabs.html.erb` on pages with **no** `tab_extras`; pages whose tabs carry `tab_extras`
(wdpca/GDPAME/Green List) still run the legacy Vue2 `<tabs>`/`<tab-target>` slot-scope path — closing
that gap needs those `tab_extras` widgets (maps, PAME table, stats) migrated first, which is tracked
as their own waves (6, 8, 10).

---

## Wave 6 — Maps (done)

`MapPaSearch.vue` (Vue3 port of `VMapPASearch` + `Autocomplete`, reusing the legacy
`.v-map-pa-search`/`.autocomplete__*` SCSS as-is) now renders inside `Map/Index.vue`'s panel top
slot, wired to `Map/Base.vue`'s exposed `zoomTo` (jump-to-result + open a name-only popup via
`useMapBoundingBox`'s `onPopupFromExtent` callback + `useMapPopups.addPopup`).

This closed the last three `partials/maps/_main.html.erb` call sites (`home`, `data/wdpca` tab 1,
`thematic/marine`, `thematic/effectiveness`'s Green List tab) — that partial and the entire dead
`app/javascript/components/map/` Vue2 tree (`VMap*`, its mixins) are deleted, along with the
now-unused Mapbox CDN `<script>`/`<link>` tags in `_head.html.erb` (MapLibre's own bundled CSS was
already imported via Vite).

**Gotcha fixed:** a map mounted inside a CSS-hidden (`display: none`, not `v-if`) inactive tab — the
wdpca/Green List `tab_extras` still render through the **legacy Vue2** `<tabs>`/`<tab-target>`
slot-scope path, since `_tabs.html.erb` only uses the new Vue3 `Tabs` island when a page has no
`tab_extras` — now resizes itself via an `IntersectionObserver` in `Map/Base.vue` once its container
gets a real layout box, replacing the legacy `TabTarget.vue`'s `$eventHub.emit('map:resize')`.

Verified via `yarn typecheck`/`vitest` (172 tests green) and a dev-server curl smoke test confirming
correct props on all four pages; not yet checked in a real browser or on staging.
Detail: [05 Maps](./05-maps.md).

---

## Wave 7 — Search areas (done)

`search-areas` (the full filterable/paginated PA search results page) and `search-areas-home` (the
input-only autocomplete box, shared by the home page and the wdpca tab_extras) are both live via
`frontend_mount`. All ~15 supporting Vue2 leaves (`FilterTrigger`, `FiltersSearch`/`vFilter`,
`Checkboxes`/`RadioButtons`/`CheckboxSearch`, `TabsFake`/`TabFake`, `CardSearchResultArea`,
`PaginationInfinityScroll`, plus the legacy `Download.vue`) were ported to Vue3, colocated under
`app/frontend/components/SearchAreas/` — mirroring the Wave 5 `Listing/` precedent (feature-scoped
copies, not a shared top-level `Filters`/`Pagination` folder) rather than the module-per-mixin split
originally sketched for this wave.

`$eventHub` broadcasts (`reset:filter-options`, `reset:pagination`) became a `resetKey` counter prop
threaded down each tree (same pattern as `Listing/Checkboxes`); `scrollmagic` in
`PaginationInfinityScroll` was replaced with `IntersectionObserver` (as in `Counter`/
`Listing/PaginationInfinityScroll`); axios/`mixin-axios-helpers` replaced with `lib/http.ts`.

The `v-slot:download` + `partials/download/download` ERB-slot pattern is gone —
`SearchAreas/Index.vue` now composes the Vue3 `Download` island directly and calls
`useDownloadStore()` itself, so the temporary `window.__downloadStoreBridge` (Wave 4) and the legacy
Vue2 `Download.vue` are both deleted. `search_areas_controller.rb`/`home_controller.rb`/
`data/wdpca_controller.rb` now hand `frontend_mount` plain Ruby hashes instead of pre-`.to_json`'d
strings, matching every other island.

**Found + deleted:** the orphaned Vue2 `ListingPage.vue`/`ListingPageList.vue` (dead since the Wave 5
`Listing` island shipped, still imported in `vue.js` with no ERB tag left).

`TabsFake.vue`/`TabFake.vue` were briefly deleted then restored — `SearchSite.vue` (deferred Wave 3)
still imports the **legacy** copies (`RegionCountryPages` no longer does, see Wave 8), so both Vue2
and Vue3 `TabsFake` trees coexist until `search-site` lands.

Verified via `yarn typecheck`/`yarn lint`/`vitest` (210 tests green, 40 new) and dev-server curl
smoke tests on `/search-areas`, `/` (home), and `/data/wdpca` confirming correct props/mounts;
Webpacker recompiles clean. Not yet checked in a real browser or on staging.

### Follow-up: `Listing`/`SearchAreas` overlap extracted into `Filters/`

Diffed every same-named `Listing`/`SearchAreas` sibling pair — `FilterTrigger`,
`Checkboxes/{Index,Item}`, and `PaginationInfinityScroll` turned out to be byte-identical (only
cosmetic style differences), so they moved to a shared
`Filters/{Trigger,Checkboxes/{Index,Item},PaginationInfinityScroll}.vue` used by both `Listing/` and
`SearchAreas/`. `FilterGroup.vue`/`FiltersPanel.vue` were left colocated per-feature since they
genuinely differ (`Listing`'s is checkbox-only with a nested `filter` prop; `SearchAreas`'s supports
checkbox/radio/checkbox-search with flat props and its own resetKey-merge logic) — merging those
would mean one component juggling two feature sets via conditionals. Added a shared `FilterOption`
type in `types/backend.ts`. `SearchAreas`'s `smTriggerElement` prop was renamed to `triggerClass` on
the shared pagination component (it's just a CSS class). Consolidated duplicate Vitest suites into
`Filters/__tests__/`; 210 tests → 201 after removing exact duplicates, all green; `yarn typecheck`/
`yarn lint` clean.

---

## Wave 8 — Charts + stats (done)

`region-country-pages` (country/region `#show` stats block) and its custom-chart family
(`chart-row-pa`, `chart-row-stacked`) are live via `frontend_mount`; amCharts stay on **amCharts 4**
for now (a v5 port is a separate follow-up, not bundled into this wave).

New: `RegionCountryPages/Index.vue` (composes
`Stats/{Coverage,Message,IucnCategories,Governance,Sources,Designations,Sites}.vue`), reusing the
Wave 7 `SearchAreas/TabStrip` island directly for the WDPA/WDPA+OECM database switcher rather than a
duplicate copy (it's generic, not SearchAreas-specific) — `RegionCountryPages.vue` no longer imports
the legacy `TabsFake.vue` at all.

`ChartRowPa`/`ChartRowStacked`/all `Stats/*` components keep their **legacy unprefixed BEM classes**
(`card--stats-*`, `chart--row-pa`, `list--underline*`, …) as a deliberate `ct-`-convention exception
(see README §Code conventions, point 4) — same precedent as `ListingPageCard`: the SCSS
(tooltip-arrow mixins, `nth-child` colour cycling for designation bars) is too deep to safely rewrite
in this pass.

`AmChart/{Pie,Multiline}.vue` port the amCharts4 wrapper components to `<script setup lang="ts">`
(template refs instead of global DOM ids, `onUnmounted` disposal) without touching the charting
library itself.

The legacy `related_countries` Vue2 slot (country page only) is gone — `frontend_mount` has no
slot-content equivalent, so `country_controller`'s view renders
`partials/stats/stats-related-countries` to a string and passes it as `relatedCountriesHtml`,
rendered with `v-html` (Pattern B "CMS as string props").

The WDPA/OECM info tooltips in `_stats-overview-country.html.erb` are wired live for the first time —
`StatsTooltipInfo.vue` wraps the already-built `TooltipSecond`/`IconExclamationCircle` (closing out
the Wave 2 "component built, never wired" note) since the description/designations-count copy that
used to live in ERB `<template #content>` slots has to come in as props instead.

`chart-row-pa`/`chart-coverage-growth` partials (marine ocean coverage, Green List tab, marine growth
chart) now call `frontend_mount` per chart directly (with `key:` for the marine page's two
side-by-side bars) rather than wrapping the whole partial in a page-level component — title/legend/
CMS content stay plain ERB since only the bar/chart itself is dynamic.

**Bugs found + fixed:**
- `Thematic::MarineController`'s growth-chart cache stored a pre-`.to_json`'d string (would have
  double-encoded once handed to `frontend_mount`'s own `.to_json` — fixed to cache the plain Hash,
  matching every other Wave 7+ controller).
- The designations jurisdiction tooltip read `jurisdiction.link_title`, a key
  `CountriesHelper#chart_link` never produces (it merges `title`), always rendering an empty `title`
  attribute — fixed to `jurisdiction.title`.

`StatsIucnCategoriesProps`/`StatsGovernanceProps` are picked from the raw TabPresenter hash (which
also carries an unused `country` key) rather than `v-bind`-spread wholesale, so `country` doesn't
leak onto the DOM as a stray attribute.

Verified via `yarn typecheck`/`yarn lint`/`vitest` (226 tests green, 25 new) and dev-server curl smoke
tests on `/country/USA`, `/region/AF`, `/thematic-areas/marine-protected-areas`, and
`/thematic-areas/protected-and-conserved-area-effectiveness` confirming correct mounts/props
(including the fixed growth-chart JSON shape); not yet checked in a real browser or on staging.

### Follow-up: point 20 (`props.xxx` in templates) retrofitted across Wave 8

The `Stats/*`/`Chart/*`/`AmChart/Pie.vue`/`RegionCountryPages/Index.vue` components landed in Wave 8
with `props.title`/`props.chart`/etc. littered through their templates instead of the bare prop name
[point 20](./CODE-CONVENTIONS.md) requires (`<script setup>` exposes every
declared prop directly to the template's render context, so the `props.` prefix is only needed inside
`<script setup>` itself). Fixed across all of them; `defineProps<T>()`'s return value was dropped (no
`const props =`) wherever nothing in `<script setup>` needed it anymore, kept where a `computed` still
reads `props.*` (`Chart/RowStacked.vue`, `Stats/Coverage.vue`, `RegionCountryPages/Index.vue`).

Also removed dead code found along the way: `AmChartPieProps.id` (a leftover from the
pre-`<script setup>` `am4core.create(id, ...)` pattern, unused now that `Pie.vue` mounts via a
template `ref`) and the redundant `class="am-chart--pie"` passed from
`Stats/Governance.vue`/`Stats/IucnCategories.vue` (Vue already falls through a parent `class` onto
`Pie.vue`'s own hardcoded-class root). Verified via `yarn typecheck`/`yarn lint`/`vitest` (25 tests
green across the touched files).

---

## Wave 9 — PA show `attributes-*` (done)

All 5 `protected_areas#show` attributes islands (`AttributesParcelsDropdown`,
`AttributesProtectedArea`, `AttributesPameList`, `AttributesAffiliations`,
`AttributesProtectedAreaSources`) are live via `frontend_mount`, under
`app/frontend/components/Attributes/`.

The Vue2 `parcelSelectionListener` mixin (`$root.$emit('parcel-selected', ...)`) doesn't survive the
split into separate `frontend_mount` apps — no shared `$root` across islands — so
`useParcelSelection` (`app/frontend/composables/useParcelSelection.ts`) replaces it: the `site_pid`
URL query param is the single source of truth (`AttributesParcelsDropdown` writes it via
`history.replaceState`; every other island re-reads it independently), with a payload-less `window`
custom event used only to tell the other islands "something changed, go re-read the URL." Chosen
over a shared composable singleton or a Pinia store because the dropdown already half-implemented
URL sync, and it's the only option that also gives reload/bookmark/back-button persistence for free.

The underlying `Dropdown` UI component (`app/javascript/components/dropdown/Dropdown.vue` +
`Options.vue` + `icon/Arrow.vue`) was ported to
`app/frontend/components/Dropdown/{Index,Options}.vue` + `Icon/Arrow.vue`, using `defineModel` + the
existing `usePopupCloseListeners` composable instead of the legacy `v-click-outside` global directive
(now deleted from `app/javascript/vue.js` along with the `$eventHub`-adjacent Vue2 registrations,
since Dropdown was its only consumer).

Legacy SCSS (`_dropdown.scss`, already `ct-`-namespaced, plus the unprefixed `card--*`/`list--*`
Stats-family classes) was kept as-is — same Wave 8 exception, not a redesign.

**Bugs found + fixed:**
- `AttributesPames`' fallback read `this.list` instead of `this.pamesAttributesList` (always
  harmless since the dropdown always sets an initial selection, but wrong regardless).
- Two sibling files both carried the copy-pasted Options-API `name: "statsAttributes"` (one of them
  on the wrong component entirely) — both vanish naturally since `<script setup>` has no `name`
  option.
- `show.html.erb`'s `sources_attributes_for_current_pa_and_all_parcels` call site was
  pre-`.to_json`'d before being handed to the (also-`.to_json`-ing) partial — fixed to pass the raw
  Hash, same double-encoding bug class as Wave 7/8.

Verified via `yarn typecheck`/`yarn lint`/`vitest` (254 tests green, 28 new) and dev-server curl
smoke tests against a single-parcel PA and a 3-parcel PA in both normal and `for_pdf=true` modes,
confirming correct props/mount shapes and no server errors.

---

## Wave 10 — PAME (done)

The gdpame page (`filtered-table`, `pame-modal`, `usePameStore`) migrated to
`app/frontend/components/Pame/{Table/*,Filters/*,Modal.vue}`, mounted as `frontend_mount
"PameTable"` (`partials/data/gdpame/_tab_content`) and `frontend_mount "PameModal"`
(`data/gdpame/index.html.erb`). This also finally wires in Wave 2's `Tooltip` island — its only
caller (the table header's tooltip) was this page, and it was the last legacy `<tooltip>` usage in
the codebase, so `app/javascript/components/tooltip/{Tooltip,TooltipSecond}.vue` were both deleted
(`TooltipSecond` had zero callers left over from Wave 8's `StatsTooltipInfo` cutover, confirmed via
grep before deleting).

**Pinia store.** `usePameStore` (`app/frontend/stores/usePameStore.ts`) ports the legacy Vuex `pame`
module, but drops `totalItemsOnCurrentPage`, `sortDirection`/`updateSortDirection`, and
`removeFilterOption`/`clearFilterOptions` — all had zero callers anywhere in the codebase (confirmed
via grep), including the legacy module's own components. `PameTable` and `PameModal` are two
separate `frontend_mount` islands sharing this one Pinia store — same bridging pattern as
`useDownloadStore` (Wave 4/7) — `isModalOpen` is a distinct boolean from `modalContent` so re-opening
the modal with the same-looking item still flips the class correctly.

**Filters — kept the dropdown-with-apply/cancel/clear UX, didn't try to reuse `Listing`/`SearchAreas`
Filters.** PAME's filter UI (`PameFiltersFilter`) is a per-column dropdown with local
pending-vs-applied checkbox state and explicit Apply/Cancel/Clear buttons — genuinely different from
`Listing`/`SearchAreas`' immediate-apply sidebar checkboxes (no cancel concept there), so per the
"diff byte-for-byte before merging" rule ([[frontend-upgrade-roadmap]] Wave 7 note), this stayed a
separate `Pame/Filters/{Index,Filter,FilterOption}.vue` tree rather than forcing it onto
`Filters/Checkboxes`. Exclusivity (only one dropdown open at a time) moved from the legacy
`$eventHub.$emit('clickDropdown', name)` global broadcast to `Filters/Index.vue` owning an
`openFilterName` ref and passing `:isOpen="openFilterName === filter.name"` down — a plain
parent-owns-list pattern, no bus needed since Filters/Index and every Filter are already in one
component tree (unlike the modal, which genuinely needs the store because it's a separate mount).

**Legacy SCSS reused as-is** (`_table-pame.scss`, `_filters-pame.scss`, `_table-head-pame.scss`,
`_modal-pame.scss`) — same Wave 8/9 exception, not a redesign; these are dense, `--pame`-suffixed
partials wired to a lot of nested BEM, and rewriting them was judged out of scope for this pass.

**Dead code found and dropped, not ported:**
- `TableHeader`'s sort click (`this.$eventHub.$emit('sort', ...)`) — grepped for a `sort` listener
  anywhere in the codebase and found none; sorting was already non-functional in the Vue2 version.
  Kept the visual sort-arrow markup (purely decorative/CSS) but dropped the dead click handler.
- `PameModal`'s `printMultiple` method — never called from its own template.
- `PamePagination`'s `setInterval(..., 100)` scroll-poll for the sticky table header replaced with a
  real `scroll`/`resize` listener pair (`PameTableHead`) — same "replace legacy polling with a native
  listener" pattern as `Counter`'s `IntersectionObserver` swap in Wave 1.

**Bug found + fixed:** `PameModal`'s "Year of submission" field checked `modalContent.year` (a key
`PameEvaluation.serialise` never sets — only `source_year` exists) before displaying
`modalContent.source_year`, so that field was always empty. Fixed the guard to check
`modalContent.source_year` directly; covered by a spec asserting the year renders.

**Same tab-visibility issue as Wave 6's Map fix.** gdpame's `tab_extras` region
(`partials/thematic_and_data_area/_tabs.html.erb`) is still legacy Vue2 `TabTarget` (a `display: none`
toggle, not `v-if`), so `PameTableHead` can mount hidden and compute a zero-based sticky trigger.
Applied the identical `IntersectionObserver`-on-container fix `Map/Base.vue` uses for the same
reason.

**Controller/model — dropped pre-`.to_json`'d strings for `frontend_mount`,** same fix class as
Waves 5/7/9: `Data::GdpameController#index`'s `@table_attributes`/`@filters`/`@json` now pass raw
Ruby hashes/arrays (`PameEvaluation::TABLE_ATTRIBUTES`, a renamed `PameEvaluation.filters` — was
`filters_to_json`, single caller — and `PameEvaluation.paginate_evaluations` unchanged). `/pame/list`
and `/pame/download` were already JSON-body endpoints server-side, so the Vue3 `postJson`/new
`postBlob` (`app/frontend/lib/http.ts`) helpers send `{filters: [...]}` unchanged from what the
legacy axios calls sent — no controller changes needed for either action.

Verified via `yarn typecheck`/`yarn lint`/`vitest` (282 tests green, 28 new — 27 Pame-specific plus
the pre-existing suite), `yarn vite:build` clean, and dev-server curl smoke tests: gdpame page (200,
`data-mount="PameTable"`/`"PameModal"` present with real filter/attribute/pagination data, zero
`<filtered-table>`/`<pame-modal>` tags), `/pame/list` (200, real paginated JSON), `/pame/download`
(200, real CSV with correct filename and BOM). `bundle exec rails webpacker:compile` logs a bare
"Compilation failed:" with no detail — reproduced identically on `vue.js`/`store.js` reverted to
their pre-Wave-10 state, so this is a pre-existing environment quirk, not a regression; live pages
render at 200 with correct content either way. **Not yet done:** real-browser verification of the
filter dropdown interactions and CSV download (curl/Vitest can't catch client-side/CSS issues — see
the Wave 6 CORS-bug lesson).

**Real-browser follow-up #1 (found by the user, not curl/Vitest): `#v-app` never mounted because the
`webpacker` dev-server container had exited.** The gdpame page rendered as raw, unstyled, stacked tab
content instead of a working tabbed UI — a symptom that only shows up in a real browser, exactly the
Wave 6 CORS-bug lesson repeating. Root cause: the dedicated `webpacker` compose service (the one
carrying `NODE_OPTIONS=--openssl-legacy-provider`, per [15 Docker Vite dev](./15-docker-vite-dev.md)
and the Node↔Webpacker constraint in this README) had exited, so `web` fell back to compiling
in-process without that flag, hit `ERR_OSSL_EVP_UNSUPPORTED` (Node 24 + webpack 4's md4 hash),
and `public/packs/manifest.json` was left pointing at a hash that was never actually written —
`/packs/js/application-*.js` 404'd, so Vue2 never mounted, and the legacy `<tabs>`/`<tab-target>`
wrapper (still in play for gdpame — Wave 3's `tab_extras` block is unrelated to this and untouched)
just dumped all three tabs' content unstyled. Confirmed NOT caused by this wave's `vue.js`/`store.js`
edits (reproduced identically with them reverted). Fixed by `docker compose up -d webpacker` —
no code change.

**Real-browser follow-up #2 (user-reported): pagination fired overlapping `/pame/list` requests.**
Clicking "next" again while the previous page was still loading fired a second POST before the first
resolved — `PameTablePagination`'s buttons only guarded against `currentPage`/`totalPages` bounds, not
against a request already in flight. Added one shared `isFetching` boolean to `usePameStore` — every
PAME network call (list fetch in `PameTable/Index.vue`, CSV download in `PameTableDownloadCsv.vue`)
sets it for the call's duration — so pagination, filter apply/toggle, and the download button all
disable together, not just the specific control that started the request. Guarded in both directions:
the buttons visually disable (`:disabled`) AND the trigger functions (`fetchItems`, `onChangePage`,
`onToggle`/`onApply`, `onDownload`) no-op if `isFetching` is already true, so a click that slips past
the disabled attribute (or a keyboard/synthetic event) still can't fire a second request. Chose a
Pinia-level flag over prop-drilling `isLoading` through `Table/Index → Filters/Index → Filter` and
`Table/Index → Filters/Index → DownloadCsv` — `usePameStore` already coordinates state across this
component tree (filters, modal), and the download button specifically needs to react to the table's
fetch state despite being nested under a sibling branch, which plain props can't express without an
extra event-bubbling relay. `DownloadCsv` keeps a separate local `isDownloading` ref purely for its
own spinner icon, so a table-fetch or filter-apply disables the button without incorrectly showing
its spinner. Covered by new specs on `usePameStore`, `Pagination`, `Filter`, `DownloadCsv`, and a
`Table/Index` test that mocks an unresolved fetch and asserts a second click doesn't call `fetch`
again. 288 tests green (6 new), typecheck/lint/`vite:build` clean.

**Follow-up #3 (same session, user-requested): loading overlay over the table body.** `isFetching`
disabling buttons wasn't itself a visible "the table is busy" signal, so added a `ct-pame-table__body`
wrapper (`position: relative`, fresh Tailwind styles — this is new markup, not ported, so it follows
the rule 4 default rather than the legacy-SCSS-reuse exception) around the `<table>`, with an
absolutely-positioned overlay (`bg-white/70`, the shared `icon--loading-spinner` background-image
class reused as-is since it's a real asset, not a rewrite) shown via `v-if="pameStore.isFetching"`.
`aria-busy` on the wrapper and `role="status"` + a "Loading…" text node on the overlay for
screen-reader users, not just a visual spinner. Covered by a spec asserting the overlay appears on
click and disappears once the mocked fetch resolves.

**Follow-up #4 (same session, user-requested): folder restructuring + PameModal moved inside the
table.** `Pame/Filters/Filter.vue`/`FilterOption.vue` restructured into `Pame/Filters/Filter/{Index,
Options,Option}.vue` — extracted the inline `<ul>` option list into a new `Options.vue`
(`PameFiltersFilterOptions`) matching the existing `Filters/Checkboxes/{Index,Item}.vue` precedent
elsewhere in the codebase (list wrapper + single-item child, one folder per concern). Similarly,
`Pame/Table/Head.vue`/`HeadCell.vue` → `Pame/Table/Head/{Index,Cell}.vue`, and `Pame/Table/Row.vue`/
`RowMobile.vue`/`SiteId.vue` → `Pame/Table/Row/{Index,Mobile,SiteId}.vue` (SiteId nested under Row/
since it's exclusively used by Row's two variants; its tag renamed `PameTableSiteId` →
`PameTableRowSiteId` to match the new flattened path). `pameTableFormat.ts` (plain `trimText`/
`joinOrMultiple` functions, no reactivity/lifecycle) moved to `app/frontend/lib/pameTableFormat.ts`,
matching the existing `lib/` convention for framework-agnostic helpers rather than `composables/`.
All import paths and test files (`__tests__` dirs) moved/updated accordingly; added a new
`Filter/__tests__/Options.spec.ts` for the extracted component.

Separately, `PameModal` was de-registered as its own `frontend_mount` island (removed from
`layout.ts` and `views/data/gdpame/index.html.erb`) and is now rendered as a normal child of
`Pame/Table/Index.vue` — it only ever appears alongside the table and already shared `usePameStore`
with it via the global Pinia instance, so a second top-level mount added nothing but an extra hydration
root. Its translations (`t('thematic_area.pame.modal')`) now thread through as a new `modalText` prop
on `PameTableProps`/`frontend_mount "PameTable"` (set in `_tab_content.html.erb`) instead of being
read directly in `index.html.erb`. `PameModalProps`/`PameModalTranslations` types kept (Modal.vue
still takes `text` as a prop), just re-described as the child component's own props rather than an
island's. Added a `Table/Index.spec.ts` case mounting the table and asserting the modal opens from a
row click. Typecheck/lint/vitest (37 tests)/`vite:build` all clean; verified live — smoke-tested the
wrong URL first (`/en/data/gdpame`, which 404s: the controller/file names use the short `gdpame` slug
but the actual CMS-routed path is `PageSlugs::Data::GDPAME` = `global-database-on-protected-area-
management-effectiveness`, per `config/routes.rb`/`app/models/page_slugs.rb`) — the correct URL
`/en/data/global-database-on-protected-area-management-effectiveness` returns 200 with a single
`data-mount="PameTable"` (no separate `PameModal` mount) and `modalText` present in its props JSON.

---

## Wave T0 — SCSS→Tailwind cleanup & convention fixes (done)

Re-verified [16](./16-scss-to-tailwind-migration.md)'s August "confirmed dead SCSS" baseline with a
precise `class=`-usage grep (not raw-token match, which false-positives on Tailwind composites like
`text-white` containing "white") before deleting anything — **the baseline had drifted more than
expected**:

- `_popup.scss` and `_social.scss` were listed as 0-consumer dead code. Both are actively live:
  `Download/Popup.vue` renders `.popup--download`/`.popup__ul`/`.popup__link` (with passing Vitest
  coverage), and `.social--media`/`.social__icon` are used by `_footer.html.erb`, `_head.html.erb`,
  `_topbar-secondary.html.erb`, `_social-share.html.erb`, `_social-follow.html.erb`, and two Comfy
  CMS partials. Neither was deleted — moved into Wave T4 (Download family) and Wave T2 (views-only
  chrome) respectively for proper rewrite-and-delete treatment.
- Most of `helpers/_helpers.scss` and `utilities/_flexbox.scss`'s classes were also assumed dead but
  turned out to have real consumers (`.block`, `.bold`, `.p-larger`, `.ul-unstyled`, `.text-center`,
  `.no-margin`/`.no-margin--top`, `.margin-center`, `.margin-space--bottom`/`--left`,
  `.hover--pointer`; `.flex`, `.flex-inline`, `.flex-row`, `.flex-column`, `.flex-wrap`,
  `.flex-no-shrink`, `.flex-h-center`, `.flex-h-between`, `.flex-v-start`, `.flex-v-center`) — left in
  place, deferred to T3/T4's real migration rather than deleted here.

**Actually deleted** (confirmed zero real consumers): `components/select/_selector.scss` (whole
file), `.circle--grey-black` from `base/_circles.scss`, the `.screen-reader{}` class rule from
`helpers/_accessibility.scss` (its `@mixin screen-reader` stays — still `@include`d by
`_v-map-filters.scss`, so that file could not be deleted outright as the original plan assumed), the
4 `.breakpoint-*-up/down` classes from `utilities/_media-queries.scss`, and the confirmed-zero subset
of `_helpers.scss`/`_flexbox.scss` (`.inline-block`, `.full-height`, `.red`, `.white`, `.thin`,
`.ul-inline`, `.text-right`, `.text-left`, `.relative`, `.bottom-right`, `.center-right`, `.top-right`,
`.margin-space--right`, `.no-padding`, `.no-select`; `.flex-1` + all 47 `.flex-*` column/alignment
variants). All mixins/functions in the touched files were left untouched — still ported in Wave T1,
not deleted here.

Also added **rule 4b (`vw-` prefix)** to CODE-CONVENTIONS.md for ERB-view-owned chrome with no single
owning Vue component, and fixed rule 5 + the "Setup status" section's stale `styles/shared/base.css`
reference to the real flat `styles/shared.css` (no `shared/` subfolder exists).

[16](./16-scss-to-tailwind-migration.md)'s baseline section, T0 checklist, and T2/T4 wave file lists
updated in place to reflect the corrected findings — not left as a silent scope drop.

Two live breakages found and fixed while verifying the deletions (grepping `app/views`/
`app/frontend/components` alone misses SCSS-internal dependencies — `@import`/`@extend` cross-file
references and Sprockets don't show up in a template-only search):
- `components/_select.scss` still had `@import './select/selector';` pointing at the deleted file —
  removed the import line (the `select-searchable` import in the same file is untouched).
- `components/_charts.scss`'s `chart-tooltip` mixin did `@extend .flex-center;`, which no longer
  resolved once that class was deleted — swapped to `@include flex-center;` (the mixin was always
  kept; identical compiled output, no dependency on the class).

Verified: `yarn vite:build` clean. Forced a full Sprockets `application.css` compile
(`Sprockets::Railtie.build_environment(...)['application.css']`) — caught both breakages above via
`SassC::SyntaxError`, clean after the two fixes (417,246 bytes compiled, confirmed also served live at
`/assets/application.css`). Live-curled home (`/en`), gdpame, a country page (`/en/country/KEN`),
resources listing, and news listing — all 200. (`/en/marine` 500s in this environment, but it's an
`ApplicationController::PageNotFound` from a missing CMS page in the local DB, unrelated to any CSS
change.) Real-browser visual diffing was skipped for this wave — every class actually removed was
independently confirmed to have zero template consumers, so there is nothing left to render
differently; the two SCSS-internal breakages above are believed to be the only regression surface,
and both are now fixed and covered by the successful full-CSS compile.

---

## Wave T1 — Shared Tailwind foundation (done)

Split `app/frontend/styles/shared.css` into `app/frontend/styles/shared/{base,icons,typography,
shadows,forms,images,scrollbar}.css`, one `@utility tw-shared-<name>` group per concern, per
CODE-CONVENTIONS.md rule 5. Two deviations from [16](./16-scss-to-tailwind-migration.md)'s original
6-name bucket list, both logged in place there per cross-cutting rule 5 rather than silently absorbed:
`buttons.css` wasn't created (nothing in this wave's scope needed `tw-shared-button-*` yet — deferred
to whichever wave first migrates a button-heavy component); `images.css` and `scrollbar.css` were added
since `image-placeholder` and the webkit-scrollbar mixin are their own concerns with real consumers
that don't fit the other five buckets.

Ported `helpers/mixins/_text.scss` (typography) and `helpers/mixins/_icons.scss` (36 SVG icon mixins,
backed by 36 SVGs newly duplicated into `app/frontend/assets/icons/` so Vite can process/fingerprint
them — no Vue island had referenced an image asset through Vite before this wave; the legacy copies
under `app/assets/images/icons/` stay put until Wave T10 deletes the Sprockets pipeline serving them).
Also ported `helpers/_border-and-shadows.scss`, `helpers/_form-fields.scss`, `helpers/_images.scss`,
`helpers/_beautify-scrollbar.scss`. Several sub-mixins turned out to already have a native Tailwind
1:1 equivalent and were deliberately **not** ported (documented inline in each new file instead of
silently ported anyway): `border-radius-top`/`-bottom` (→ `rounded-t`/`rounded-b`), `input-hidden`
(→ `sr-only`), `input-custom-focus` (→ `outline-none`). One mixin family genuinely can't become a CSS
utility: `icon-pin($circle, $outline)` and its `-marine`/`-oecm`/`-terrestrial`(`-light`) variants tint
an *inline* `<svg>`'s child `.circle`/`.outline`/`.tick` fills rather than swapping a background-image —
left as legacy SCSS, deferred to Wave T5 (`_v-map-popup.scss`) / T7 (`card/_card-theme.scss`) when
those consumers actually migrate (likely an inline Vue SVG component with color props, not a utility
class). `icon-pin-outline`/`icon-pin-map` — plain background-image uses of the same source SVGs at
different fixed sizes — **were** ported.

Confirmed (no port needed) rather than assumed: `utilities/_flexbox.scss`'s mixins map 1:1 to
Tailwind's native `flex`/`justify-*`/`items-*`; `utilities/_rem-calc.scss` matches Tailwind's rem-based
spacing scale exactly (Foundation's `$global-font-size` is never overridden from its 16px default, so
`rem-calc(N)` and Tailwind's arbitrary-value `N/16rem` math never diverge).

`utilities/_media-queries.scss`'s legacy breakpoints (767/1024/1200/1440px) don't line up with
Tailwind's defaults (640/768/1024/1280) closely enough to reuse `sm:`/`md:`/`lg:`/`xl:` without
silently changing what those prefixes mean for any future non-legacy-parity use — added as
**distinctly-named** `@theme` breakpoints instead: `--breakpoint-small: 48rem` (768px),
`--breakpoint-medium: 64.0625rem` (1025px), `--breakpoint-large: 75.0625rem` (1201px),
`--breakpoint-xlarge: 90.0625rem` (1441px). The `+1px` mirrors the legacy `breakpoint()` mixin's
exclusive `min-width: $bp + 1px`. Extended `@theme` colors with 4 more tokens found in active use
across T2/T3's file scope: `--color-theme-grey-xdark`, `--color-theme-green-dark`,
`--color-theme-chart-purple`, `--color-theme-chart-green` (`$white`/`$black` also appear there but
need no new token — Tailwind ships `white`/`black` natively).

Verified: `yarn typecheck` / `yarn lint` / `yarn vite:build` / `yarn test` (Vitest) all clean in the
`protectedplanet-web` container. The build itself caught a real bug: a doc comment in the new
`shadows.css` contained a literal `*/` (inside the phrase "rounded-t-*/rounded-b-*"), closing the CSS
comment early — Vite's CSS optimizer flagged it as "Unexpected token Delim('*')"; fixed by rewording
the comment. `SearchSiteInput.spec.ts`'s 1 pre-existing lint error and 4 pre-existing Vitest failures
were confirmed unrelated by stashing this wave's changes and re-running — identical failures on the
branch beforehand. No visual change expected or checked live — this wave ships zero consumers of the
new utilities (pure infrastructure); real-browser spot-checking starts with Wave T2, the first wave
that actually applies them.

**Post-wave correction (same day):** a user question about icon architecture surfaced an
already-established precedent this wave's research had missed — `app/frontend/components/Icon/
{Search,Close,Arrow,Pin,ExclamationCircle}.vue` already exist, rendering icons as inline
`<svg fill="currentColor">` Vue components (sized/colored by the consumer's own scoped `@apply`,
not baked into the icon file), already used by `Search/SiteInput.vue`, `Carousel/Themes/Ribbon.vue`,
`Stats/TooltipInfo.vue`. Added **CODE-CONVENTIONS.md rule 5b**: a Vue-rendered icon is always an
`Icon/*.vue` component, never a `tw-shared-icon-*` CSS class — the latter is for ERB view chrome
(rule 4b) only. Three fixes followed: `icon-pin($circle, $outline)`'s "not portable, decide later"
note was wrong — `Icon/Pin.vue` already solves it (per-part `@apply fill-*`), so T5/T7 reuse that
component rather than inventing a new mechanism; `forms.css`'s `tw-shared-input-custom-checkbox-selected`
(`@apply tw-shared-icon-tick`) was removed since its only real consumers are Vue/T4 (which should add
`Icon/Tick.vue` instead); `images.css`'s `tw-shared-image-placeholder` dropped its icon `::after`
overlay for the same reason (real consumers are Vue/T7). `shared/icons.css` itself keeps its full
icon set for now — which utilities end up with a genuine ERB consumer vs. none (because their only
real caller should have used `Icon/*.vue`) gets sorted out as T2/T3/T4 actually land, not guessed at
here.

---

## Wave T2 — Global chrome, views-only (done)

Migrated all 9 files in the wave's scope to `app/frontend/styles/views/{base,footer,hero,cta,
content-banner,background,social}.css` (7 new files — `base.css` covers both `base/_base.scss`
and, being ERB-owned only, `_nav.scss`'s `.nav--primary`): `base/_base.scss`'s `.site-width`/
`.container`(+modifiers)/`.spacer-*`/`h1-home`/`h2-big`(`-white`)/`text-intro`, `components/_nav.scss`'s
`.nav--primary` (own declarations only — see below), `components/_footer.scss`, `components/hero/
*.scss` (5 variants), `components/_cta.scss`, `components/_content-banner.scss` +
`content-banner/_content-banner-basic.scss`, `helpers/_background.scss` (5 of 11 classes with real
consumers), `components/_social.scss`. All of `base.css`'s classes are `vw-base-*`-prefixed (e.g.
`vw-base-container`, `vw-base-h2-big`) — added post-review, since unlike every other file in this
wave it has no single component/block name of its own to put in the class name; matches the
existing `tw-shared-base-container` precedent in `shared/base.css`.

`custom.scss` (2018-era, "home page stat blocks" per the
wave doc) turned out to have **zero live consumers anywhere** — not even compiled into
`application.css` (never `@import`ed by `application.scss`) — deleted outright, no port needed.

**Scope corrections against the wave doc's own baseline** (re-verified live, not trusted as-is,
same discipline as T0):
- `_nav.scss` **cannot be deleted** — only `.nav--primary`'s own `display:flex; align-self:stretch`
  (not `align-items:stretch` as the doc's baseline said) moved to `views/topbar.css`'s existing
  `vw-layouts-partials-topbar__nav` utility. Everything nested under `.nav--primary .nav__*` is rendered by
  `NavBar/Index.vue`/`Link.vue`/`Dropdown.vue` (Vue 3's `app.mount()` nests children inside
  `frontend_mount`'s wrapper div rather than replacing it) — squarely Wave T4, so `_nav.scss` stays
  alive with just that trimmed top-level rule.
- `pages/_error-page.scss` (T3 scope) has a live descendant-selector dependency on hero classes —
  `& > .hero--basic .hero__content { width:100% }`, feeding 404/500's `error-page__hero` wrapper —
  updated in place to `.vw-hero--basic .vw-hero__content--basic` rather than left dangling; a wave
  boundary isn't a reason to ship a silently-broken selector.
- `helpers/_background.scss` **stays alive** (mixins only) — `bg-image-overlay`, `bg-image-overlay-hover`,
  `bg-gradient-overlay`, `bg-grey-xlight`, `bg-grey-black` are still `@include`d directly by T4/T7 files
  (`_search-results-areas.scss`, `_card-theme.scss`, `_cards-squares.scss`, `_card-stats-overview.scss`);
  only the **classes** section (`.bg--*`, `.bg-img`, `.bg-image-overlay(--white)`, `.bg-gradient-overlay--white`)
  was removed. The dead `$image-placeholder` variable (only used by the deleted `.bg-img`) was removed too.
- Two "gutters" mixins with the **same name** exist — `helpers/mixins/_layout.scss`'s (never actually
  called — shadowed) and `helpers/_helpers.scss`'s (imported later in `application.scss`, so it's the
  one Sass actually resolves for every `@include gutters(...)` call, including inside `.container`).
  The real one uses `breakpoint($medium)`/`breakpoint($large)` (1025px/1201px), not `breakpoint($small)`/
  `breakpoint($large)` as the shadowed definition would suggest — caught only by checking the actual
  compiled `application.css`, not the SCSS source (same lesson as T0's `_popup.scss`/`_social.scss`
  correction: verify against compiled output, not source-reading assumptions, whenever two rules could
  plausibly apply to the same selector).
- `icons/email-white.svg` (`_social.scss`) doesn't exist on disk — legacy `image-url()` silently
  fell back to an unfingerprinted literal path. Turns out harmless: `config/locales/social/en.yml`'s
  `social.share`/`social.follow` keys are only twitter/facebook/linkedin, so `.social__icon--email`
  never renders and the missing asset is dead code, not a live bug. Ported as-is (same still-missing
  absolute path, which Vite leaves unresolved at build time rather than hard-failing) rather than
  inventing new icon artwork for a variant nothing renders.
- A **third**, pre-existing, unrelated bug found and preserved as-is (not this wave's to fix):
  `.hero--area-type`/`.hero--basic`/`.hero--thematic`/`.hero--small`'s medium-tier padding called a
  non-existent `em-calc()` Sass function (only `rem-calc()` exists) — Sass passes unrecognized
  function-like syntax through as literal text, so the browser drops the whole declaration as invalid
  CSS. Real effect: padding just stays at the small-tier (768px) value from 1025px up. Reproduced by
  simply not adding a `medium:` padding override, rather than silently "fixing" it to the
  presumably-intended value.

**Cascade-layer pitfall found via real-browser check, not just curl/Vitest** — the wave's
"real-browser verification" rule caught a bug that would have been invisible to `yarn vite:build`/
`yarn test`: `views/base.css` and `views/footer.css` originally wrote `vw-base-h1-home`/
`vw-base-h2-big`/`vw-base-h2-big-white`/`vw-partials-footer__link`/`vw-partials-footer__link-partner` as `@utility` blocks, same as every
other class in this wave. But per the CSS cascade spec, **any unlayered rule beats any layered rule
regardless of specificity** — Tailwind's `@utility` always lands in `@layer utilities`, while the
legacy Sprockets `application.css` has no `@layer` at all. Since this wave deliberately keeps
`_base.scss`'s bare `h1`/`h2`/`a` element rules alive (site-wide typography baseline, not "views-only
chrome"), any new utility trying to override a property those bare rules *also* set (font-size on
h1/h2, color on h2, text-decoration on a) silently lost — confirmed via `getComputedStyle` in a
headless-Chromium check: `h2.vw-h2-big-white` rendered `#242424` instead of white on the API/MPA
CTAs' dark backgrounds (text nearly invisible), footer links rendered underlined instead of not.
Fixed by writing exactly those 5 classes as plain (non-`@utility`) selectors — still using `@apply`
internally, just landing unlayered so normal specificity rules apply and the class correctly beats
the bare element rule. Every other class in this wave targets a div/section with no competing
bare-element rule, so `@utility` was fine as-is; documented inline in both files so the next wave
doesn't have to rediscover this by staring at a washed-out screenshot.

Verified: `yarn typecheck`/`yarn vite:build` clean; `yarn lint` and `yarn test` (Vitest) reproduce
the same pre-existing `SearchSiteInput.spec.ts` failures as T1 (1 lint error, 4 Vitest failures),
confirmed unrelated. Forced a full Sprockets `application.css` recompile — clean, no dangling
`@import`s from the deleted files (all glob-imported via `components/*`/`base/*`, so removal is
silent and safe). Live-verified in a real headless-Chromium session (`playwright-core`, since
`chromium-cli` wasn't available in this environment) at both desktop (1440px) and mobile (390px)
viewports: home, the marine/effectiveness thematic hero pages, gdpame, wdpca — screenshotted
before and after the cascade-layer fix above, `console --errors`/response-status checked on every
page (the only errors present are pre-existing ActiveStorage `disk` service 500s for CMS-uploaded
images in this dev dataset, unrelated to CSS/SCSS and present on every page regardless of this
wave's changes).

**Post-review pass (same day): one combined class per element, not multiple stacked in markup.**
Within each component partial (footer, the 5 hero variants, the 3 CTA variants, content-banner),
elements that had 2+ of this wave's own classes stacked in `class="..."` — e.g. `vw-hero__container
vw-hero__container--early-row vw-hero__container--spaced vw-base-container` on the area-type hero's
container — were consolidated into **one** combined class per element (`vw-hero__container--area-
type`), composing the pieces via `@apply` inside the CSS instead of stacking classes in the ERB —
matching how a Vue SFC's `<style scoped>` block works. The genuinely cross-cutting `vw-base-*`/
`vw-bg--*` utilities used standalone on *unrelated* page templates (`country/show.html.erb`,
`layouts/cms/_*.html.erb`, etc.) were deliberately left alone — those aren't "one component's
multiple modifier classes," they're the shared-utility tier doing exactly what it's for.

This refactor surfaced two more bugs, both fixed:
- **`@apply` cannot reference a plain (non-`@utility`) class.** `vw-partials-ctas-api__title` tried to compose
  `vw-base-h2-big` (deliberately written as plain CSS per the cascade-layer fix above) via `@apply`
  — Tailwind's build failed outright ("Cannot apply unknown utility class") since only
  `@utility`-registered classes are valid `@apply` targets. Fixed by making `vw-partials-ctas-api__title` itself
  a plain selector with the h2-big declarations inlined directly, rather than composed — the same
  pattern applies to any future combined class that needs a plain (bare-element-overriding)
  ingredient.
- **Tailwind's class scanner can't see a dynamically-interpolated class name.** Merging
  `vw-bg--grey-xdark` into `vw-partials-ctas-api--live-report` broke the live-report CTA's entire background —
  `_live-report.html.erb` builds its root class as `vw-partials-ctas-api--<%= cta_protected_planet_report.css_class %>`, and
  since the literal string `vw-partials-ctas-api--live-report` never appears intact anywhere in scanned source
  (only the static `vw-partials-ctas-api--api`/`vw-partials-ctas-api--mpa` do, in their own partials), Tailwind's `@source`
  scanner silently never generated the utility at all — confirmed by grepping the compiled CSS
  for `vw-partials-ctas-api--live-report` and finding zero matches. This had actually been broken since this
  class was first introduced earlier in the wave; it only became *visible* once the separate,
  always-static `vw-bg--grey-xdark` class (which was quietly carrying 100% of the real styling)
  was removed from the markup. Fixed by hardcoding the literal class name (`cta_protected_planet_report` is
  always looked up by the `PageSlugs::Cta::LIVE_REPORT` constant, so this was never actually
  variable in practice) — per [Tailwind's own docs](https://tailwindcss.com/docs/detecting-classes-in-source-files#dynamic-class-names),
  a class name is never safe to build by string concatenation regardless of whether the legacy
  Sprockets pipeline tolerated it. **Any future wave reusing a `<%= record.some_column %>`-driven
  class name needs the same check** — grep the compiled CSS for the literal class string, don't
  assume "it's in an `@utility` block" is enough.
- (Caught in the same pass, unrelated to the above) an ERB comment (`<%# ... %>`) that quoted a
  `<%= ... %>` tag as example text inside itself broke — ERB doesn't nest comments, so the parser
  closed the comment at the quoted tag's own `%>` and rendered the rest of the "comment" as literal
  page text. Fixed by rephrasing the comment in plain prose with no ERB-tag-shaped substrings.

## Wave T3 — Page shells, views-only (done)

**Retracted this wave's own T2 exception: no bare utility classes in ERB markup, ever, not even
cross-cutting ones.** T2's entry above explicitly left `vw-base-*`/`vw-bg--*` stacked directly in
markup (e.g. `class="page--country vw-bg--grey-xlight vw-base-spacer-small--top"`) on the reasoning
that cross-cutting utilities are "the shared-utility tier doing exactly what it's for." Reversed:
every element gets exactly one class, even one that does nothing but `@apply` a couple of
`tw-shared-*` ingredients with no page-specific tweaks — same rule as a Vue SFC's single template
class composing everything in `<style scoped>`. See the two new Decisions entries in the main plan
doc for the full reasoning.

**Found and fixed while doing this: `vw-base-*`/`vw-bg--*` were misnamed and mis-homed from the
start.** Both are consumed standalone by 30+ *unrelated* ERB templates plus `hero.css`/`cta.css`/
`footer.css` — the literal `tw-shared-` definition ("needed by >1 component or view"), not `vw-`'s
("chrome owned by one page"). T2 put the whole family in `views/base.css`/`views/background.css`
instead of `shared/`. Fixed:
- Moved all of `views/base.css` (`vw-base-container(--pame/--medium/--component)`,
  `vw-base-spacer-{small,medium,large}--{top,bottom}`, `vw-base-h1-home`, `vw-base-h2-big(-white)`,
  `vw-base-text-intro`) and `views/background.css` (`vw-bg--primary/grey-xlight/grey-xdark/
  grey-black`, `vw-bg-image-overlay--white`) into `shared/base.css`/`shared/background.css` as
  `tw-shared-base-*`/`tw-shared-bg--*`. Both `views/*.css` files deleted, `tailwind.css`'s imports
  updated. Repointed every consumer: `hero.css`, `cta.css`, `footer.css`, `content-banner.css`
  (internal `@apply` ingredients) and all ~34 ERB view templates that had them stacked directly in
  markup (mechanical rename, no behaviour change for these — the prefix changed, the utility
  bodies didn't).
- **Real duplicate found and merged.** `shared/base.css` already had a `tw-shared-base-container`
  (added in T1, consumed by `views/topbar.css`, `views/topbar-secondary.css`, `Tabs.vue`,
  `Banner/Index.vue`) using native `md:`/`lg:` (768px/1024px) breakpoints — written before T2's own
  investigation into the legacy `.container` class's real compiled breakpoints (`medium:`/`large:`,
  1025px/1201px, via the shadowed `gutters()` mixin documented in T2's `views/base.css` header
  comment). The two were never reconciled against each other. Resolved in favour of the
  legacy-verified `medium:`/`large:` definition (the one with 40 real consumers to stay pixel-
  accurate against vs. 3 that had no legacy counterpart to match in the first place) — so `topbar`/
  `Tabs`/`Banner` now also use `medium:`/`large:`. **This is a real behaviour change for those 3
  pre-existing consumers** (container padding now steps up at 1025px/1201px instead of
  768px/1024px) — flagged for live re-verification, not silently assumed fine.
- Added `tw-shared-region-country-site__overview` (`flex flex-wrap small:flex-nowrap`) to `shared/base.css` —
  the legacy `flex-stack-mobile` mixin's exact 2-line body, called identically by all three of
  `pages/_country.scss`/`_region.scss`/`_site.scss`'s `.page__section--overview-map` rule. First
  consumer is country (below); region/site inherit it when their own rows in the plan's T3 wave
  table land.

**`country/show.html.erb` done** (the reference example for the retracted-exception fix above):
- Outer wrapper: `page--country vw-bg--grey-xlight vw-base-spacer-small--top` → single class
  `vw-country` (`@apply tw-shared-bg--grey-xlight tw-shared-base-spacer-small--top`).
- Container div: `vw-base-container` → `vw-country__container` (`@apply tw-shared-base-container`).
- `page__section--overview-map` → `vw-country__overview` (`@apply tw-shared-region-country-site__overview`).
- Both new classes live in new `views/country.css`.
- `pages/_country.scss` **deleted** — its only rule (`.page--country .page__section--overview-map
  { flex-stack-mobile }`) is now `vw-country__overview` above, and `page--country` had zero
  other consumers after the ERB rewrite (confirmed via grep). `pdf.scss`'s `.page--country`
  selector (zeroes the background for PDF export) repointed to `.vw-country` so that still matches.
- Two standalone spacer sections inside the page (`vw-base-spacer-small--bottom` around the
  restricted-country message and the citation) kept as direct `tw-shared-base-spacer-small--bottom`
  usage, not merged into a page-owned class — there's nothing else on those elements to compose
  with, so the bare shared utility already satisfies "one class per element."

**Not yet done, left for the rest of this wave:** `region/show.html.erb` (`page--region`) and
`protected_areas/show.html.erb` (`page--site`) still stack the pre-correction 3-class pattern
directly in markup — same treatment needed, but `_region.scss`/`_site.scss` have real content
beyond `flex-stack-mobile` (`.page__2cols`, `.page__col-wrapper`/`__col-1`/`__col-2`) that isn't
retireable by the shared utility alone, so don't assume either SCSS file is fully dead the way
`_country.scss` was — audit before deleting.

### Wave T3 correction — custom breakpoint tokens removed

User rejected the Wave T1 `--breakpoint-small/medium/large/xlarge` `@theme` tokens outright: "just
using md lg or 2xl rather than having legacy settings." Removed 2026-08-03. New mapping — legacy
`$small`(768px)→`md:` (exact), `$medium`(1025px)→`lg:` (1024px, ~1px off, immaterial),
`$large`/`$xlarge`(1201px/1441px — rare, just `shared/base.css`'s container padding and
`tw-shared-base-container--pame`'s width, 5 usages total)→`2xl:` (1536px), collapsing the two
rather than adding a distinct `xl:` step. Added **CODE-CONVENTIONS.md rule 21** so this doesn't
get reinvented in a later wave.

**Real bug found while doing the rename, not just cosmetic:** legacy `$small` (768px) is
numerically identical to Tailwind's own native `--breakpoint-md` (768px). A previous pass had
left native `md:` utilities mixed in on top of the custom `small:` token in `views/hero.css`,
`cta.css`, `social.css`, `footer.css` — intending `md:` to mean "the tier after small" (legacy
`$medium`/1025px) — but since `small:` and native `md:` fire at the exact same breakpoint, the two
utilities collided and the smaller-tier value silently never rendered (whichever rule landed
later in Tailwind's generated CSS won). Confirmed against the deleted legacy SCSS (recovered via
`git show <pre-deletion-commit>:app/assets/stylesheets/...`) — `_hero.scss`, `_cta.scss`,
`_social.scss`, `_footer.scss`, and `_helpers.scss`'s `responsive()`/`gutters()` mixins all
confirmed the two real tiers are `$small`(768)/`$medium`(1025), not `$small`(768)/native-`md`(768).
Fixed by promoting every mistranslated native `md:` to `lg:`. One spot (`vw-hero__text`, from
`hero-home`'s `.hero__text` `@include breakpoint($large)`) was pre-existing native `lg:` doing
duty for `$large`(1201) — moved to `2xl:` for consistency with the rest of this mapping.

**Two unrelated but build-blocking bugs hit and fixed while restarting `protectedplanet-vite` to
verify** (leftover mess from concurrent manual edits to this same branch, not from the breakpoint
work itself): `tailwind.css` still `@import`ed `./views/base.css` and `./views/background.css` —
both already deleted/moved into `shared/` earlier this wave — removed the dangling imports and
added the missing `@import './shared/background.css';` that had never been wired in; separately,
`views/content-banner.css`'s `vw-layouts-partials-hero-green-list__stat-text` used a typo'd `wrap-break-words`
(no such Tailwind v4 utility) instead of `break-words`.

Verified via `playwright-core` screenshots at 700/900/1100/1600px on the home page (hero sizing
steps, the 4-stat-tile row, footer partner-logo column reveal) — all correct post-fix, no visual
regressions. Also took the opportunity to wire every file under `app/frontend/styles/views/` into
`tailwind.css` (several — `chart-row`, `cms-layouts`, `error-page`, `home`, `search`,
`search-areas-home`, `static-cards`, `thematic-pages` — existed on disk but weren't imported yet).

---

## Wave T4 — Vue leaves with no existing styling (started, `NavBar/*` + `Listing/*` (+ `FiltersPanel`) + `Pagination` + `Download` + `TabStrip` + `Search/Index` + `SearchAreas` filter family slices done)

**First slice: `NavBar/{Index,Link,Dropdown}.vue`, backed by `components/_nav.scss` (deleted).**
Rewrote all three from zero-`<style>` legacy-class markup to `ct-nav-bar*`-prefixed Tailwind, per
the established T4 pattern. Sequenced first within T4 since it's the smallest, most self-contained
file group (one legacy SCSS file, three components, no cross-file sharing).

- `ct-nav-bar` (root, no legacy styling of its own — `.nav` never carried any rules directly, only
  scoped nested `.nav__*` selectors), `__pane` (`fixed`→`md:static` drawer, `translate-x-full`→
  `translate-x-0` slide, `duration-400`), `__close`/`__burger` (both `tw-shared-button-basic`),
  `__list` (`flex-col`→`md:flex-row`), `__item`.
- `ct-nav-bar-link` (own top-level BEM block per rule 4a, reused standalone for plain links) +
  `--current` modifier (`font-bold`, was `.is-current-page`). Font: reused the pre-existing
  `tw-shared-font-hind-siliguri__light-base-lg-lg` utility (`text-base lg:text-lg font-light`) —
  matches `text-nav-link`'s responsive 16/16/18px sizing (`$small`→`md:`, `$medium`→`lg:`, both
  collapsing to the same value below `lg:` per the established breakpoint mapping) at the same
  size/leading bucket as an existing utility, so no new one was needed.
- `ct-nav-bar-dropdown` (`relative h-full`) + `--active` (`md:z-3`, only gated above `md:` like the
  legacy rule), `__toggle` (`tw-shared-button-basic flex items-center gap-2.5`), `__icon`/
  `--active` (rotates 180° instead of swapping between two legacy chevron-up/-down background
  images), `__wrapper` (`hidden`→`block` on `--active`, `z-10` added so it layers above page
  content) + `__link` (254px-wide menu item, `hover:bg-theme-grey-dark hover:text-white`).
- New `Icon/Burger.vue` (three rounded bars, copied from legacy `burger.svg`). Reused existing
  `Icon/Close.vue` (already a generic X, sized via `size-5` to match legacy's 20×20px `icon-cross`)
  and `Icon/Arrow.vue` (already the established dropdown-chevron icon elsewhere, e.g.
  `Dropdown/Base.vue` — same 14×8px viewBox as legacy's chevron icons) rather than building new
  ones for either.
- **Dead markup found and dropped, not ported:** `Dropdown.vue`'s `<span class="drop-arrow
  arrow-svg">` had zero matching CSS anywhere (`grep` confirmed) — the *real* visible chevron came
  from `nav__dropdown-toggle-a`'s own `::after` pseudo-element (`button-dropdown` mixin), unrelated
  to that span. Replaced by a real `<IconArrow>` sibling per rule 5b instead of porting the dead
  span.
- **Dead override found and dropped:** the toggle button's stacked `hover--pointer flex-inline
  flex-v-center` utility classes were fully superseded by `nav__dropdown-toggle`'s own later-
  declared rule (`components/*` imports after `utilities/*` in `application.scss`, so on a
  specificity tie the component class always won) — confirmed real display was already `flex`, not
  `inline-flex`, before this migration touched it. Not ported.
- **Class-merging note for future T4 components using `NavBarLink`-style sub-components:** Vue's
  attrs fallthrough means a parent passing `class="foo"` to a child ADDS to the child's own
  template class rather than replacing it (unlike ERB's one-class-per-element rule, which governs
  markup, not Vue component composition) — `Dropdown.vue`'s toggle link deliberately relies on this
  and passes no extra class at all, since `Link.vue`'s own `ct-nav-bar-link` class already supplies
  everything the toggle needs. A plain, unprefixed `nav-bar-dropdown-toggle` hook class was added
  purely for Vitest selection (rule 4b's documented test-hook exception), carrying zero styling.
- Test-only class-name updates in `NavBar.spec.ts`/`NavBarDropdown.spec.ts`/`NavBarLink.spec.ts` (12
  tests, all still passing).
- Verified: `yarn typecheck`/`stylelint`/`vitest`/`vite:build` all clean; live Playwright check on
  the home page at 1400px (link font-weight/size/padding, hover-opened dropdown position/width/
  hover-color, all match legacy computed values) and 500px (burger visible, pane slides fully
  in/out via `translate`, close button works).
**Second slice: `Listing/{Index,List}.vue` + the shared `Filters/Trigger.vue`, backed by
`components/_listing.scss` (deleted) plus the `button-filter-trigger`/`icon-filters` mixins in
`base/_buttons.scss`/`helpers/mixins/_icons.scss` (both now dead, removed).**
`Listing/FiltersPanel.vue`/`FilterGroup.vue` were deliberately left alone — their own markup is
backed by `_filters-sidebar.scss`, shared with unmigrated `SearchAreas/FilterGroup.vue`, and belongs
to T9 per the plan doc's own file-boundary, not T4's `_listing.scss` scope.

- `ct-listing__bar`/`__bar-content`/`__main`/`__filters`/`__results-wrapper`/`__spinner` — straight
  port of `_listing.scss`'s mixins onto `tw-shared-base-container`/`tw-shared-shadow-bottom-grey-
  light`/native `md:`/`lg:` breakpoints (legacy `$small`→`md:`, `$medium`→`lg:`, per the established
  mapping). `ct-listing-list` (own top-level BEM block, `Listing/List.vue` is a separate SFC) for the
  `.listing__results`/`__cards-news`/`__cards-resources` family.
- **`Filters/Trigger.vue` fully closed out, not just re-skinned in place** — it's the shared
  `button-filter-trigger` mixin's only remaining consumer once `Listing/Index.vue`'s
  `listing__filters-trigger` fallthrough class and `SearchAreas/Page.vue`'s `search__filter-trigger`
  fallthrough class are both retired in favour of the component owning its own real style
  (`ct-filters-trigger`, `@apply tw-shared-button--outline-black` — its first live consumer). This
  also **unified a real behavioural inconsistency**: `search__filter-trigger.disabled` had real
  `button-disabled` styling (`_search-results-areas.scss`) but `listing__filters-trigger`'s own
  `.disabled` modifier never did (dead, zero-definition) — both call sites now share one working
  `ct-filters-trigger--disabled` (`@apply tw-shared-button--disabled`), fixing the Listing side's gap
  rather than preserving it as a legacy quirk, since this is the exact kind of "give the component
  its own real style" gap this migration wave exists to close.
- New `Icon/Filters.vue` per rule 5b (legacy `icon-filters`/`filter.svg`, `fill="currentColor"`) —
  closes the mixin (only consumer was `button-filter-trigger`) and the dormant, zero-consumer
  `tw-shared-icon-filters` utility in `shared/icons.css` (both removed).
- New `Icon/LoadingSpinner.vue` per rule 5b, replacing the `icon--loading-spinner`/`margin-center`
  background-image class combo on `Listing/Index.vue`'s spinner span — copied the legacy 12-bar SMIL
  `lds-spinner` SVG verbatim (`fill="currentColor"` swapped in per bar) rather than reinventing the
  animation. **Fixed a real, previously-inert dead-code bug in passing:** the `icon-visible` toggle
  class (used by this spinner plus 3 other still-legacy consumers — `Search/Index.vue`,
  `SearchAreas/Page.vue`, `Pame/Table/DownloadCsv.vue`) has zero CSS definition anywhere in the
  codebase, so the loading spinner has never actually appeared on any of the 4 call sites. Only the
  `Listing/Index.vue` consumer was fixed this round (`ct-listing__spinner`/`--visible` with a real
  `invisible`/`visible` toggle) — the other 3 stay on the dead `icon-visible` class until their own
  waves land; don't assume they're fixed too.
- `PaginationInfinityScroll.vue`'s default `triggerClass` renamed `pagination__infinity-trigger` →
  `ct-pagination-infinity-scroll__trigger` — this default class has never had any CSS either (purely
  a DOM hook for the `IntersectionObserver` sentinel), so this is a naming-only close-out, not a
  styling change. `SearchAreas/Results/Index.vue` always overrides `triggerClass` explicitly and is
  unaffected.
- **Real, pre-existing dead-code bug found and fixed in passing (unrelated to the class rename):**
  `Listing/List.vue`'s no-results message used a bare `search__results-none` class, which only has
  real CSS when nested under `.search--results-areas` (`_search-results-areas.scss`) — a context
  `Listing/List.vue` is never rendered inside, so the message has always rendered completely
  unstyled. Restored the evident intended look (20px bold, centered, 30px vertical padding, read
  directly off the same legacy rule) as `ct-listing-list__no-results`.
- Test-only class-name updates in `Listing/{Index,List}.spec.ts` (also fixed 4 *pre-existing,
  already-broken* assertions unrelated to this rename — `.card__h3` doesn't exist and hasn't since an
  earlier T7 session renamed `ListingPageCard/News/Card.vue`'s title to
  `ct-listing-page-card-news-card__title` without updating these Listing specs; confirmed broken
  on `master` before this session's changes via a `git stash` diff), `SearchAreas/__tests__/
  Page.spec.ts` (disabled-state class assertion), `PaginationInfinityScroll.spec.ts` (default class).
- Verified: `yarn typecheck`/`stylelint`/`vitest` (39/39 in the affected files, full suite unchanged
  at 8 pre-existing unrelated failures in `SearchSiteInput.spec.ts`/`Map/__tests__/Index.spec.ts`,
  confirmed via `git stash` to predate this session) /`vite:build` all clean; live Playwright check on
  `/en/news-and-stories` (bar shadow/border/padding, trigger height/border/color, mobile icon-only
  layout, filter-pane open/close) and `/en/search-areas` (shared `Trigger.vue` renders correctly)
  desktop 1400px + mobile 375px.
**Third slice, same day: `Listing/FiltersPanel.vue` + `Listing/FilterGroup.vue`** — user feedback after
reviewing the second slice ("you didn't migrate panel... you should have a panel for mobile another
one for desktop") asked for a real component split rather than one panel with responsive CSS classes,
matching the `NavBar/{Desktop,Mobile}.vue` precedent. Backed by `_filters-sidebar.scss` — **not
deleted**, since `SearchAreas/FilterGroup.vue`/`FiltersPanel.vue` are separate, still-fully-legacy
files sharing the exact same nested `&--sidebar { .filter { ... } }` block; confirmed zero overlap risk
via grep (SearchAreas has its own independent component files, no shared markup with `Listing`'s).

- **New `Listing/FiltersPanel/{Desktop,Mobile}.vue`**, `Listing/FiltersPanel.vue` demoted to a thin
  breakpoint switcher (`useBreakpoint()`'s `isLarge || isXLarge` → `Desktop`, else → `Mobile`) —
  exact mirror of `NavBar/Index.vue`'s `NavBarDesktop`/`NavBarMobile` shape, just JS-breakpoint-gated
  (`v-if`/`v-else`, single DOM tree at a time) rather than CSS-hidden (both always mounted) — a
  deliberate departure from the `NavBar` precedent since these two variants differ far more
  structurally (full-screen overlay drawer with a topbar+close footer vs. a plain inline sidebar
  column with neither), not just "hidden vs visible" cosmetically. **Cutoff is 1024px, not the legacy
  SCSS's 768px** (`_filters-sidebar.scss`'s `@include breakpoint($small)` flips to the "desktop" sidebar
  treatment at 768px) — a deliberate, user-directed simplification: tablet widths now get the mobile
  drawer too, on the reasoning that 768–1024px doesn't comfortably fit a persistent sidebar column
  next to results. Both variants keep the legacy's `v-show="isActive"` gating at every breakpoint
  (the "Filters" trigger button is unconditionally rendered at all widths in `Listing/Index.vue`, so
  even the desktop "sidebar" starts hidden until clicked — not a permanently-visible sidebar).
- `Listing/FilterGroup.vue` (shared by both panel variants — legacy `.filter`/`.filter__header`/
  `.filter__title`/`.filter__button-clear` have zero breakpoint distinction, so no split needed here,
  only the panel chrome around it) → `ct-listing-filter-group*`. Clear button's `::after`
  black-circle-white-cross pseudo-icon replaced with a real `<IconClose>` (already existed, reused
  verbatim per rule 5b) inside a `bg-black rounded-full` wrapper span.
- `Filters/Checkboxes/Index.vue`'s own `filter__options`/`flex-column` legacy classes **deliberately
  left untouched** — it's shared with other still-legacy filter surfaces (`SearchAreas`, `Pame`) and is
  its own separate, already-identified T4 line item (`Filters/Checkboxes/Item`), not part of "the
  panel" the user asked for.
- Test updates: `Listing/{FiltersPanel,FilterGroup,Index}.spec.ts` — class-selector renames, plus two
  new `FiltersPanel.spec.ts` cases that explicitly stub `window.innerWidth` (375/1400) to pin down
  which breakpoint each test exercises, rather than relying on jsdom's incidental default width (which
  happens to land in the mobile branch — verified via a first pass with the tests unpinned, then made
  explicit). New pattern for this codebase (`useBreakpoint`/`useWindowSize` had no prior spec
  precedent) — reset `window.innerWidth` in `afterEach` so it doesn't leak into later tests in the file.
- Verified: `yarn typecheck`/`stylelint`/`lint`/`vitest` (16/16 in `Listing/**`)/`vite:build` clean;
  live Playwright check on `/en/news-and-stories` at 1400px (static sidebar, border-right, no
  topbar/footer), 900px and 375px (both render the full-screen drawer with topbar + scrollable groups
  + black "View Results" footer) — screenshots confirm the breakpoint switch and visual shape match
  the legacy design intent at each tier.

- **Dating/attribution correction (2026-08-11 re-audit):** the "second slice"/"third slice, same day"
  narrative above described `Listing/{Index,List}.vue`, `Filters/Trigger.vue`, `Listing/FilterGroup.vue`,
  and `Listing/FiltersPanel/{Desktop,Mobile}.vue` as landing across two same-day (2026-08-10) commits.
  Re-verified against git history: all of that work, plus `Filters/Checkboxes/{Index,Item}.vue`, actually
  shipped together in one commit the following morning (`3d038da62 feat: migrate news resource page`,
  2026-08-11 09:20) — the doc/CHANGELOG got ahead of the actual commit by about a day. The technical
  content of every entry above is accurate against current code; only the dating/commit-grouping was
  wrong. Also corrected: `SearchAreas/InputAutocomplete.vue` was already fully migrated to
  `ct-search-areas-autocomplete*` back in `511c2f5eb feat: refactor search area input` (2026-08-07,
  pre-dating this wave's own baseline) — it was never actually part of T4's remaining scope, despite
  being listed below in earlier drafts of this entry.
- **Pagination family done, 2026-08-11: `Pame/Table/Pagination.vue` + `Search/Pagination.vue`, closes
  `components/_pagination.scss`** (41 lines, deleted) plus its now-dead-consumer mixins: `button-next`/
  `button-prev` (`base/_buttons.scss`), `icon-circle-chevron-{green,grey}-{left,right}`
  (`helpers/mixins/_icons.scss` — the `-large-left`/`-large-right` siblings are still live via
  `base/_icons.scss`'s `.icon--circle-chevron-green-large-prev/next`, left alone), and
  `text-pagination`/`text-pagination-no-results` (`helpers/mixins/_text.scss`). Both components were
  previously 100% legacy (`pagination`/`pagination__content`/`pagination__button--previous/--next`) plus
  a bolted-on `ct-*__button--disabled` class from an earlier session — now fully `ct-pame-table-
  pagination*`/`ct-search-pagination*`.
  - Dropped the outer `.pagination`/`.right`/`.left` wrapper classes — grepped, confirmed zero CSS
    definition anywhere (dead, no visual effect), so the two states (results / no-results) are now two
    sibling Vue-3 fragment roots instead of a no-op wrapper `<div>` around each.
  - `.bold` (on the item-count span) is a *real* legacy class (`font-weight: $bold` in
    `helpers/_helpers.scss`, unrelated to the also-dead `.bold`-adjacent classes T0 already swept) —
    ported as part of a new shared typography utility, `tw-shared-font-hind-siliguri__normal-base-lg-lg-grey-black`
    (sibling of the existing `__light-base-lg-lg`, same text-base/lg:text-lg/leading-1.3/grey-black
    shape, just bold), added to `shared/typography.css`.
  - No-results text ported to a new `tw-shared-font-hind-siliguri__normal-lg-md-xl-grey-dark` (sibling of
    the existing `__bold-lg-md-xl-grey-black`, swapping grey-black for `$grey-dark` — the legacy rule
    explicitly overrode color to grey-dark, not the family default).
  - **`Icon/CircleChevron.vue` extended, not duplicated**, with two new optional props: `direction`
    (`'left' | 'right'`, default `'right'`, applies `-scale-x-100` to mirror the arrow — compiles to
    Tailwind v4's CSS `scale` property, not `transform`, so verify via `getComputedStyle(el).scale`, not
    `.transform`, in any future live check) and `circleColor` (`'grey-black' | 'green' | 'grey'`,
    default `'grey-black'`, preserving the two pre-existing consumers' rendering unchanged). Pagination's
    prev/next buttons pass `circleColor="isXDisabled ? 'grey' : 'green'"` to reproduce the legacy
    `icon-circle-chevron-{green,grey}-{left,right}` swap-on-disable behaviour; `'grey'` uses an arbitrary
    `fill-[#f2f2f2]` value (no existing theme token matches that exact legacy grey).
  - **Real bug found and fixed during live verification, applies to every `Icon/*.vue` consumer, not
    just this one:** the icon's root `<i>` is `display: inline` by default (no Icon component sets its
    own display), so a sizing utility like `size-8.5` on it is silently a no-op per CSS spec (width/
    height don't apply to non-replaced inline elements) — confirmed live via Playwright, the icon
    collapsed to a 0×0 `getBoundingClientRect()`. The two pre-existing consumers (`Stats/Sites.vue`,
    `Attributes/Affiliations/Affiliation.vue`) never hit this because they happen to render the icon as
    a direct child of a flex container, which blockifies it per the CSS Display spec (same mechanism as
    the documented `inline-flex`→`flex` blockification gotcha) — pure luck, not a fix. This pagination
    component's buttons weren't flex containers, so it surfaced here. Fixed locally by making
    `.ct-*-pagination__button--previous/--next` `inline-flex items-center justify-center` (also the
    semantically-correct way to center an icon in a button) rather than touching the shared
    `Icon/*.vue` root — **worth a follow-up sweep of every other icon consumer once a non-flex context
    is used**, since the bug is latent in the icon-component pattern itself, not this call site.
  - Verified: `yarn typecheck` (2 pre-existing unrelated parse errors in `useMapBoundingBox.spec.ts`/
    `useMapLayers.spec.ts`, confirmed via `git stash` to predate this change), `stylelint` clean,
    `vitest` (9/9 in the two updated specs), `bundle exec rake assets:clobber && assets:precompile`
    clean (confirms the Sprockets side still compiles after removing the dead mixins), `vite:build`
    clean. Live-verified `/en/search` via Playwright at 1400px: bold "1 - 0 of 1396" text at the correct
    18px/grey-black, disabled previous button (grey circle, 20% opacity via `tw-shared-button--disabled`),
    active next button (green circle, correct 34×34px), correct 10px/6px spacing either side of the
    previous button. **Could not live-verify `Pame/Table/Pagination.vue`** — `/en/data/gdpame` (the only
    `PameTable` mount point) still 500s on a pre-existing Comfy CMS routing/seed-data gap in this dev
    environment (`ApplicationController::PageNotFound`), same gap T3 already flagged as unrelated to
    this migration; verified structurally via its (now-updated) Vitest spec instead. Flag for whoever
    next touches PAME to screenshot-verify once that route is fixed.
- **Download family done, 2026-08-11: `Download/{Index,Modal,Commercial,Popup,Item}.vue`, closes
  `components/_download.scss`, `components/modal/_modal-download.scss`,
  `components/modal/_modal-download-commercial.scss`, `components/_popup.scss`** (all 4 deleted)
  plus their now-dead-consumer mixins: `button-download`/`button-download-trigger`/
  `button-download-trigger-small` (`base/_buttons.scss` — grepped first, confirmed zero consumers
  outside the 2 deleted files that used them) and `icon-warning` (`helpers/mixins/_icons.scss` —
  same check, zero consumers left once `_modal-download.scss`'s `&__li-failed:before` went). Every
  other mixin these 4 files touched (`button-close`, `icon-cross`, `icon-close`, `icon-minus-white`,
  `icon-loading-spinner`) still has real consumers elsewhere (`_modal-pame.scss`, `_v-map-header.scss`,
  `_tooltip.scss`, `base/_icons.scss`, `_autocomplete.scss`, `_select-searchable.scss`) — left alone.
  - All 5 components had zero `<style>` blocks beforehand; rewritten to `ct-download*`/
    `ct-download-modal*`/`ct-download-commercial*`/`ct-download-popup*`/`ct-download-item*`.
  - **`.download__target`'s display-toggle wrapper `<div>` was dropped entirely, not ported as a
    `ct-download__target`/`--active` pair** — since `DownloadPopup` has no internal state to lose on
    unmount (unlike a polling `DownloadItem`), `showPopup` now gates it with a plain `v-if`, matching
    the `v-if`-is-safe precedent already established for `Tabs.vue`/`FiltersPanel/{Desktop,Mobile}`
    (MutationObserver-driven mounter, no forced `v-show`). Removes a class and a wrapper element for
    free; `.ct-download` itself keeps `position: relative` so `DownloadPopup`'s own `absolute`
    positioning still resolves against it.
  - **The two legacy fallthrough-class variants (`download--search` on `SearchAreas/Page.vue`,
    `download--small` on `_topbar-secondary.html.erb`'s `frontend_mount` call) were retired in favour
    of the component owning its own real style** — same "component owns its style, not the caller's
    CSS class" precedent as `Filters/Trigger.vue`'s `Listing`/`SearchAreas` fallthrough retirement in
    the slice above. Diffing `button-download-trigger-small`'s responsive rules against
    `.download--small`'s one extra `breakpoint-down($small) { width/height: 38px }` override showed
    the *only* real difference between the two legacy variants is that one extra mobile-only fixed
    38px square (vs. the shared default's 46px `height-small` square) — not two meaningfully distinct
    "modes." Modelled as a new boolean prop, `compact` (default `false`), on `DownloadProps`
    (`types/backend.ts`) rather than a caller-supplied class — `SearchAreas/Page.vue` now passes no
    class at all (its old behaviour *is* the default), `_topbar-secondary.html.erb` passes
    `compact: true` as a normal prop through `frontend_mount`.
  - **New icon components** (rule 5b: any icon a Vue component renders is a real `Icon/*.vue`, sized/
    colored by the consumer): `Icon/CircleClose.vue` (legacy `close.svg`'s circle+X — two-part
    `currentColor` fill, circle at `opacity-20` to match the original's baked-in `opacity:.203`, same
    per-part `<style scoped>` shape as `Icon/Pin.vue`; used for the download item's delete button —
    **not** the same shape as `Icon/Close.vue`, which is `cross.svg`/`icon-cross`, a different asset
    despite the similar name, reused as-is for the commercial modal's close button since that one
    really is `button-close` = `icon-cross`), `Icon/Minus.vue` (`minus-white.svg`, a single bar, for
    the download-modal minimise toggle), `Icon/Warning.vue` (`warning.svg`, for the failed-download
    status row — needed a new `--color-theme-red: #FA3232` token in `tailwind.css`'s `@theme`, no
    existing token was close). Reused as-is: `Icon/Download.vue` (trigger + item download link,
    both at the established `w-5 h-4.75` = legacy `icon-download-black`'s 20×19px) and
    `Icon/LoadingSpinner.vue` (item's "generating" status, `size-10` = legacy's 40×40px, same sizing
    precedent as its first use in `Listing/Index.vue`).
  - **Two sibling `<p v-show>` status rows (`hasFailed`/`isGenerating`) both needed their own BEM
    modifier** (`ct-download-item__status--failed`/`--generating`), not just a shared base class —
    a shared-only class made `wrapper.find('.ct-download-item__status')` ambiguous (always resolves
    the first, `failed`, DOM match regardless of which one `v-show` actually shows), silently breaking
    the "shows the generating state" spec's assertion until caught and split.
  - Per the "prefer `flex`/`grid` + `gap-*` over margin/padding on children" Decision — `Modal.vue`'s
    `.modal__li { margin-bottom: 10px }` (previously on every list item) moved to `gap-2.5` on the
    list container (`.ct-download-modal__list`) instead; `Modal.vue` also dropped the `class="modal__li"`
    fallthrough it passed into `<DownloadItem>` entirely, since `Item.vue` now owns 100% of its own
    row styling (was previously split: base row look from the parent's fallthrough, everything else
    from the child) — same fallthrough-retirement shape as the `compact` prop above, just for a
    child-component class instead of a caller-supplied one.
  - `--color-theme-red` aside, every other color/spacing value reused existing tokens/shared
    primitives (`tw-shared-button--download`, `tw-shared-button-basic`, `tw-shared-border-radius`,
    `tw-shared-shadow-grey`, `theme-grey-black`/`-xlight`/`-dark`/`-light`/`-xdark`) — no other new
    `@theme` tokens needed. `md:w-150`/`lg:w-187` (600px/748px) reused the exact numeric width already
    established for the commercial modal's own `md:w-187`, confirming the arithmetic (748÷4) is right
    both times it's used.
  - Verified: `yarn typecheck` (same 2 pre-existing unrelated parse errors in
    `useMapBoundingBox.spec.ts`/`useMapLayers.spec.ts` as the Pagination slice, re-confirmed via
    `git stash` to predate this change), `yarn lint` (0 errors among files this slice touched — the 4
    reported are pre-existing and unrelated, in `Carousel/Themes/Card.vue`/`SearchSiteInput.spec.ts`/
    the same 2 Map composable specs), `stylelint` clean, `vitest` (29/29 across all 5 updated specs +
    `SearchAreas/Page.spec.ts`), `vite:build` clean. Live-verified via Playwright on `/en/10467`
    (a real PA show page, since `/en/search-areas` still 500s on the pre-existing Comfy routing gap
    noted in earlier T4/T3 entries — confirmed structurally instead via `SearchAreas/Page.spec.ts`,
    already passing): desktop 1400px trigger (163×56px, text+icon visible); mobile 500px `compact`
    trigger (exactly 38×38px, icon-only); popup opens on click with the expected dark background and
    option list; selecting a commercial-available option opens the commercial dialog with real
    production copy (title/commercial/non-commercial sections, divider, purple "Continue" button);
    clicking "Continue" closes the dialog and opens the fixed-bottom download modal (dark topbar,
    citation text, a real in-flight "Generating…" item row with spinner + delete button); minimise
    collapses the modal to just its topbar. Full round-trip, no stubbing needed since a real dev-mode
    protected-area page has everything wired already.
- **`SearchAreas/TabStrip/{Index,Tab}.vue` done, 2026-08-11, closes `components/_tabs.scss`
  entirely** (deleted) plus its now-dead `button-tab-rounded` mixin (`base/_buttons.scss` — grepped
  first, confirmed zero consumers outside the file just deleted). `text-tabs-fake`
  (`helpers/mixins/_text.scss`) stays alive — still a real, separate consumer in
  `components/search/_search-results.scss` (T7 scope).
  - **4 real external fallthrough-class variants collapsed into one `variant` prop.**
    `Tab.vue`/`Index.vue` previously had zero styling of their own; every one of 4 different parent
    components (`Search/Index.vue` → `tabs--search-main`, `SearchAreas/Page.vue` →
    `tabs--search-areas`, `RegionCountryPages/Index.vue` → `tabs--rounded`,
    `SearchAreas/CheckboxSearch.vue` → `tabs--rounded-small`) passed a different fallthrough class
    into `<TabStrip>`. Same "component owns its style, not the caller's CSS class"
    precedent as `Filters/Trigger.vue`'s and `Download`'s fallthrough retirements above — added a
    required `variant: 'search-main' | 'search-areas' | 'rounded' | 'rounded-small'` prop instead,
    all 4 call sites updated to pass it as a normal prop, no `class="..."` left on any of them.
  - **Diffing the 4 variants' legacy CSS showed `Tab.vue` itself only ever needs a 2-way split, not
    the full 4-way one** — `search-main`/`search-areas`/`rounded` all `@include tabs-rounded`, whose
    `.tab__trigger` body (`button-tab-rounded` default size + `flex-no-shrink` + `margin: 0 10px`) is
    byte-identical across the three; only `rounded-small` calls `button-tab-rounded(small)` with a
    different font-size/padding and skips the `flex-no-shrink`/scroll-container shape entirely
    (`display: inline-block` items in a plain wrapping block, not a flex row). So `Index.vue` maps
    `variant` down to `Tab.vue` as a simpler `size: 'default' | 'small'` prop — the UL-level styling
    (spacing, scroll behaviour, centering) stays the full 4-way `variant` on `Index.vue`'s own root,
    only the tab pill itself collapses to 2 shapes.
  - Per the "prefer `flex`/`grid` + `gap-*` over margin on children" Decision — every variant's
    `.tab__trigger { margin: 0 10px }` (or `0 4px` for `rounded-small`) plus its accompanying
    `&:first-child { margin-left: 0 }` override (needed only because margin-based spacing leaves a
    stray leading gap) became `gap-5`/`gap-2` on the parent `<ul>` instead — the `:first-child`
    override is now unnecessary and was dropped, not ported.
  - **Real, if narrow, bug caught before shipping:** first draft copied `font-weight: $bold` onto the
    `--active` modifier, misremembering it from the *dead* `tab-trigger-underlined` mixin's own
    `&.active` block (which does set it) rather than the live `button-tab-rounded` mixin's `&.active`
    (which does NOT — only `background-color`/`color` change, weight stays regular). Caught by
    re-diffing against `git show HEAD:.../_tabs.scss` before shipping rather than trusting an
    earlier read of the file; fixed to drop `font-bold`.
  - **Confirmed-dead sub-scope removed in the same pass, not just ported around:** `.tabs--hero` and
    `.tabs--underlined` (plus the `tab-trigger-underlined`/`tabs-horizontal-scroll` mixins only they
    used) had **zero live consumers anywhere** — grepped `tabs--hero`/`tabs--underlined`/
    `tab__trigger`/`tab__target`/`tabs__triggers` across `app/views` + `app/frontend`, the only hit
    was `Tabs.vue`'s own unrelated, already-fully-migrated `ct-tabs__triggers`. Deleting these wasn't
    "moving a consumer" (T4's own discipline) since they had none to move — closer to a T0-style dead
    sweep that happened to surface while touching this exact file.
  - New `mountTabStrip()` spec helper (defaults `variant: 'rounded'`) since `variant` is now a
    required prop; added one new test asserting `rounded-small` maps to the `--small` tab size.
    Updated 3 other specs' `.tabs--search-main li` / `.tabs--search-areas li` selectors and every
    bare `'active'` class assertion to the new `ct-search-areas-tab-strip(-tab)?--*` names.
  - Verified: `yarn typecheck` (same 2 pre-existing unrelated parse errors as every prior T4 slice),
    `yarn lint`/`stylelint` clean, `vitest` (26/26 across the 4 touched specs), `vite:build` and
    `bundle exec rake assets:precompile` both clean. **Live-verified 3 of the 4 variants via
    Playwright** on real pages once the right locale-prefixed URL was found (`/en/search`,
    `/en/search-areas` — bare `/search`/`/search-areas` 500 on the same pre-existing Comfy
    routing/seed-data gap flagged in earlier T3/T4 entries, but `/en/...` routes correctly):
    `search-main` on `/en/search` (pill row, active-state swap on click, horizontal scroll at
    500px confirmed by the last pill scrolling off-screen), `search-areas` on `/en/search-areas`
    (same shape, `md:justify-center` centering visibly different from `search-main`'s left-align),
    `rounded-small` inside that same page's filters panel ("View sites within: Country/Region" pill
    toggle — smaller pills than the other 3 variants, confirmed visually distinct). **Could not
    live-verify `rounded`** — none of 15 sampled countries render `RegionCountryPages`' tab strip at
    all in this dev seed data (`tabs.length > 1` never true, i.e. no seeded country has both a WDPA
    and a WDPA+OECM effectiveness dataset) — verified structurally via its own passing spec instead,
    same as every prior wave's seed-data-gap components (Pagination's PAME table, etc.).
  - **Same-day follow-up: the 4-way `variant` prop above was simplified away to one universal
    style.** `TabStrip/Index.vue` now renders every consumer identically (`tw-shared-base-flex-gap-3
    overflow-x-auto`, `Tab.vue` always at `size="default"`) — the `variant` prop, its 4
    variant-specific style blocks, and the corresponding `variant="..."` attribute on all 4 call
    sites (`Search/Index.vue`, `SearchAreas/Page.vue`, `RegionCountryPages/Index.vue`,
    `SearchAreas/CheckboxSearch.vue`) were all removed. The detailed 2-way `size` split and the
    per-variant CSS documented above describe the *shipped-then-superseded* design, kept here for
    the reasoning trail (the legacy-mixin diff that found only 2 real shapes is still accurate
    background even though the shapes themselves didn't survive) — **the `--search-main`/
    `--search-areas`/`--rounded`/`--rounded-small` modifier classes and the `variant` prop no longer
    exist in the codebase.** Specs updated to match: `mountTabStrip()` no longer passes `variant`,
    the `rounded-small`→`--small` mapping test was removed, and every spec's
    `.ct-search-areas-tab-strip--<variant> li` selector was simplified to plain
    `.ct-search-areas-tab-strip li`.
- **`Search/Index.vue` done, 2026-08-11 — its root and spinner classes turned out to have zero real
  CSS anywhere already, nothing to delete, just to stop using.** `search--main` (the root `<div>`)
  has no matching rule in any `.scss` file, confirmed by grep — a fully dead class name, not even a
  T0-era oversight since it was never a real selector to begin with. The spinner span's
  `icon--loading-spinner`/`icon-visible` are likewise undefined anywhere; its third class,
  `search__spinner`, DOES exist — but only as `&__spinner` nested under `_search-results-areas.scss`'s
  `&--results-areas` block (i.e. the compiled selector is `.search--results-areas .search__spinner`),
  which is `SearchAreas/Page.vue`'s own root class, not `Search/Index.vue`'s `search--main` — so this
  specific usage never matched that rule either, a scope mismatch rather than a real shared
  dependency. Net effect: this component's loading spinner has been rendering completely invisible
  (no icon graphic, and even if one existed, `margin-center`'s `margin: 0 auto` has no effect on the
  span's default `display: inline`) on the live site this whole time.
  - New `ct-search-site` root (no styling of its own needed — `views/search.css`'s `vw-search`
    already supplies the container/padding this component mounts into) +
    `ct-search-site__spinner`/`--visible`, swapping the dead classes for a real
    `Icon/LoadingSpinner.vue` at `size-10 mx-auto my-13.75 text-black` — the exact same sizing
    already established for `Listing/Index.vue`'s own loading spinner (itself the first Tailwind port
    of this same `search-spinner` mixin's 55px vertical-margin value, reused here since both are
    "spinner shown centered below results while an ajax fetch is in flight" in the same shape).
  - **Real, if invisible-until-now, behaviour preserved as-is:** the spinner toggle logic
    (`invisible` base + `--visible` modifier driven by `loadingResults`) is unchanged from the legacy
    intent — only the previously-nonexistent graphic now actually renders. Verified live via
    Playwright that it now genuinely shows while a category-tab AJAX request is in flight and hides
    again once results update, on `/en/search`. (Aside, unrelated to this component: that same live
    check surfaced how slow this specific dev environment's Vite/Puma round-trip can be under
    concurrent asset load — a raw `fetch()` to the same URL resolves near-instantly, but the app's
    own fetch call sometimes took 10+ seconds to settle with many result-thumbnail requests in
    flight. Same territory as the already-documented Vite dev-server slowness elsewhere, not a
    regression from this change — don't mistake a slow `waitForTimeout` in a future live-check for a
    real hang.)
  - `Search/*`'s remaining children were already migrated in earlier T4 slices (`SiteInput` — Wave 3;
    `TabStrip` — this same session's earlier slice; `Pagination` — same day) — `Results/Index.vue`
    stays T7 scope (cards family), so `Search/*` is otherwise fully closed for T4 purposes now.
  - Verified: `yarn typecheck`/`stylelint` clean (same 2 pre-existing unrelated parse errors as every
    other T4 slice), `vitest` (6/6), `vite:build` and `bundle exec rake assets:precompile` both clean
    (no SCSS file was deleted this slice — nothing to break).
- **`SearchAreas/{RadioButtons,CheckboxSearch,FilterGroup,FiltersPanel}` done, 2026-08-11 — closes
  `components/form/_radio.scss` and `components/filters/_filters-sidebar.scss` entirely (both
  deleted).** All 4 components had zero `<style>` blocks beforehand.
  - **`_filters-sidebar.scss` turned out to be a two-component file, same shape as the T4 pattern
    established for `_tabs.scss`/`_download.scss`** — its one top-level `&--sidebar { .filter { ...
    } }` block backs BOTH `SearchAreas/FilterGroup.vue` (`.filter`/`__header`/`__title`/
    `__button-clear`/`__options`) AND `SearchAreas/FiltersPanel.vue` (`.filter__pane*`), which wraps
    every `FilterGroup` instance in the `.filters--sidebar` ancestor these rules are actually scoped
    under. Confirmed via grep that `Pame/Filters/Filter/Index.vue`'s similarly-named `.filter`/
    `.filter__button-clear`/`.filter__options` classes resolve against a completely different
    ancestor (`.filters--pame`, defined in the separate, untouched `_filters-pame.scss`) — a
    same-leaf-class-name coincidence, not a shared dependency, so migrating this file has zero effect
    on the still-legacy T8 PAME filters.
  - **`SearchAreas/FiltersPanel.vue` (flat file) split into `FiltersPanel/{Index,Desktop,Mobile}.vue`**,
    mirroring the `Listing/FiltersPanel` precedent (Wave T4 `Listing` slice above) — same
    `hidden lg:flex` / `flex lg:hidden` CSS-only toggle (both variants always mounted, not
    `v-if`/`v-else`, matching what `Listing/FiltersPanel/Index.vue` actually does today, superseding
    an earlier session's note that it used `v-if`/`useBreakpoint()`), same 1024px (`lg:`) cutoff.
    **One real difference from the `Listing` precedent, preserved rather than copied**: the original
    `SearchAreas/FiltersPanel.vue` aggregated every child `FilterGroup`'s `update:filter` payload
    into one `Record<string, unknown>` itself (`activeFilterOptions.value[id] = options`) before
    re-emitting — `Listing`'s version only forwards a single payload up, aggregating one level
    higher instead. Kept the aggregation in the new `Index.vue` switcher (not pushed down into
    `Desktop`/`Mobile`, which both need to funnel into the same shared map) to preserve
    `SearchAreas/Page.vue`'s existing `@update:filterGroup` contract unchanged.
  - **`SearchAreas/RadioButtons.vue`**: `.radio__input-fake`'s `::before` checked-dot now driven by a
    plain `:checked + &::before` CSS combinator (matching the legacy `.radio__input:checked +
    .radio__input-fake::before` structure 1:1) rather than Tailwind's `peer-checked:` mechanism,
    since rule 8 keeps utilities out of the template — `peer-checked:` would need a `peer` marker
    class on the input and the utility itself on the template's fake-radio span, which rule 8
    forbids. `$green` (the checked-dot colour) resolves to `$primary`/`theme-primary` via
    `_settings.scss`'s `$primary: $green;` alias — no new token needed.
  - **`SearchAreas/CheckboxSearch.vue`**: its lone `<input type="text">` used the bare, unnamed
    `input { }` element selector in `form/_input.scss` for basic border/padding/height/font (that
    selector stays — still backs every other un-migrated `<input>` site-wide) plus its own
    `.input--search`/`margin-space--bottom` for width/spacing, both now retired (zero other
    consumers, confirmed via grep) into one new `ct-search-areas-checkbox-search__input` class
    inlining all of it.
  - **`SearchAreas/FilterGroup.vue`**'s clear button reused the exact `Icon/Close.vue` +
    `size-4.5 rounded-full bg-black` circle treatment already shipped for `Listing/FilterGroup.vue`'s
    identical clear button (both are the same legacy `button-clear` mixin, `icon-cross-white` inside
    an 18px black circle) — same sizing, not just same shape, confirming the two "filter group
    clear button" implementations really were pixel-identical in the legacy source, not just
    similar-looking.
  - **Dead-mixin sweep, same file-touched discipline as every prior wave**: `input-hidden`/
    `input-custom-radio`/`input-custom-radio-selected` (`helpers/_form-fields.scss`, only consumer
    was `_radio.scss`), `button-clear` (`base/_buttons.scss`, only consumer was
    `_filters-sidebar.scss`), `text-filter` (`helpers/mixins/_text.scss`, consumers were exactly
    these two files, both now gone), and `item-center` (`helpers/_helpers.scss`, its only consumer
    was the now-deleted `input-custom-radio-selected`) — all confirmed zero remaining callers via
    grep before removal. **Also found already-orphaned from an earlier wave**: `input-custom-checkbox`/
    `input-custom-checkbox-selected` (same file as the radio mixins) had zero consumers anywhere —
    presumably dead since `form/_checkbox.scss` was deleted in the `Filters/Checkboxes` slice
    several sessions ago and nobody swept these two siblings at the time; removed in the same pass
    since they're the same mixin family in the same file.
  - New `SearchAreas/__tests__/RadioButtons.spec.ts` (no prior coverage existed) — this dev
    environment's seed data has no `type: 'radio'` filter live anywhere reachable (confirmed via
    Playwright: 0 `.ct-search-areas-radio-buttons` instances on `/en/search-areas`'s full filter
    panel), so this is the only verification for that component this round; `CheckboxSearch`/
    `FilterGroup`/`FiltersPanel` were all live-verified instead.
  - Verified: `yarn typecheck`/`yarn lint`/`stylelint` clean (same 2 pre-existing unrelated parse
    errors as every other T4 slice), `vitest` (48/48 across the full `SearchAreas`+`Search`
    directories, including the new spec), `vite:build` and `bundle exec rake assets:precompile` both
    clean. Live-verified via Playwright on `/en/search-areas`'s real filters panel: the clear-button
    circle+X icon on every filter group header, the `checkbox-search` search input actually narrowing
    a 30-country list down to 2 matches on "fra", and the desktop/mobile panel split correctly
    swapping at the 1024px breakpoint (full-screen drawer with dark "View Results" footer on mobile,
    static bordered sidebar column on desktop) — `protectedplanet-web` OOM'd mid-session during this
    verification pass (exit 137, unrelated to this change) and needed a plain `docker start` to
    recover; noting since a future session hitting the same exit code shouldn't assume its own
    change caused it.
- **`SearchAreas/Page.vue`'s own root/container classes done, 2026-08-11 — closes T4's last piece of
  `SearchAreas/*`.** New `ct-search-areas-page` root (+`__bar`/`__main`/`__filters`/`__results`/
  `__spinner`), reusing `tw-shared-base-container`/`bg-theme-grey-xlight` and the same
  `Icon/LoadingSpinner.vue` spinner treatment already established for `Listing`/`Search/Index`.
  - **Found while auditing "which child classes actually have real CSS" (prompted by a user question
    pointing at this exact file):** `.search__bar` (the OLD wrapper `<div>` around `search__bar-content`)
    and `.search__map`/`.search__map-container` had **zero remaining consumers anywhere** — the first
    because an earlier concurrent edit already flattened `search__bar-content` to a direct child of the
    root (no wrapper div left to match `.search__bar`'s selector), the other two because this page never
    rendered a map at all in its current form. Deleted from `_search-results-areas.scss` without
    porting, confirmed via grep first same as every prior dead-class finding this wave.
  - **`&__results`/`&__results-none`/`&__results-bar` de-nested, not deleted** — these three still back
    `SearchAreas/Results/Index.vue` (T7 scope, untouched), but the `&--results-areas` wrapper they used
    to sit under is gone now that `Page.vue`'s own root retired that class. De-nesting to bare
    `.search__results { }` etc. keeps the file an accurate reference for whoever does T7 next, even
    though (per the file's own new comment) the enclosing `_search.scss`'s `.search { @import ... }`
    still mechanically re-nests them one level — harmless since the legacy stylesheet isn't linked on
    live pages regardless.
  - `search-spinner` mixin (`_search.scss`) and 3 already-dead `$search-input-size-*` variables (never
    referenced anywhere, confirmed via grep, unrelated pre-existing debt swept in the same pass) removed.
  - **Real audit method worth reusing**: loaded the live page in Playwright, walked every element under
    the component's root via `document.querySelectorAll('*')`, collected every class name, then checked
    each one against `document.styleSheets`' actual parsed `CSSRule.selectorText` list (not a text grep
    of the compiled CSS, which is JS-string-escaped by Vite's HMR wrapper and doesn't grep cleanly) —
    cleanly separated "real Tailwind class" from "legacy class with zero CSS anywhere" across the whole
    subtree in one pass, confirming every `ct-*` class from prior slices resolves and isolating exactly
    which legacy classes were this component's own remaining gap.
  - Verified: `yarn typecheck`/`stylelint` clean, `vite:build` and `bundle exec rake assets:precompile`
    both clean. Live-verified via Playwright on `/en/search-areas`: `ct-search-areas-page` background
    resolves to `rgb(244,244,244)` (`theme-grey-xlight`), filters column measures 313.5px at a 1400px
    viewport (27.5% of the ~1140px content width, exact match). **3 pre-existing spec failures found
    while testing, not caused by this change** (confirmed via `git stash` isolation attempts and direct
    code inspection) — 2 trace to `TabStrip` being relocated out of `SearchAreas/` into a new top-level
    `components/TabStrip/` during this same session (separate, still-in-progress restructuring), 1 to
    `FiltersPanel/Index.vue`'s root gaining a `v-if="isActive"` gate on both breakpoints (an earlier
    concurrent edit) that the affected spec doesn't open the panel before asserting against.

---

## Wave T5 — Maps (`Map/*`, 8 sub-islands + `_map.scss` + `_autocomplete.scss`) — done

**Pre-work audit found the plan doc's own T5 section was stale in three ways, all confirmed via grep/
`git log` before writing any code:**
1. No `_map-section` ERB partial exists to migrate — `app/views/partials/maps/_main.html.erb`/
   `_header.html.erb` were already deleted 2026-07-24 (`b29bc3c555 feat: migrate all maps over`,
   `256e23b37 feat: remove map header`). All 7 `frontend_mount "Map"` call sites already sit inside an
   already-migrated `vw-*__map`/`vw-*__overview` wrapper from earlier T2/T3 work — nothing left to do
   there.
2. The legacy Vue2 map + CDN `mapbox-gl.js` is fully gone (`app/javascript/components/map/*` deleted
   2026-07-24, `vendor/assets/javascripts/mapbox.js` deleted 2026-08-03 in `ff4acf88e`) — the `.mapboxgl-*`
   half of every duplicated `_map.scss`/`_v-map-popup.scss` selector (and one in `pdf.scss`) has been
   dead weight for weeks, not "kept for a still-live legacy map" as the file comments claimed.
3. `.map--header`/`--search`/`--site`/`--country`/`--region` (the 5 height-variant modifiers `_map.scss`
   defined for different page contexts) and `.map__trigger` were **never actually applied anywhere** —
   `Map/Index.vue`'s root has always been hardcoded `class="map--main"` regardless of page. Only one
   height variant (`map--main`'s 360px/700px) was ever live; baked directly into `Base.vue`'s own canvas
   class below rather than porting a dead variant system.

**Also found, not previously documented:** `_v-map-disclaimer.scss`'s `--embedded` modifier and both
copies of `.v-map-pa-search__dropdown` (duplicated across `_v-map-filters.scss`/`_v-map-pa-search.scss`,
a leftover from the deleted legacy `Selector.vue`) had zero consumers — dropped, not ported.
`_v-map-toggler.scss`'s entire `&:hover` block turned out to be a genuine Sass nesting bug — `&__switch`/
`&__active` nested directly inside `&:hover` compiles to the invalid selector fragment `:hover__switch`/
`:hover__active` (verified by actually compiling the file with `sass`) — the toggler has never had a
working hover state in any browser; **not ported**, per the standing "preserve pre-existing bugs, don't
silently fix unrelated things" rule. `.v-map-filter__active-toggler` and `.v-map-filters__overlays`/
`__overlay` were real template classes with **zero** backing CSS even before this wave — carried forward
as unstyled `ct-` structural classes (`ct-map-filter__active-toggler`, `ct-map-panel__legends`/
`__overlay`), not invented styling. `Map/PaSearch.vue` turned out to depend on a 9th, previously-unlisted
legacy file (`components/_autocomplete.scss`) — its sibling consumer, `SearchAreas/InputAutocomplete.vue`,
already migrated off it in T4, leaving `PaSearch.vue` as sole owner; deleted alongside the 8 named files.

**Rewrite, one `ct-map-<name>` BEM block per SFC** (`Index`→`ct-map`, `Base`→`ct-map-base`,
`Header`→`ct-map-header`, `Panel`→`ct-map-panel`, `Disclaimer`→`ct-map-disclaimer`,
`Filter`→`ct-map-filter`, `BaselayerControls`→`ct-map-baselayer-controls`,
`PaSearch`→`ct-map-pa-search`, `Toggler`→`ct-map-toggler`) — closes `PaSearch.vue`'s own file-header
comment claiming a "same exception as Wave 3" unprefixed-class carve-out, which (per the T7 precedent)
the actually-enforced `stylelint-bem-namics` config never granted anyone.

- **The mobile/desktop dual-header swap is real, deliberate legacy behaviour — preserved via the same
  Vue-attrs-fallthrough class pattern `NavBar/Index.vue` established** (`class="ct-nav-bar__mobile"` /
  `__desktop`), not `:deep()`: `Index.vue` passes `class="ct-map__header"` (`flex md:hidden`) onto its
  own standalone `<MapHeader>` instance (visible above the map on mobile, where `Panel` hasn't started
  floating yet), while `Panel.vue` passes `class="ct-map-panel__header"` (`hidden md:flex`) onto its
  *own* internal `<MapHeader>` instance (visible once the panel floats over the map at `md:`) — exact
  opposite visibility rules on the same child component, driven entirely by which parent mounts it.
  Live-verified via Playwright at 1400px (outer hidden, panel header visible) and 375px (outer visible,
  panel header hidden) on the home page — swaps correctly both ways.
- **Icon-in-Vue-component rule 5b applied**: `Header.vue`'s open/closed toggle now renders real
  `Icon/Close.vue`/`Icon/Minus.vue` (`v-if`/`v-else`, both already existed, exact shape match to the
  legacy `cross-white.svg`/`minus-white.svg`) instead of a CSS-class-driven background-image swap;
  `PaSearch.vue`'s magnifying-glass/delete buttons likewise swapped to `Icon/Search.vue`/`Icon/Close.vue`,
  mirroring `SearchAreas/InputAutocomplete.vue`'s established structure (`__bar`/`__input`/`__delete`
  naming, `tw-shared-icon-button-reset` for the reset styling) almost verbatim, just dark-themed instead
  of light. **One genuine exception, flagged rather than silently worked around**: `useMapPopups.ts`'s
  `.v-map-pin` map marker is created via `document.createElement('div')` inside a composable, not a Vue
  template — there's no render tree to mount an `Icon/*.vue` SFC into at that point, so it keeps the
  existing `tw-shared-icon-pin-map` CSS utility (renamed from `.v-map-pin`, not deleted) as a deliberate
  rule-5b carve-out for this one imperative-DOM case, alongside the ERB-view-chrome carve-out already on
  the books. No new test precedent existed for asserting "which of two Icon components is rendered" —
  added one (`Header.spec.ts` now uses `findComponent(IconClose/IconMinus)`).
- **`useMapPopups.ts`'s hardcoded popup-content class strings renamed `mapboxgl-popup-content__*` →
  `maplibregl-popup-content__*`.** These only ever resolved to real CSS because `_v-map-popup.scss`'s
  comma-selector duplicated every rule under both prefixes — deleting the now-dead `.mapboxgl-*` half of
  that selector without this rename would have silently unstyled every live popup. The dead
  `className: 'v-map-pa-popup'` option (zero CSS anywhere, confirmed via grep) was dropped from the
  `Popup` constructor call, not renamed forward. `mapboxgl-popup-content__title`/`__link`/`__value` had
  **zero CSS before this wave either** (a pre-existing, separate gap — popup title/value/link text has
  always rendered with no visual distinction) — left as-is, not fixed in passing.
- **Global, library-imposed selectors moved out of any component's scoped style into `shared/map.css`**,
  since `stylelint-bem-namics` rejects a bare `.pdf`/`.maplibregl-*` ancestor class inside a Vue SFC's
  own scoped block (confirmed by literally running `yarn stylelint` — `:global()` isn't in the config's
  `ignorePseudoClasses` allowlist alongside `:deep()`, so that escape hatch doesn't work here either) —
  same "global cross-page override lives outside the scoped file" pattern `views/site.css`'s
  `.pdf .vw-protected-areas__col-1/2` already established. Covers the MapLibre zoom-control buttons (ported 1:1 from
  `_map.scss`'s pixel values, `.mapboxgl-*` half dropped) and the popup content/tip/close-button styling
  (ported 1:1 from `_v-map-popup.scss`, same drop). `Disclaimer.vue`'s own `.pdf`-ancestor border override
  moved there too for the same reason, with a comment pointing back at the pattern.
- **`pdf.scss` updated in lockstep** (separate, still-active Sprockets pipeline, out of this migration's
  scope but never silently left broken per the standing rule): `.v-map-baselayer-controls` →
  `.ct-map-baselayer-controls`, `.mapboxgl-ctrl-top-right` → `.maplibregl-ctrl-top-right` (the latter was
  already dead before this wave touched it, per finding #2 above — fixed while already in the file for
  the former's rename, not a separate scope expansion).
- **`helpers/_accessibility.scss` fully deleted** (its `.screen-reader{}` class was already removed in
  T0; `.v-map-filters--hidden` — now `.ct-map-panel--hidden`, ported to native Tailwind `sr-only`, a
  byte-for-byte match confirmed by reading the mixin body — was its last surviving `@include` consumer
  anywhere in the codebase). Removed its `@import` from `_helpers.scss`.
- **9 legacy files deleted**: the 8 named `components/maps/*.scss` + `_map.scss` +
  `components/_autocomplete.scss` (9, not 8, per the `PaSearch.vue` finding above) +
  `helpers/_accessibility.scss`.
- Verified: `yarn typecheck`/`stylelint`/`yarn lint` clean on every touched file (2 pre-existing unrelated
  parse errors in `useMapBoundingBox.spec.ts`/`useMapLayers.spec.ts` reproduced identically before this
  wave, same as every prior wave's note). `yarn vite:build` and `bundle exec rake assets:clobber
  assets:precompile` both clean. `yarn vitest run app/frontend/components/Map`: 36/37 passing — the one
  failure (`Index.spec.ts`'s "forces the panel hidden when isHidden is passed") is **pre-existing**,
  reproduced identically via `git stash` against the untouched HEAD version of the same test: the test's
  own premise doesn't match `Index.vue`'s actual `v-if="isHidden"`/`v-else` branching (when `isHidden` is
  true, `MapPanel` doesn't render *hidden* — it doesn't render *at all*, `MapDisclaimer` renders instead),
  a test/component design mismatch predating this wave entirely, not touched. Separately,
  `useMapPopups.spec.ts`'s 3 tests were **already failing on HEAD before this wave** for an unrelated
  reason — the spec does `const { useMapPopups } = await import(...)` (named-export destructure) against
  a file that only ever had `export default function (...)` — confirmed via `git show HEAD` on the
  composable, zero coverage of this composable currently runs; flagged here, not fixed (outside this
  wave's actual scope, a pre-existing test-infra bug).
- **Live-verified via Playwright** (`playwright-core` direct, chromium already cached locally, no
  `chromium-cli` available in this environment, same as every prior Maps-adjacent wave): home page at
  1400px and 375px (header swap, panel positioning/width-at-breakpoint, filter rows + working toggler
  click + baselayer-control selected-state styling, disclaimer, zoom controls, map tiles all rendering),
  country page (the `isHidden: true` disclaimer-only path — confirmed zero header/panel elements render,
  disclaimer + zoom controls + baselayer control all correctly styled), `/en/data/wdpca`'s tab-extras
  mount (identical rendering to home, confirms the shared component works the same regardless of mount
  site), and the PA-search input's visual appearance (pill shape, icon placement, dark theme) while
  typing. **Could not live-verify a real point-query popup** — clicking the map canvas and the
  PA-search-to-zoomTo flow both depend on external ArcGIS-style query services this dev sandbox can't
  reach (consistent 500s in the browser console, unrelated to this change); relied on `Base.spec.ts`'s
  existing passing Vitest coverage of `zoomTo`'s popup HTML content instead, same as every prior wave's
  seed-data/network-gap components. Toggler hover state intentionally not verified — confirmed dead code,
  see above.

---

## Wave T6 — Charts + Stats (done)

**Pre-work audit found two more doc-drift issues:** `AmChart/Multiline.vue` was already fully migrated
(`ct-am-chart-multiline*`) via an undocumented commit — real progress was 2/13, not the doc's claimed
1/13, before this session. More seriously, **`Stats/Sites.vue` had become a live regression**: Wave T7
deleted `cards/cards/_cards-search-results-areas.scss` on the strength of "confirmed zero other
consumers," but never checked `Sites.vue`'s own "other protected areas" card grid, which depended on
that exact file (`cards--search-results-areas preview`, `card__link`/`__image-placeholder`/`__image`/
`__content`/`__title`) — it had been rendering completely unstyled since T7 landed. Fixed as part of
this wave, not filed separately.

- **`AmChart/Pie.vue`** → `ct-am-chart-pie*`. `.chart__chart`'s padding rule was dead (a same-element,
  not-descendant selector — `class="am-chart--pie chart__chart"` sat on one div, so the compiled
  `.am-chart--pie .chart__chart` descendant selector never matched); not ported. `.chart__svg`'s
  `height: 280px` was a real descendant match — ported as `h-70`. `_am-chart-pie.scss` deleted.
- **`Chart/RowStacked.vue`** → `ct-chart-row-stacked*`. Its type (`ChartRowStackedRow`)'s own doc comment
  confirms its only real caller is `Stats/Designations.vue`, which never triggers the legacy mixin's two
  variants directly — it relies on an ancestor class (`chart--row-stacked--designation`) the parent
  passes via attrs fallthrough. Rebuilt fully self-contained instead: no `theme` prop → per-bar colour
  from a new 12-entry palette (`tw-shared-chart-theme-1..12`, `shared/themes.css`, matching `$theme-chart`/
  `PIE_COLOURS` order — the same order already used by `AmChart/Pie`'s JS-side colours) with alternating
  above/below tooltip placement by index (ports the legacy `chart-bars`/nth-child mixins); `theme` prop
  given → single colour for every bar via the existing `tw-shared-chart-legend-colour-*` classes, tooltip
  always above (the legacy `--basic` variant — real but untriggered by any caller today; ported as
  genuinely working code rather than left dead, same precedent as T4's `Trigger.vue` disabled-state fix).
  The tooltip "speech bubble" reuses `TotalCoverageChart.vue`'s already-established caret pattern
  (`tw-shared-border-radius` + `before:border-x-13` triangle) — confirmed the legacy `chart-tooltip`
  mixin's `::before`/`::after` double-caret was redundant (both render the same colour, so only one
  triangle is ever visually distinct; a single `before:` caret is a faithful, not simplified, port).
  `_chart-row-stacked.scss` deleted, plus `_charts.scss`'s now-fully-dead `chart-target-line`/
  `chart-scrollable`/`chart-tooltip` mixins and 4 unused `$chart-*` variables — zero remaining `@include`
  callers anywhere once `_chart-line.scss` (already dead — see next item) and this file were gone.
- **`_chart-line.scss` deleted** — confirmed zero consumers even before this wave; its sole would-be
  trigger (`chart--line`) had already stopped rendering once `AmChart/Multiline.vue` migrated away from
  it in the earlier undocumented commit this session's audit surfaced.
- **`Stats/Designations.vue`** → `ct-stats-designations*`, consuming the new `ChartRowStacked` and the
  same 12-colour palette for its own legend-key swatches (one shared source of truth for both, instead of
  the legacy's two separate but identical nth-child rainbow implementations). Jurisdiction sub-list uses
  new `app/frontend/styles/shared/list.css` (`tw-shared-list-underline-*`, porting the `list-underline`/
  `list-scrollbar` mixins) — the first real consumer of `tw-shared-scrollbar`, which had sat pre-built
  and consumer-less since T1. `list__a`'s `::after` chevron background-image → a real `Icon/
  CircleChevron.vue` per rule 5b. New `app/frontend/styles/shared/card.css` (`tw-shared-card-stats`) ports
  the legacy `card-stats` mixin, including its `.pdf &` override as a plain (non-`@apply`-scoped) rule —
  can't live inside a Vue SFC's scoped style, same stylelint-bem-namics restriction Wave T5's `shared/
  map.css` hit. `_card-stats-designations.scss` deleted (zero consumers once `card--stats-designations`
  itself stopped being rendered).
- **`Stats/IucnCategories.vue` + `Stats/Governance.vue`** → `ct-stats-{iucn-categories,governance}*`,
  sharing the new `tw-shared-card-stats-half`/`tw-shared-card-stats-wrapper` (`shared/card.css`, the
  legacy `card--stats-half`/`--wrapper`) and `shared/list.css` for their `list--underline` rows. Porting
  both side by side surfaced that the legacy `theme-chart-list-icon` mixin already ran unconditionally
  for *every* `list--underline` consumer — `Governance`'s own `.theme--governance` modifier
  (`list-theme($theme-chart)`) turned out to be a byte-for-byte duplicate of the same nth-child logic,
  not a distinct visual; both components now just get the palette unconditionally, no modifier needed.
  "View list" links ported to `Icon/CircleChevron.vue` + `max-lg:hidden` text (the legacy
  `text-indent: -9999px` mobile icon-only technique). `_card-stats-iucn.scss` deleted.
  `_card-stats-governance.scss` **also deleted, but it was already fully dead before this wave** —
  `Governance.vue` has only ever rendered `card--stats-iucn`, never its own same-named file's
  `card--stats-governance` class (confirmed via grep: zero consumers, ever).
- **`RegionCountryPages/Index.vue`** (the wrapper nesting the whole Stats family on country/region pages
  — not separately named in the plan doc's component list, but load-bearing) — its `card--stats-toggle`/
  `card--stats-wrapper` wrapper divs now use `tw-shared-card-stats`/`tw-shared-card-stats-wrapper`. Closed
  `_card-stats.scss`'s own `&--stats-wrapper`/`&--stats-toggle` blocks (zero other consumers) and deleted
  `_card-stats-toggle.scss` outright (its only content was the now-closed `&--stats-toggle`).
  `&--stats-half`/`&--feault-block` stay in `_card-stats.scss` — `Stats/Coverage.vue` and `Stats/
  Sources.vue`/`Attributes/ProtectedArea/Source/List.vue`/`Dropdown/ParcelsDropdown.vue` (T8) still need
  them.
- **`_card-stats-overlap.scss` deleted** — turned out to never even be `@import`ed by `_card-stats.scss`
  (missing from its own import list), on top of having zero template consumers. Pure pre-existing dead
  weight, unrelated to any of this wave's own changes.
- **`Stats/Sites.vue` regression fixed** (see pre-work audit note above) — rebuilt as `ct-stats-sites*`,
  mirroring `SearchAreas/Results/Item.vue`'s already-established card shell (same legacy file family)
  rather than reinventing one, plus two behaviours specific to this "preview" usage that `SearchAreas`'s
  version never needed: hide the 3rd card on mobile (`:nth-child(3)` + `max-md:hidden`) and the legacy
  trailing-lone-2nd-of-3 centering hack (`:not(:first-child, :nth-child(3n+1), :nth-child(3n)):
  last-child`). No placeholder-icon fallback needed — unlike `SearchAreas`'s optional `image`,
  `thumbnail_link` is a required field on this component's props.
- **Still open**: `Stats/{Sources,Coverage,Message,TooltipInfo}` and all of `Attributes/*` (`Pame`,
  `ProtectedArea`, `ProtectedArea/Source`, `Affiliations`) remain 100% legacy — the rest of `_lists.scss`'s
  consumers and `card/stats/{affiliations,coverage,overview,related}.scss` / `_card-stats.scss`'s
  `&--feault-block`. `_chart-square.scss` (`Stats/Coverage.vue`) and `_chart-legend.scss`'s `--map`/
  `--points-poly` blocks (ERB-only, via `_stats-overview.html.erb`/`_stats-overview-country.html.erb` — a
  full `card--stats-overview` card, not yet touched) are the remaining live pieces of the charts family.
  `_stats-related-countries.html.erb` (ERB, reuses `list--underline` + `card-stats`) is small and could
  close alongside `Attributes/*`'s pass.
- Verified: `yarn typecheck`/`stylelint`/`yarn lint` clean (the only failures are the 2 pre-existing
  unrelated TS parse errors in `useMapBoundingBox.spec.ts`/`useMapLayers.spec.ts`, reproduced identically
  on unmodified HEAD, same as every prior wave's note). `yarn vite:build` and `bundle exec rake
  assets:precompile` both clean. `yarn vitest` all green except one pre-existing failure
  (`TotalCoverageChart.spec.ts`'s legend-colour assertion — reproduces identically via `git stash` against
  untouched HEAD, unrelated to this wave). **Live-verified via Playwright** (`playwright-core` from the
  npx cache, no `chromium-cli`/local install available in this environment): `/en/country/BRA` (has real
  designation-jurisdiction data — pie donut chart, per-bar/per-swatch rainbow colouring, tooltip caret
  bubble, "View list" chevron links, jurisdiction scrollbar list all rendering and computed-style-correct)
  and `/en/country/KEN` (iucn/governance two-card row, 555px each at 1400px viewport — exact
  `calc(50%-15px)` match against an ~1140px container). **Could not live-verify `Stats/Sites.vue`'s fix**
  — needs a country/region with >1 `site_details` and a working region-page route; this dev environment's
  region pages 500 (same seed-data gap noted since T3) and no country tried had >1 site with a thumbnail.
  Verified by code-reading against the deleted legacy SCSS and the `SearchAreas/Results/Item.vue`
  reference instead.

**Same-day continuation: `_lists.scss`'s remaining consumers + `Attributes/*` (11/~13 done overall).**

- **`Stats/Sources.vue`** → `ct-stats-sources*`. Its root was `card--feault-block` (the same `@include
  card-stats` mixin `Designations`/`IucnCategories`/`Governance` already reuse) plus `_lists.scss`'s
  `list--underline-sources` variant, ported as new `tw-shared-list-underline-scrollbar` +
  per-field `md:w-[15%]/[40%]/[45%]` widths in `shared/list.css`. Dropped `sm-sources` — a bare class
  with zero backing CSS anywhere, confirmed via grep across the whole tree (shared verbatim with
  `Attributes/ProtectedArea/Source/List.vue`, see below — not carried forward in either).
- **`Stats/Message.vue`** — already had a partial `<style>` block from an earlier pass (its own two
  link-variant classes); closed the remaining gap. `card--message`/`card__warning` confirmed to have
  **zero backing CSS anywhere**, even in the legacy source — carried forward unstyled, not invented.
  New `tw-shared-list-links-item` (`shared/list.css`) for the chip-row list.
- **`Attributes/Pame/{List,Pame}.vue`** — `card--attributes-pame`/`list--stripes` →
  `ct-attributes-pame-list*`/`ct-attributes-pame*`, reusing `tw-shared-card-stats` and new
  `tw-shared-list-stripes-item`/`-title`. The legacy `.pdf &` override targets the *root card itself*
  (flex-col, 2rem gap between multi-parcel instances in PDF mode) — not `.card__all-attributes` as a
  first read suggested; that class turned out to be a pure marker with zero own CSS, dropped from the
  template entirely rather than carried forward unstyled. `card__h3` (the per-parcel subtitle) traced to
  an unrelated `card-news` mixin (T3, already migrated) that Pame's own `<h3>` never actually matched —
  confirmed unstyled, same treatment as other dead-class findings this wave. `_card-attributes-pame.scss`
  deleted.
- **`Attributes/ProtectedArea/{Index,AttributeList}.vue`** — same `list--stripes` shell as Pame,
  `card--attributes-pa-and-parcels` → `ct-attributes-protected-area*`. Unlike Pame, this root is *always*
  `flex flex-col gap-4` regardless of PDF mode — the PDF-only piece here is `.card__all-attributes`
  itself gaining `flex-col gap-16`, a genuinely different shape from Pame's file despite near-identical
  markup (a reminder that "looks the same" isn't "is the same," per this wave's own recurring theme).
  `_card-attributes-pa-and-parcels.scss` deleted.
- **`Attributes/ProtectedArea/Source/{Attributes,List}.vue`** — same `card--feault-block`/
  `list--underline-sources` shell as `Stats/Sources.vue`, confirmed byte-for-byte identical legacy
  markup by reading both side by side, ported the same way. `Attributes.vue` (the leaf) has no card-stats
  root of its own — it's always nested inside `List.vue`'s, so its `card__h2`/`card__content` rules were
  only ever real via that ancestor relationship in the compiled CSS; same conclusion, applied here.
- **`Attributes/Affiliations/{Affiliation,Index,List}.vue`** — `card--stats-affiliations` →
  `ct-attributes-affiliations*`. Two dead-code findings preserved, not "fixed": `.card__button`
  (`translations.more`) is `display: none` in the legacy source with its own "to be added later"
  comment — ported hidden, matching the file's own stated intent to finish it later, not this wave's job
  to do that; and `.card__subtitle--link`'s flex/no-underline rules were never actually paired with the
  base `.card__subtitle`'s bold/margin in the real markup — the two classes were never stacked on the
  same element in the legacy template, so only the modifier's own rules ever applied. Preserved as two
  independent, non-overlapping classes rather than "corrected" to the BEM modifier-implies-base
  convention the legacy code never actually followed. `card__logo`/`card__h3` confirmed unstyled, same
  as Pame's. `_card-stats-affiliations.scss` deleted.
- **`_stats-related-countries.html.erb`** (ERB — `country/show.html.erb`'s `relatedCountriesHtml` prop,
  rendered server-side then injected into `RegionCountryPages/Index.vue` via `v-html`) →
  `vw-partials-stats-stats-related-countries*` per rule 4c's path-mirroring convention, new
  `views/partials/stats/stats-related-countries.css`. The first ERB (non-Vue) consumer of either
  `tw-shared-card-stats` or `tw-shared-list-underline-*`. Its "View" link's chevron — a real
  `Icon/CircleChevron.vue` in every Vue consumer this wave — becomes the pre-existing
  `tw-shared-icon-circle-chevron-black` CSS background-image utility instead, since a `link_to` helper
  call has no Vue render tree to mount a component into (rule 5b's existing ERB-view-chrome carve-out,
  not a new exception). `_card-stats-related.scss` deleted.
- **`_card-stats.scss` trimmed further**: removed the now-dead `&--feault-block .card__content` rule
  (its `card-stat-content` mixin has no remaining caller under this selector once `Stats/Sources.vue`
  and `Attributes/ProtectedArea/Source/List.vue` migrated away from it — `Dropdown/ParcelsDropdown.vue`,
  the one real `card--feault-block` consumer left, uses its own unrelated `card__top` class, confirmed via
  reading the component directly) and the now-dead `card-button-external` mixin (its one caller was the
  just-deleted `_card-stats-affiliations.scss`). `&--feault-block`'s `card-stats` include and `.card__h2`
  rule stay — `ParcelsDropdown.vue` (T8, out of scope) still needs both.
- Verified: same clean `yarn typecheck`/`stylelint`/`yarn lint`/`vite:build`/`bundle exec rake
  assets:precompile` results as the first slice above (identical 2 pre-existing TS parse errors, nothing
  new). `yarn vitest` on every touched directory: 27/27 passing, plus a re-run of `Dropdown/*` (touched
  indirectly via the shared `_card-stats.scss` trim) confirming no regression there either.
  **Live-verified via Playwright**, including working around two environment quirks discovered this
  session: (1) individual PA pages 500 under the `/en/:id` locale-scoped route but 200 under the plain
  `/:id` route registered outside the `(:locale)` scope — used `/142`/`/767` instead; (2) a component's
  first request after a Vite dev-server restart can take several seconds to compile
  (`waitForSelector` rather than a fixed `waitForTimeout` avoided a false "not found" on the first
  `Attributes/ProtectedArea`/`Pame` check). PA `/767` ("Jirisan", Republic of Korea) has real PAME
  assessment + attributes + sources data — confirmed the striped `Attributes/ProtectedArea`/`Attributes/
  Pame` columns (odd/even shading, bold titles, correct two-column layout) and the `Stats/Sources` card
  all render correctly. **Could not live-verify `Attributes/Affiliations`** — no PA tried had real
  affiliation data; verified by code-reading against the sibling `Attributes/Pame`/`ProtectedArea`
  components (same shared utilities, same card-stats shell) instead.

**Final session: `Stats/{Coverage,TooltipInfo}` + the `card--stats-overview` ERB card +
`_chart-legend.scss`'s last two live variants — T6 fully closed (13/13).**

- **`Stats/Coverage.vue`** → `ct-stats-coverage*`, reusing `tw-shared-card-stats`/`-half`. The legacy
  `theme--${type}` square (`_chart-square.scss`) becomes two real modifiers, `--marine`/`--terrestrial`
  (`bg-theme-blue`/`bg-theme-bright-green` — both pre-existing tokens, exact hex matches for
  `$marine`/`$terrestrial`), confirmed via `CountryPresenter#yml_key` that the real prop value is always
  one of those two strings, never the literal `'land'` its own Vitest fixture uses (a pre-existing
  test/reality mismatch — not fixed, same no-matching-modifier outcome as before). `_card-stats-coverage.
  scss`/`_chart-square.scss` deleted; the now-fully-dead `card-stat-content`/`card-stats-number` mixins
  removed from `_card-stats.scss`, and its `&--stats-half` block too (dead — every real consumer had
  already moved to `tw-shared-card-stats-half` earlier this wave).
- **`Stats/TooltipInfo.vue`** → `ct-stats-tooltip-info*`. `.carousel__tooltip` (the class it passed onto
  `TooltipSecond`) had zero backing CSS anywhere — dropped, not ported.
- **The ERB `card--stats-overview` card** (`_stats-overview.html.erb`/`-country.html.erb`, identical
  apart from two extra `StatsTooltipInfo` mounts — same "one shared file" precedent as T3's
  `error-page.css`) → `vw-partials-stats-stats-overview*`, new `views/partials/stats/stats-overview.css`.
  `.card__flag.icon--flag-outline`'s two stacked legacy classes merged into one (`__flag`);
  `.card__subtitle-margined.card__flex`/`.card__subtitle.card__flex`'s stacked pairs each became one
  combined class (`flex` wins over the subtitle mixin's own `display: block` in the legacy cascade — it's
  there to sit the label next to `StatsTooltipInfo`'s trigger icon, the intended outcome, not an
  accident). `.card__external-text` confirmed zero backing CSS, same as `Stats/Message.vue`'s
  `card__warning` earlier this wave — carried forward unstyled. `card__external-button`'s `@extend
  .button--link-external` (an icon-only `::after`, no colour/font of its own) → the existing
  `tw-shared-icon-arrow-external` utility via `after:`, ERB's standard rule-5b icon carve-out.
  `_card-stats-overview.scss` deleted whole — every rule in it turned out to belong to either this ERB
  card or `TooltipInfo.vue`, nothing left over.
- **`_chart-legend.scss`'s `--map`/`--points-poly` blocks** (the last two live variants — `--designation`
  moved into `Stats/Designations.vue` earlier this wave, `--vertical` already dead) →
  `_chart-legend.html.erb` rewritten to `vw-partials-charts-chart-legend*`, new `views/partials/charts/
  chart-legend.css`. `row[:theme]` was previously a **full legacy class-name string built in Ruby**
  (`'theme--primary'`, `'theme--terrestrial'`, etc., from `{country,region}_presenter.rb#chart_point_poly`
  and `map_helper.rb#map_legend`) stacked directly onto `chart__legend-key` — interpolating that into a
  `vw-` element would mean ERB rendering a raw legacy class name directly, which rule 4c forbids. Changed
  all three Ruby call sites to emit a short key instead (`'primary'`/`'primary-dark'`/`'terrestrial'`/
  `'marine'`/`'oecm'`), so the partial builds its own `vw-partials-charts-chart-legend__key--<variant>-
  <key>` class from data it fully controls. Same fix for `_chart-row.html.erb` (→
  `vw-partials-charts-chart-row*`, new `views/partials/charts/chart-row.css`), the other consumer of the
  same `chart_point_poly` rows — `chart__bar-overseas` (zero consumers anywhere, confirmed via grep)
  dropped, not ported. `_chart-legend.scss`/`_chart-row.scss` deleted, and with them `components/
  _charts.scss` itself (empty once both were gone) — `components/charts/` no longer exists as a
  directory.
- **Typography-routing fix, same session**: `Coverage.vue`/`TooltipInfo.vue`/`stats-overview.css`
  initially landed with raw `text-*`/`font-*` combos instead of a named `shared/typography.css` utility,
  inconsistent with how every other T6 component already routes size+weight(+colour) combos (a lone
  `font-bold` or `text-sm` with nothing else stays bare — only genuine combos get a named utility). Added
  two utilities with no existing match (`tw-shared-font-hind-siliguri__normal-4xl`,
  `...bold-3xl-md-4xl-leading-none-primary`); everything else composed onto what already existed — e.g.
  the ERB card's `card__h1` (20→25px bold white) reuses `tw-shared-font-hind-siliguri__normal-xl-white` +
  `md:text-2xl`, since `--text-2xl`'s custom 1.565rem token is an exact match for legacy's 25px.
  `TooltipInfo.vue`'s literal `color: black` (not the site's usual `grey-black`) folded into
  `tw-shared-font-hind-siliguri__light-base-grey-black` — the only place in the codebase that ever used
  true black instead of grey-black, read as an authoring slip, not a deliberate distinct colour.
- **This wave closes the Wave-8 `Stats*`/`ChartRowPa`/`ChartRowStacked` rule-4 exception** — removed from
  CODE-CONVENTIONS.md's exception-precedent list.
- A stale `showSitePid` prop reference in `Attributes/ProtectedArea/__tests__/AttributeList.spec.ts` —
  left over from the user's own concurrent `showSitePid`→`forPdf` prop rename earlier this wave — was a
  real regression (the test silently stopped exercising the site-pid-row branch), fixed in this pass.
- Verified: `yarn typecheck`/`stylelint`/`yarn lint`/`vite:build`/`bundle exec rake assets:precompile`
  all clean (same 2 pre-existing TS parse errors, nothing new). `yarn vitest` on every touched directory:
  all green except the one pre-existing `TotalCoverageChart.spec.ts` legend-colour failure (reproduces
  identically via `git stash`, unrelated to this wave). **Live-verified via Playwright**: `/en/country/
  BRA` for the full stats-overview card end to end (flag, heading, h1, map legend's 3 correctly-coloured
  swatches, the polygons/points chart-row bar + its own legend) with computed font-size/weight/colour on
  `__h1`/`__number`/`__subtitle-margined` matching the ported typography exactly; `/en/country/
  {USA,IND,DEU}` for `StatsTooltipInfo`'s trigger icon. `Stats/Coverage.vue` itself never appeared on any
  country tried in this dev environment's seed data — verified by code-reading + its own passing Vitest
  spec instead, the same seed-data-gap pattern as `Stats/Sites.vue`/`Attributes/Affiliations` earlier
  this wave.

---

## Wave T7 — Cards family, Listing cards, Carousel (almost done)

`Search/Results/{Index,Item}.vue` migrated (2026-08-13). `Index.vue`'s root/total/grid are now
`ct-search-results`/`ct-search-results__total`/`ct-search-results__list` — the list uses `flex flex-col
gap-y-5` rather than porting the legacy `margin: 20px 0` onto each card, per the flex/grid-over-margin
Decision. `Item.vue` is `ct-search-results-item*`; the no-image fallback now renders
`Icon/PlaceholderImage.vue` per rule 5b instead of leaving the background-image `:style` empty, mirroring
`SearchAreas/Results/Item.vue`'s already-established pattern (same legacy card family). Added
`tw-shared-font-hind-siliguri__bold-lg-md-xl-grey` to `shared/typography.css` for `.search__total`'s
count text (`text-tabs-fake` mixin: bold, `$grey`, 18px/`$small`→20px — no existing utility matched).
The legacy `.card__title`/`.card__summary` selectors for this family were empty rules (bare
browser-default `h3`/`p`, no deliberate font treatment ever existed) — left with no `@apply`
counterpart rather than inventing one that changes current visual behaviour. `cards/cards/
_cards-search-results.scss` and `components/search/_search-results.scss` deleted (plus `_search.scss`'s
`@import` of the latter) — confirmed zero other consumers via grep; `.search`'s own `&--pa` block
(unrelated, same root selector) is untouched.

**Doc-drift fix, same pass**: this wave's checklist had `Attributes/ProtectedArea/*` listed as
"still 100% legacy," referencing a `_card-attributes-pa-and-parcels.scss` file that no longer exists —
that work was actually done under **T6** (see `Attributes/ProtectedArea/{Index,AttributeList,Source/*}`
entries above) but this wave's own tracking was never updated to say so. Corrected in the plan doc; only
`Dropdown/ParcelsDropdown.vue` remains open for T7.

**Unrelated pre-existing bugs fixed while verifying**: the "same 2 pre-existing TS parse errors" noted
in T6's verification above (`useMapBoundingBox.spec.ts`/`useMapLayers.spec.ts`, both `import x from from
'@/...'` — a duplicated `from`) were genuine typos, not environment noise; fixed both so `yarn
typecheck` is clean of them. A broader `yarn typecheck`/`yarn vitest` pass surfaced a separate, larger
set of pre-existing failures in `Map/__tests__/{Filter,Panel}.spec.ts`, `useMapPopups.spec.ts`, and
`Attributes/Affiliations/__tests__/List.spec.ts` (missing/renamed exports, stale required-prop
mismatches) dating back to the T5 Maps and T6 Attributes waves — left untouched as out-of-scope for this
wave (unrelated component families, non-trivial fixes each), but flagged here so they aren't mistaken
for something this wave introduced.

Verified: `yarn typecheck`/`yarn lint`/`yarn vite:build` clean (module classes confirmed present in the
compiled dev bundle via grep — `ct-search-results*`, `bold-lg-md-xl-grey`). `yarn vitest` on
`Search/Results/`: all 5 tests green (2 new/updated specs asserting the new class names + a new
placeholder-icon-fallback case). Live-browser verification not yet done this pass — re-check `/en/search`
results with and without a `summary`/`image` present.

**Wave closed (2026-08-13)**: `Dropdown/ParcelsDropdown.vue` — the last open T7 item — migrated to
`ct-parcels-dropdown*`, reusing `tw-shared-card-stats`/`tw-shared-list-title`/`tw-shared-list-underline-value`.
`card/attributes/_card-attributes-parcels-dropdown.scss` and the now-fully-dead `_card-stats.scss`
deleted. T7 is now **done**.

---

## Wave T8 — PAME + Dropdown + Select (done)

Closes the Wave 9 `Dropdown` and Wave 10 `Pame/*` rule-4 exceptions.

**`Dropdown/Base.vue` + `Dropdown/Options.vue`** — both already rendered `ct-dropdown*` markup with no
`<style>` block (styled by legacy `components/_dropdown.scss`). Added real `@apply` styles:
`Base.vue`'s outline button reuses `tw-shared-button--border-theme-primary` (an exact match for the
legacy `button-outline($black,1px)` mixin once compared property-by-property); `Options.vue`'s dropdown
list reuses `tw-shared-shadow-grey` for the legacy `box-shadow-grey` mixin. Mid-wave the block/element
name was renamed `ct-dropdown` → `ct-dropdown-base` (by hand, concurrently) to disambiguate from
`Options.vue`'s own `ct-dropdown-options` — picked up and propagated into `Base.spec.ts`/
`ParcelsDropdown.spec.ts`, both of which were still asserting the pre-rename class names. `_dropdown.scss`
deleted.

**`Pame/Modal.vue`** — `ct-pame-modal*`. Legacy `.modal__close` used the `button-close` mixin
(`icon-cross` background-image); replaced with a real `Icon/Close.vue` per rule 5b, matching
`NavBar/Mobile.vue`'s established close-button pattern. `z-300`/`z-400` (legacy `$z-300`/`$z-400`) are
valid bare Tailwind v4 utilities, not arbitrary values — no bracket syntax needed. Legacy `$small`
(767px) breakpoint mapped to native `md:`, matching the established precedent. `_modal-pame.scss`
deleted.

**`Pame/Filters/*` family** — `ct-pame-filters`/`ct-pame-filter`/`ct-pame-filter-option`. The filter
toggle button's chevron and the checkbox's tick mark were both legacy background-image swaps
(`chevron-{black,white}-{down,up}.svg`, `tick.svg`); replaced with real `Icon/Arrow.vue` (rotated via
`rotate-180` for the open state) and a new `Icon/Tick.vue` (traced the SVG back to an old
"Coral_Reff_Funding_Landscape" asset — unrelated to PAME, just reused — confirmed via the model's own
`PameEvaluation.filters` that only `method`/`country`/`year`/`type`/`site_type` are real filters).
That check also confirmed the legacy SCSS's `--category`/`--donors`/`--ocean-region` per-filter
max-width variants are dead — no such filter exists — so only the real `--country` variant was ported;
the other two were dropped rather than migrated. `_filters-pame.scss` deleted.

**`Pame/Table/*` family** — root shell `ct-pame-table` (the bare `pame` hook class on the wrapper had
zero CSS anywhere — dropped). Legacy `$large` (1200px) breakpoint — a third tier distinct from
`$medium`/`$small` — mapped to native `xl:` (nearest unclaimed tier) for the desktop-table/mobile-card
switch. `Row/Index.vue` (desktop `<tr>`) → `ct-pame-table-row*`; a `::before` label rule with no
`content:` set (hence never rendering) was correctly left unmigrated as genuinely dead CSS.
`Row/Mobile.vue` (the card-list view) had real CSS for only 2 of its ~11 classes
(`table__list-items`/`table__list-item-label`) — the other 9 per-field modifier classes
(`--name`/`--designation`/etc., including a pre-existing `able__list-item--site-id` typo) had zero
backing rules anywhere and were dropped rather than carried forward. `Row/SiteId.vue`
(`pame-site-id*`) was always unstyled — renamed only, no `<style>` added, to avoid inventing spacing
that never existed. `Head/Index.vue`/`Head/Cell.vue` → `ct-pame-table-head*`; the sort-direction icons
(also a decorative-only holdover, per the component's own code comment) got the same real-`Icon/Arrow`
treatment as the filter chevron. `Table/DownloadCsv.vue` (already `ct-`/`@apply`-based from an earlier
undocumented pass) had one dangling legacy spinner (`icon--loading-spinner`/`margin-center`/
`icon-visible`, the last two with zero CSS) — closed out using `tw-shared-icon-loading-spinner`, and
`Table/Index.vue`'s identical spinner got the same treatment. `table/_table-pame.scss`,
`table/_table-head-pame.scss`, and `components/_table.scss` (the `.filtered-table` shared class, now
`ct-pame-table`) deleted.

**Confirmed-dead files deleted, no migration needed**: `table/_table-horizontal-scroll.scss` +
`table/_table-head-horizontal-scroll.scss` — a second, entirely separate "horizontal-scroll" table
variant with zero Vue/ERB consumers, ever (its `.tooltip__target` reference was already stale — see
next). `_tooltip.scss` — both `Tooltip/Index.vue` and `Tooltip/Second.vue` turned out to already be
fully `ct-tooltip*`/`ct-tooltip-second*` migrated from an earlier undocumented pass, so the legacy
`.tooltip*` classes had zero live consumers left. `components/_select.scss` +
`components/select/{_select,_select-searchable}.scss` — confirmed (per this doc's own T8 "not
independently confirmed" flag) that `Search/SiteInput.vue`'s existing Tailwind styling supersedes them;
`select/_select.scss` turned out to never even be `@import`ed (dead on arrival). `base/_buttons.scss` —
zero remaining `.button`/`.button--*` class consumers and zero remaining `button-*` mixin consumers
across the whole stylesheet tree once the files above were migrated/deleted.

**Verified**: `yarn typecheck`/`yarn lint` clean (only pre-existing, unrelated T5/T6 debt remains — same
15 files / 28 tests as before this wave, none in `Dropdown`/`Pame`/`Icon`). Full `yarn vitest` run and
targeted `Dropdown`/`Pame`/`Icon` runs both green after fixing the renamed-class test fallout. Live
Playwright verification on `/en/data/global-database-on-protected-area-management-effectiveness`:
filters open/close, checkbox + tick icon + badge counter, Apply correctly filters (and correctly shows
"no records" + disables CSV when a filter yields zero results), modal opens/closes with real content,
sticky table header holds on scroll, mobile viewport switches to the card-list layout, no new console
errors. Did not find a real multi-parcel PA in the dev dataset to click through to `ParcelsDropdown` live
(seed data limitation) — covered instead by the full green `Dropdown`/`ParcelsDropdown` Vitest suite.

---

## Wave T9 — Residual tabs/filters coupling (done, no code changes needed)

Re-audited before starting (per this doc's own repeated drift lesson) and found the whole wave
already closed by same-day, undocumented direct commits after the T8 session ended. `_tabs.scss` and
`_filters-sidebar.scss` no longer exist on disk. All 5 named components already render fully
`ct-`-prefixed markup with real `<style scoped>`: `SearchAreas/CheckboxSearch.vue`, `SearchAreas/
FilterGroup.vue`, `Listing/FilterGroup.vue`, `RegionCountryPages/Index.vue`; `SearchAreas/Index.vue`
turned out to be a thin wrapper with no markup classes of its own. Nothing to do — see T10 for what
the same re-audit turned up instead.

---

## Wave T10 — Finish (done, 2026-08-14)

**Found a live-breaking bug while re-auditing T9**: `bundle exec rake assets:precompile` was failing —
`components/_filters.scss` and `components/_modal.scss` (left behind by T8's deletion of
`_filters-pame.scss`/`_modal-pame.scss`) still `@import`ed those now-gone files. This had been broken
since 2026-08-13, silently — it would break any real deploy, and specifically PDF export, since
`_head.html.erb` links `application.css` whenever `@for_pdf` is true. `bin/rails runner` is still
broken in this container (see [[t8-pame-dropdown-select-wave-done]]) — verified via `docker exec
protectedplanet-web bundle exec rake assets:clobber assets:precompile` directly instead.

**Fixing it cascaded into finishing this wave's whole SCSS-deletion checklist in one pass.** A fresh
`class="..."`-usage grep sweep (careful to exclude `ct-`/`tw-shared-`/`vw-` substring false positives,
e.g. `cards--resources` inside `ct-listing-list__cards--resources`) found the **entire remaining
legacy SCSS tree had zero live consumers left**, 24 files beyond the two broken ones: `components/
{_search,_cards}.scss` + `components/{cards,form}/**` (`.search--pa`, `.card--message`, `.cards--
{articles,basic,resources}`, and the bare `input {}` tag selector — every real `<input>` consumer,
e.g. `Search/SiteInput.vue`, already has its own scoped styles); `base/_base.scss` (already fully
commented-out since preflight+Tailwind fonts took over); `base/{_circles,_icons,_svgs,_themes}.scss`;
`base/_fonts.scss` (legacy MuseoSans/MuseoSlab `@font-face`, fully superseded by `app/frontend/
styles/fonts.css`'s self-hosted Hind Siliguri/Playfair Display); `helpers/_cms.scss` (already flagged
dead in T3); `helpers/{_background,_beautify-scrollbar,_border-and-shadows,_form-fields,_images,
_helpers}.scss` (closing T3's long-open `.block`/`.bold`/`.ul-unstyled`/etc. item — all zero
consumers now); `helpers/mixins/{_cards,_icons,_layout,_text}.scss`; `utilities/{_flexbox,
_media-queries}.scss`. Kept `utilities/_rem-calc.scss` — `_settings.scss` itself calls `rem-calc()`
for its own variables. `application.scss` rewritten to just import `rem-calc`+`settings`; confirmed
the compiled output is now byte-for-byte empty (`sha256` of `''`), consistent with the 2026-08-07
finding that `application.css` hasn't been linked on normal page loads for a while (PDF-only).

**`pdf.scss`'s fate — decided as option (b), left on the Sprockets/sassc path.** It only imports
`settings` (zero dependency on anything just deleted) and every selector it references is either an
already-live Tailwind-era class or a pre-existing, harmless dead Leaflet-era leftover (`.pa-card`,
`.leaflet-control*`, from before the MapLibre migration). Porting its 39 lines to hand-written CSS
(option a) would add risk for no benefit. **Because of this, `sassc`/`sass-rails` stay in the
Gemfile** — they're the only thing left compiling `pdf.scss`/the `application.scss` stub.

**`bourbon`/`neat` removed** — confirmed zero remaining usage anywhere in the 5-file tree above (they
were never used by `_settings.scss`, `_rem-calc.scss`, or `pdf.scss`). Removed from `Gemfile` +
`config/initializers/assets.rb`'s `assets.paths` entry; `bundle install` completed clean (both gone
from `Gemfile.lock`); re-ran `assets:precompile` after — still clean.

**Verified**: `assets:clobber assets:precompile` clean after every deletion batch; `bundle install`
clean after the gem removal. Live PDF-export smoke test — `GET /country/USA?for_pdf=true` → 200, both
`pdf.self-*.css`/`application.self-*.css` `<link>` tags resolve, `.pdf` root class present in the
rendered HTML. Live Playwright check (home, country, 1400px, after restarting the crash-prone
`protectedplanet-vite` container per [[vite-dev-server-optimize-deps-crash]]): both fully styled, zero
visual regression (expected — none of the deleted classes had live consumers). Remaining console
noise is pre-existing/unrelated: a Playwright-vs-dev-server WebSocket HMR handshake warning, and
`/search` 500ing with `PageNotFound in ProtectedAreasController#show` — the same seed-data routing
gap T3 already documented, confirmed via the server log to predate this session.

**Not done, deliberately deferred**: enabling Tailwind preflight + the full-site visual sweep it
needs. Risk is much lower now (there's no legacy SCSS left to fight at all), but it's still the one
previously-forbidden change and deserves its own dedicated verification pass rather than being folded
into an already-large session. This is the one remaining checklist item in the entire plan.

### T10 continued, same day — `pdf.scss` decision flipped from (b) to (a)

A follow-up request ("consolidate all PDF CSS into `global/pdf.css`, plus any other globally-used
CSS into the same folder") led to actually doing what option (b) above had deferred. The fact that
flipped the risk calculus: `entrypoints/layout.ts` already `import`s `tailwind.css` unconditionally
— not gated on `@for_pdf` — so anything added to a new `app/frontend/styles/global/pdf.css` would
already be live on PDF-rendered pages regardless of whether the old Sprockets `pdf.scss` link stuck
around. Porting was no longer "two systems computing overlapping styles" risk; that overlap already
existed the moment `global/pdf.css` got any content, so removing the redundant old half was strictly
a cleanup, not a behavior change.

All 39 lines of `pdf.scss` ported into `global/pdf.css` — unlayered plain selectors (as documented
by the pre-existing comment in `protected-areas.css`), `@apply` where a Tailwind utility exists,
raw `page-break-*`/`break-*` properties otherwise. Folded in the three previously-scattered `.pdf
`-scoped override blocks that already lived in `shared/card.css`, `views/protected-areas.css`, and
`views/partials/stats/stats-overview.css` (same convention, same file each was "waiting" to move
into once one existed). Root wrapper class renamed `.pdf` → `.tw-global-pdf` to fit the new folder's
naming scheme (`layouts/application.html.erb` + every consumer updated — grepped for stray `.pdf`
class assumptions in Vue/TS, found none; the few string matches were unrelated `forPdf`-prop-driven
classes like `ct-stats-message__link--pdf`). Also moved `styles/fonts.css` (ambient `@font-face`,
applies with zero opt-in class — same "global" semantics as the PDF mode flag) into
`global/fonts.css`, distinguishing `global/`'s role (ambient, automatic) from `shared/`'s (opt-in
`@apply` utilities).

Two pieces of the old `pdf.scss` were dropped rather than ported, confirmed dead by grep before
deleting (mark-and-sweep discipline, not scope creep): the entire `&--protected-area` nested block
(`.pa-card`, `.leaflet-control*`, `.flex-2-fiths`/`.flex-3-fiths`, `.js-tab-content.u-hide` — its
trigger class `.pdf--protected-area` was never applied by any consumer, so the whole block was
unreachable) and `.modal--download.active`/`.card__stat-box` from the display:none list (zero
consumers, same as the classes inside the dropped block).

With `pdf.scss` gone, `_settings.scss` (only import left was `pdf.scss`), `utilities/_rem-calc.scss`,
and the `application.scss` stub had zero remaining consumers — deleted all three. `app/assets/
stylesheets/` now contains only the out-of-scope `comfy/admin/cms/custom.scss`. Dropped the
`@for_pdf`-gated `stylesheet_link_tag 'pdf'/'application'` block from `_head.html.erb` (its own
comment explaining why it existed went with it) and the now-dangling `assets.precompile += %w(
pdf.css )` line from `config/initializers/assets.rb`. Removed the explicit `sass-rails` gem from the
Gemfile. `sassc-rails`/`sassc` deliberately kept — `comfortable_mexican_sofa` depends on
`sassc-rails (>= 2.0.0)` directly, so they stay in `Gemfile.lock` regardless, still compiling the
out-of-scope admin `custom.scss`.

**Verified**: `docker exec protectedplanet-web bundle install` clean (395 gems, `sass`/`sass-rails`
gone from `Gemfile.lock`, `sassc`/`sassc-rails` still present as expected). `bundle exec rake
assets:clobber assets:precompile` clean (exit 0) — this step also runs the production Vite build,
which is where a pre-existing latent bug surfaced and got fixed: `tailwind.css`'s `@import
'./global/pdf.css'` was missing its trailing semicolon, silently tolerated while the imported file
was empty, breaking the build the moment it had real content. Live smoke test: `GET
/country/USA?for_pdf=true` and `/region/AF?for_pdf=true` both 200, `tw-global-pdf` root class present
in the rendered HTML, and the compiled production CSS bundle (`public/vite-dev/assets/layout-*.css`)
contains every ported `.tw-global-pdf …` rule with `!important`/nesting correctly flattened by
Lightning CSS. Protected-area PDF smoke test (`GET /1?for_pdf=true`) hit the same pre-existing,
unrelated seed-data `PageNotFound` gap already documented above and in T3 — confirmed via server log
to predate this change, not caused by it.

This closes every T10 checklist item except enabling Tailwind preflight + the final full-site visual
sweep, which remain the one deliberately-deferred item in the entire plan.

### T10 continued, same day — preflight + full-site sweep closed, plan fully done

Went looking for the "enable preflight" checklist item in `tailwind.css` and found no commented-out
`preflight.css` import to uncomment at all — just the shorthand `@import "tailwindcss";`. Bisecting
history found the cause: commit `ef5c17575` ("feat: migrate coverage chart", 2026-08-06) replaced the
deliberately-split import (`theme.css` + `utilities.css`, omitting `preflight.css`, with a comment
block explaining why) with that shorthand — which bundles preflight back in — as an incidental side
effect of an unrelated component migration, comment block and all gone, never mentioned in the commit
message. Confirmed live (not just in source) via the compiled CSS: preflight's universal reset
(`*,::before,::after{box-sizing:border-box;border:0 solid;margin:0;padding:0}`) present in both the
dev-server output and the production build. Practical upshot: every wave from T2 onward (2026-08-06
onward) was actually verified against a preflight-**on** site the whole time — the docs were wrong
about the starting condition, not the other way around. `shared/cms.css`'s `tw-shared-cms-wysiwyg`
wrapper already explicitly restyles `h1`-`h4`/`p`/`ul`/`ol`/`li`/`a`/`table` rather than relying on
browser defaults, consistent with having been built against a preflight-on reality all along.

Ran the full-site visual sweep this left as the only remaining checklist item. First pass used this
repo's own `puppeteer` dependency (already used for real PDF export) — and it produced screenshots
that looked badly broken: a CTA ribbon (`.vw-ctas-protected-planet-report__ribbon`) rendered black
text with no background instead of white-on-red, `min-h-73` computed as `auto`. Chased it down to the
actual cause rather than reporting it as a regression: that puppeteer bundles **Chrome 88, which
predates CSS Cascade Layers (`@layer`, shipped Chrome 99)** — an unrecognized at-rule's entire block
gets dropped per CSS forward-compatible parsing, so *none* of Tailwind v4's `@layer theme`/`@layer
utilities` content ever applies in that browser, while unlayered CSS (`global/pdf.css`, `@font-face`)
still renders fine. Confirmed by re-screenshotting the same page in a real, ephemeral Chromium (`npx
--yes playwright screenshot` on the host, using an already-cached modern build) — the ribbon rendered
exactly as designed, white-on-red, background photo intact. This is the same failure mode as
[[tailwind-v4-setup]]'s already-documented oklch/nesting gotchas from this same ancient test browser,
just for `@layer` specifically — worth remembering as its own entry since it's broader (drops
*everything* layered, not just color or `:hover` rules) and easy to mistake for a real bug if the
"old test browser" caveat isn't front of mind.

Swept, real-browser-verified, at 1400px and 390px: home, country (`AFG`), region (`AF`), protected
area (`10467` — the WDPA site ID; an initial attempt with the internal DB `id` 404'd, which is correct
behavior, not a bug, the controller resolves by slug/site-id not primary key), marine, effectiveness,
a CMS resource-layout page, a CMS thematic-page layout, a news article, and PDF export
(`?for_pdf=true`). All render correctly — headings, lists, tables, buttons, spacing, hero images, the
world map, CTA banners, footer, all matching design with zero preflight-attributable regressions. PDF
export specifically confirmed the `global/pdf.css` port from earlier today works end-to-end in a real
browser: topbar and map controls hidden, background transparent, single narrow container, exactly the
old `pdf.scss`'s intent. Two unrelated pre-existing issues surfaced and were **not** fixed (out of
scope, already partly documented): `/search` and any unmatched path 500 instead of 404 (the app's
catch-all `get '/:id'` route hits `ProtectedAreasController#show`, which raises `PageNotFound` that
isn't rescued into a real 404 response in this dev environment — same gap T3/T9/T10 already flagged);
a couple of inline CMS images 500 via `ActiveStorage::DiskController` with `Errno::ENOENT` (missing
local blob files in this dev seed). Also noticed but not investigated: the map panel doesn't render
inline on country/region/protected-area pages (it does on home/marine) — a Vue/MapLibre concern,
flagged for a future session rather than chased here. Comfy admin confirmed unaffected — still
Sprockets/`sassc-rails`-served, the preflight boundary holds.

**Every item in the entire SCSS→Tailwind plan (T0 through T10) is now done.**
