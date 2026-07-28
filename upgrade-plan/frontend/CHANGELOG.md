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
