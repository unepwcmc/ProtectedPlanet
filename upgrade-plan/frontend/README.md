Total around 6 months for frontend if no surprises then it can be shorter to 5 months

# Protected Planet — Frontend upgrade (summary)

**For:** planning / stakeholders · **Detail:** phase docs linked below


|                     |                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Target**          | Vite 7 · Vue 3 · island mounts (Rails 7/8 desirable but **not required** for the frontend — see gates)                          |
| **Now**             | Rails 5.2 · **Ruby 2.7.8 ✓ · Node 24.4.1 ✓ · Vite 7 + vite-plugin-rails ✓** · Webpacker⇄Vite dual bundler ✓ · `#v-app` (Vue 2) intact · **dead code removed ✓** (Wave 0) · first island **Banner ✓** · Tabs island proven · Vitest ✓                                                        |
| **Owner**           | Frontend (+ Vite/ERB integration, Comfy admin JS)                                                                               |
| **Not in estimate** | Backend Rails 5→8 · CMS redesign                                                                                                |
| **Scope**           | **[Live inventory](./01-live-inventory.md)** — nav-led; ~12 entrypoints; dead code + **Vue 2–only npm** replacements in phase 4 |
| **Real gates**      | **Ruby 2.7+** (for `vite_rails` 3.x) + **Node 18+** (for Vite 5) — *not* Rails 7. See [Version gates](#version-gates--execution-order) |


---

## Status — G1 gate done (Jul 2026)

**Done this cycle** (branch `feat/upgrade-frontend`): Ruby 2.6.3→**2.7.8**, Node 12→**24.4.1**, **Vite 7 + `vite-plugin-rails`** (`vite_rails` 3.11.1) running **alongside Webpacker/Vue 2** (dual bundler, cold-start safe). Islands foundation built — `frontend_mount` helper + `readMountProps` + `app/frontend/lib/islands.ts` (registry, lazy Vue, `MutationObserver`), registered in `entrypoints/layout.ts`. **First real island migrated: `Banner`** (lifted out of `#v-app`, on every page). **Tabs island proven** (real `v-if` panels; verified live on wdpca with dummy search/map mounts, then reverted) — confirms hidden / late / nested mounts work with no `v-show`. **Vitest** set up (60 tests, all green — also covers Waves 1–3 below). Everything else still runs under Vue 2 / `#v-app`.

**Also added: Tailwind v4** via Vite (preflight disabled, **additive** alongside the legacy SCSS — not a redesign) for styling new/migrated components. Detail + caveats: [08 Styles](./08-styles-and-assets.md#decision-tailwind-v4--added-additive-july-2026).

**Also done: Wave 1 · simple leaves** (`ga-link`, `counter`, `select-with-content`, `listing-page-card-news`,
`listing-page-card-resources`) — migrated to Vue 3 islands alongside `Banner`. `Counter` dropped its
`scrollmagic` dependency for a native `IntersectionObserver`; `frontend_mount` gained a `key:` option so
repeated-instance components (the two card types, rendered in a loop) each get their own DOM id/props block
while resolving to one registry entry — see [FrontendHelper](../../app/helpers/frontend_helper.rb).

**Also done: Wave 2 · mixin-only leaves** (`tooltip`, `tooltip-second`) — migrated to Vue 3 (`app/frontend/components/Tooltip/Index.vue` → `<Tooltip>`, `Tooltip/Second.vue` → `<TooltipSecond>`). Their only Vue 2 coupling, `mixin-popup-close-listeners`, became `app/frontend/composables/usePopupCloseListeners.ts` (click-outside + Escape-to-close, reusable by later waves — `nav`, `search`, `select` mixins share the same legacy mixin). Registered as islands in `layout.ts` but **not yet wired to a live page**: their current callers (PAME table header's `<tooltip>`, `_stats-overview-country.html.erb`'s `<tooltip-second>`) still run under Webpacker/Vue 2 and haven't reached their own wave (8/10) yet — swap the callers over then.

**Wave 3 · global chrome, in progress:** `nav-burger` (+ `NavDropdown`, `NavLink`) and `search-site-topbar` (+ `SearchSiteInput`) migrated to Vue 3 (`app/frontend/components/NavBar/{Index,Dropdown,Link}.vue`, `app/frontend/components/Search/{SiteTopbar,SiteInput}.vue`). The top-level component is named `NavBar` (not `NavBurger`) since it's the whole nav — pane, link list, and burger trigger — not just the burger button; per the Nuxt folder convention it's `NavBar/Index.vue`→`<NavBar>`, `NavBar/Dropdown.vue`→`<NavBarDropdown>`, `NavBar/Link.vue`→`<NavBarLink>`, matching `Tabs/Index.vue`→`<Tabs>`. `mixin-focus-capture` (Tab-trap accessibility) and `mixin-responsive` (breakpoint tracking, previously broadcast via a global `$eventHub` Vue 3 doesn't need here) became `app/frontend/composables/{useFocusCapture,useBreakpoint}.ts`; `mixin-popup-close-listeners` reused from Wave 2. Legacy `_nav.scss`/`_search-main.scss` kept as-is (unprefixed BEM classes, no `ct-`/Tailwind rewrite) rather than a from-scratch reimplementation — deliberate exception given this is global, every-page chrome where a visual regression has outsized blast radius; revisit once it's proven live. **Wired live:** `_topbar.html.erb` now calls `frontend_mount "NavBar"`/`frontend_mount "SearchSiteTopbar"` directly — no Vue 2 tags left in that partial — and the `_topbar` render moved outside `#v-app` in `application.html.erb` (same as Banner). `get_nav_primary` now returns the raw links array instead of a pre-`.to_json`'d string, since `frontend_mount` serializes props itself. Old Vue 2 `Nav{Burger,Dropdown,Link}.vue`/`SearchSiteTopbar.vue` deleted (zero remaining references); `SearchSiteInput.vue` kept since un-migrated `SearchSite.vue` still uses it. Along the way, found+fixed a real bug in `app/frontend/lib/islands.ts`: the mount-unwrap logic carried `id`/`dataset` from the `frontend_mount` wrapper onto the real mounted root but silently dropped `class` — would have broken `.topbar__nav`/`.topbar__search` CSS; fixed with a covering test. `search-site` (the full results page, pulls in `Pagination`/`TabsFake`) remains deferred to a later pass given its size. `@vueuse/core` (already used by `pp-data-management-portal`) was added as a dependency (Jul 2026) and `useBreakpoint`/`usePopupCloseListeners` were rewritten on top of it (`useWindowSize`, `onClickOutside`, `onKeyStroke`) — same public API, less hand-rolled listener bookkeeping. It only resolves inside the Vite/Vue 3 build (`vue` → `vue3` alias); `vitest.config.mts`'s `server.deps.inline` needed `/@vueuse\//` added alongside the existing `@vue/test-utils` entry so its internal `import ... from 'vue'` goes through the same alias instead of resolving the real Vue 2.7 package. `onClickOutside` also briefly guards against double-firing on rapid clicks (touch+click protection) — `Tooltip`/`TooltipSecond`/`NavBar`'s "closes when clicking outside" tests needed a macrotask tick (`await new Promise(resolve => setTimeout(resolve, 0))`) between the trigger click and the outside click to account for it.

**Next:** finish Wave 3 (`search-site`, deferred); rewrite migrated components onto Tailwind; `download-modal`→Pinia; Webpacker removed last.

### Decisions made
- **Vite/Rails glue — `vite-plugin-rails`** (not `vite-plugin-ruby`) is the npm package actually wired up (`vite.config.mts`) alongside the `vite_rails` gem. [02](./02-vite-on-rails-8.md) corrected to match.
- **Maps — MapLibre GL JS** (open source, no Mapbox account/licensing dependency) over Mapbox GL v2+. Requires migrating `mapbox://` style URLs and re-testing RTL/polygons/zoom. Detail: [05](./05-maps.md#decision-maplibre).
- **Analytics — `vue-gtag`** (GA4) replaces `vue-analytics`. Detail: [04](./04-vue3-and-state.md#dependency-replacements).

### Decisions to revisit later
- **Mounting library — homegrown for now; revisit `turbo-mount` after Ruby 3 / Rails 6+.** We use a small in-house mounter (`frontend_mount` + `islands.ts`). [`turbo-mount`](https://github.com/skryukov/turbo-mount) (Evil Martians, Stimulus-based) is the "batteries-included" equivalent, but its **gem requires Ruby ≥ 3.0 and railties ≥ 6.0** — won't install on our **Ruby 2.7.8 / Rails 5.2** — and it pulls in Hotwire/Stimulus. Because views only ever call `frontend_mount`, adopting it later is a ~2-file swap (Vue SFCs never move). Detail: [14 Architecture](./14-architecture-and-design.md#mounting-mechanism-and-the-turbo-mount-decision).

---

## Task plan

*Estimates @ 1 FTE with **AI assistance**, scoped to **[live pages/components](./01-live-inventory.md)**. Format: **weeks (months in brackets)**. Phases 4–7 overlap — do not sum the column.*


| #   | Phase                    | Key deliverables                                                       | Estimate                 | Detail                                                                    |
| --- | ------------------------ | ---------------------------------------------------------------------- | ------------------------ | ------------------------------------------------------------------------- |
| —   | Rails 5.2 prep           | Vue 2 refactors; Comfy Coffee→JS; remove dead globals/SFCs             | 2–5 wk (~0.5–1.25 mo)    | [13](./13-work-while-rails-upgrades.md)                                   |
| 1   | Discovery                | Confirm [live inventory](./01-live-inventory.md); CMS A/B/C            | 1–2 wk (~0.25–0.5 mo)    | [01](./01-discovery-and-inventory.md)                                     |
| 2a  | Vite foundation          | Dual bundler; Docker **vite** service; `frontend_mount`; entrypoints   | 1–2 wk (~0.25–0.5 mo)    | [02a](./02a-vite-spike-rails-5.md) · [15 Docker](./15-docker-vite-dev.md) |
| 2b  | Vite target stack        | Ruby 2.7; `vite_rails` 3.x; Vite 5; Vue plugin; **Node 24 LTS** Docker  | 1–2 wk (~0.25–0.5 mo)    | [02](./02-vite-on-rails-8.md)                                             |
| 3   | Islands                  | **~12 entrypoints**; drop `#v-app`                                     | 5–8 wk (~1.25–2 mo)      | [03](./03-end-runtime-compilation.md)                                     |
| 4   | Vue 3 + state            | **~110** SFCs (not 125); drop ~9 dead/child-only globals               | 6–9 wk (~1.5–2.25 mo)    | [04](./04-vue3-and-state.md)                                              |
| 5   | Maps                     | Mapbox/MapLibre; bundle via Vite                                       | 4–7 wk (~1–1.75 mo)      | [05](./05-maps.md)                                                        |
| 6   | Charts                   | **4 live** chart families; no dial/sunburst/treemap/bar (dead)         | 3–5 wk (~0.75–1.25 mo)   | [06](./06-charts-and-visualisations.md)                                   |
| 7   | Search & CMS UI          | Listings + wdpca/gdpame/marine/effectiveness (not 127 CMS URLs)        | 3–6 wk (~0.75–1.5 mo)    | [07](./07-search-listings-downloads.md)                                   |
| 8   | Styles & Sass            | Dart Sass; drop sassc / Webpacker CSS                                  | 3–5 wk (~0.75–1.25 mo)   | [08](./08-styles-and-assets.md)                                           |
| 9   | Testing                  | Vitest; Playwright on **live page list**                               | 2–4 wk (~0.5–1 mo)       | [09](./09-testing-and-qa.md)                                              |
| 10  | Release                  | Deploy vite build; PDF smoke                                           | 2–3 wk (~0.5–0.75 mo)    | [10](./10-deploy-and-devops.md)                                           |
|     | **Total — conservative** | AI + normal review; overlap included                                   | **24–34 wk (~6–8.5 mo)** |                                                                           |
|     | **Total — optimistic**   | AI-native; few surprises                                               | **19–27 wk (~5–7 mo)**   |                                                                           |


*Add **+15–25%** on conservative total if the wdpca/gdpame/effectiveness tabs are harder than expected. Phase **2b onward** is gated on **Ruby 2.7 + Node 18+**, not on the Rails major — see [Version gates](#version-gates--execution-order).*

**Out of scope (no estimate):** ~100+ static CMS resource/news pages, equity study-site articles, connectivity/ICCA thematic copy-only pages, orphan Vue files listed in [01-live-inventory](./01-live-inventory.md).

---

## Version gates & execution order

### The real dependency gates

The modern frontend stack is **not** gated on Rails 7/8. The actual technical requirements are:

| Want | Requires | Not |
|------|----------|-----|
| `vite_rails` 3.x | **Ruby 2.7+** (`filter_map`) | any specific Rails major |
| Vite 5+ | **Node 18+** | — |
| Vue 3 + `@vitejs/plugin-vue` | Vite 5 | — |

Rails 5.2 officially supports Ruby up to 2.7, so **bumping Ruby 2.6.3 → 2.7 while staying on Rails 5.2** is enough to unlock the modern gem. The Rails major can lag. *(Rails 7 is still worth doing later — Comfy, `dartsass-rails`, security — but it does not block this work. Validate `vite_rails` 3.x on Rails 5.2 with a short spike.)*

### The Node ↔ Webpacker constraint

Today **one `Dockerfile` (`ruby:2.6.3`, Node 12), one `package.json`, one shared `node_modules`** serve `web` + `webpacker` + `vite`. Bumping Node to 18+ breaks Webpacker 4 (webpack 4's `md4`/OpenSSL 3 error, `ERR_OSSL_EVP_UNSUPPORTED`).

**Good news:** this app does **not** use `node-sass` (SCSS compiles Ruby-side via `sassc`/`sass-rails`), so the only fix needed to keep Webpacker 4 alive on modern Node is one flag on the **webpacker service only**:

```
NODE_OPTIONS=--openssl-legacy-provider
```

With that, a single bumped Node (24 LTS) runs **both** Webpacker 4 (Vue 2, with the flag) and Vite 5 (Vue 3) during the migration overlap. Expect minor `yarn install` peer-dep friction, but no native-module wall. Use **Node 24 LTS**, not 26 (26 is not LTS until ~Oct 2026).

### Recommended execution order (constrained path — current Ruby/Rails)

> **Status (Jul 2026):** steps **1–5 ✓ done** · step **6 in progress** (`Banner` island ✓, `Tabs` proven, Vitest ✓, dead-code cleanup ✓) · step **7 pending**.

1. **Delete genuinely-dead code now ✓ done** (safe on Rails 5.2): orphan `.vue` files, dead globals (`ChartDial`, carousel, sunburst/treemap/bar, `select-equity`/`select-dropdown`), `leaflet`, plus the last orphaned SCSS (`_select-equity.scss`). Browser polyfills (`babel-polyfill`/`es6-promise`/`url-search-params-polyfill`) are a separate, not-yet-done audit — [01](./01-live-inventory.md), [13](./13-work-while-rails-upgrades.md).
2. **Add Vite as a Docker dev service alongside Webpacker** (dual bundler, already spiked) — [15](./15-docker-vite-dev.md).
3. **Ruby 2.6.3 → 2.7** on Rails 5.2 (rebuild image on `ruby:2.7` base). Unlocks `vite_rails` 3.x.
4. **Node 12 → 24 LTS** in the Dockerfile; add `--openssl-legacy-provider` to the webpacker service.
5. **`vite_rails` 2→3, Vite 2.9→5** + `@vitejs/plugin-vue`.
6. **Migrate Vue 2→3 island by island**; swap each component's Vue2-only deps (vuex→Pinia, vue-analytics→GA4, …) and drop each package once unused — [04](./04-vue3-and-state.md).
7. **Remove Webpacker last** — service, gem, `@rails/webpacker`, config, and the legacy flag together — [03](./03-end-runtime-compilation.md), [15](./15-docker-vite-dev.md) D3.

**Webpack removal is the finish line, not the first step** — it stays until the last Vue component is on Vite. Keep the dual-Node overlap window short.

---

## Component migration order (Vue 2 → Vue 3)

Order derived from a coupling scan (mixin / Vuex `$store` / `$eventHub` / maps / charts) over the
live components. **Principle:** leaf & zero-coupling first → mixin-only → global chrome (then break
`#v-app`) → **state stores before the components that use them** → maps & charts (gated on their
library decisions) → Webpacker removed last. Every component is rewritten to the conventions:
**TypeScript `<script setup>` (Composition API) + Tailwind + mixins replaced by composables/utils**
(not ported as-is) — see [Code conventions](#code-conventions-vue-3--typescript) below for the full list.

| Wave | Components (ERB tag) | Prereq / why |
|------|----------------------|--------------|
| **0 · Delete dead code first ✓ done** | `chart-dial`, carousel/`carousel-slide`, `sticky-nav`, `chart-bar`/`chart-bar-simple`, `chart-sunburst`/`chart-treemap-*`/`chart-rectangles`, `select-equity`/`select-dropdown`, ~10 orphan `.vue` | Don't migrate the dead — shrinks phase 4. Safe on Rails 5.2. See [01](./01-live-inventory.md). |
| **1 · Simple leaves** (zero coupling) **✓ done** | `banner-banner`, `ga-link`, `counter`, `select-with-content`, `listing-page-card-news`, `listing-page-card-resources` | Establish the Composition-API + Tailwind + composable pattern on the lowest-risk surface. |
| **2 · Mixin-only leaves** | `tooltip`, `tooltip-second` | First mixin→composable extractions; no store/bus. |
| **3 · Global chrome → break `#v-app`** | `nav-burger`, `search-site-topbar`, `search-site` | mixin→composable, `$eventHub`→`mitt`/emits. Once chrome is islands, **dismantle `#v-app`**. |
| **4 · Pinia + downloads** | `useDownloadStore` (port Vuex `download`), `download`, `download-item`, `download-csv`, `download-modal` | Set up **Pinia**; downloads span pages (loaded from `layout`). |
| **5 · Listings + tabs** | `listing-page`, `tabs`/`tab-target`/`tab-trigger` (**`Tabs.vue` proven**) | `$eventHub 'map:resize'`→composable; wire news/resources + a real tab page. |
| **6 · Maps** (phase 5) | `v-map` (+ `-header`/`-filters`/`-pa-search`/`-disclaimer`/`-baselayer-controls`/`-toggler`) | **MapLibre chosen** (see decisions above) + `useMapStore` (Pinia) first. |
| **7 · Search areas** | `search-areas`, `search-areas-home`, `search-areas-input-autocomplete` | Depends on maps + downloads; then complete `wdpca`/data pages. |
| **8 · Charts + stats** (phase 6) | `chart-row-pa`, `chart-row-stacked`, `am-chart-multiline`, `am-chart-pie`, `region-country-pages` (+ `Stats*`) | Port custom SVG charts first; amCharts 4→5; country/region/marine/effectiveness pages. |
| **9 · PA show** | `attributes-*` (5) | mixin→composable; protected-area page. |
| **10 · PAME** | `usePameStore` (port Vuex `pame`), `filtered-table`, `pame-modal` (+ table subcomponents) | gdpame page. |
| **11 · Carousel** | replace `flickity` (`vue-flickity`) → Swiper/CSS | affects home + marine hero carousels. |
| **12 · Finish** | remove `#v-app`, `vue.js`, Vuex, `vue-analytics`/`vue2-touch-events`/`vue-lazyload`, Webpacker + packs | Webpacker removed last, once nothing is left on Vue 2. |

*Retrofit note: `Banner.vue` and `Tabs.vue` were migrated earlier in **Options API** with global SCSS — bring them in line with the conventions (Composition API + Tailwind) as the reference examples when Wave 1 starts.*

*Wave 0 note: `stats-growth`/`AmChartLine` (growth chart, ticket #265) has been removed — component, registration, and SCSS all deleted from `RegionCountryPages.vue`/`vue.js`.*

---

## Code conventions (Vue 3 / TypeScript)

Binding rules for every component written or migrated from Wave 1 onward. These extend the
"Composition API + Tailwind + composables" note above with the specifics:

1. **TypeScript everywhere.** New/migrated SFCs use `<script setup lang="ts">` — no plain JS.
2. **Types live in `app/frontend/types/`.** Shared/domain types go directly under
   `app/frontend/types/`. Anything shaped by the backend (Rails-rendered props, API JSON) goes under
   `app/frontend/types/backend.ts` — one file per resource/serializer shape, so a backend contract
   change is easy to find and update in one place.
3. **Component naming = Nuxt-style flattened path.** A component's folder path becomes its tag name:
   `app/frontend/components/Chart/Circle.vue` is used as `<ChartCircle />`. Nested folders flatten to
   PascalCase in the order they nest (`Chart/Circle.vue` → `ChartCircle`, not `CircleChart`).
   **Once a component has its own sub-components**, move it into its own folder as `Index.vue` and
   keep its sub-components alongside it there (each already named with its full tag name), instead
   of leaving a flat `Tabs.vue` sitting next to a `Tabs/` folder. `Index.vue` maps to the bare folder
   name: `components/Tabs/Index.vue` → `<Tabs />`, `components/Tabs/TabsTitle.vue` → `<TabsTitle />`.
   This applies from the first sibling on, even with no shared/base component: a family of leaf
   components that only share a name prefix (no bare `<ListingPageCard />` itself) still goes in a
   folder with no `Index.vue` — e.g. `components/ListingPageCard/{News,Resources}/Index.vue` →
   `<ListingPageCardNews />`/`<ListingPageCardResources />` (the mounted list wrapper) and
   `components/ListingPageCard/{News,Resources}/Card.vue` → the individual card, used internally —
   never a flat `ListingPageCardNews.vue` file. (This pair started as a single flat `.vue` file per
   type in Wave 1 — one `frontend_mount` per card in an ERB loop — and was split into `Index`/`Card`
   in a Wave-1 follow-up once a second use case (a `cards` array with one list-level mount) came up;
   see the roadmap memory note.)
4. **CSS is BEM, namespaced `ct-`.** Class names follow `ct-block__element--modifier` (e.g.
   `ct-banner__nav`, `ct-banner-content--is-active`) for any component-scoped classes in new SFCs —
   the `ct-` prefix is enforced by Stylelint (`@namics/stylelint-bem`, `namespaces: ["app", "ct-"]`
   in `stylelint.config.mjs`). Legacy SCSS keeps its existing unprefixed BEM (`chart-circle__label--active`).
   **Reminder for future waves:** `ListingPageCard/{News,Resources}/Card.vue` (Wave 1) kept their
   unprefixed legacy classes (`card__date`, `card__h3`, ...) as a one-off exception because they reuse
   existing shared Webpacker SCSS mixins as-is. That's the exception, not the pattern — don't copy it
   forward. A component migrated from here on writes fresh component-scoped styles and must use the
   `ct-` prefix (`ct-card__date`, not `card__date`), even when its markup/classes started life copied
   from a legacy `.vue` file.
   A sub-component gets its **own** top-level BEM block rather than nesting under the parent's:
   `Banner/Content.vue`'s root is `ct-banner-content`, not `ct-banner__content`.
   **Test-only hook classes may skip the namespace.** When two elements are visually identical and
   only need a stable selector for tests/JS (not a style), add a second, plain (non-`ct-`) class
   purely for that — e.g. `class="ct-banner__nav banner__nav--prev"`, where `ct-banner__nav` carries
   all the `@apply` styling and `banner__nav--prev` exists only so a spec can tell prev from next.
   Never put Tailwind/`@apply` rules on the unnamespaced class.
5. **Shared Tailwind classes live in `app/frontend/styles/shared/<name>.css`, prefixed `tw-shared-`.**
   Reusable utility/component classes (built with `@apply`, custom properties, etc.) that more than
   one component needs go in a dedicated file there, declared with `@utility tw-shared-<name>` (e.g.
   `tw-shared-base-container` in `styles/shared/base.css`) — don't duplicate them per-component or
   inline them ad hoc in a single SFC.
6. **Imports use the `@/` alias, never relative paths.** e.g.
   `import ChartCircle from "@/components/Chart/Circle.vue"`,
   `import { ProtectedArea } from "@/types/backend"` — not `../../../`.
7. **Tailwind inside an SFC `<style>` block needs `@reference "tailwindcss"`.** This project's
   Tailwind entry (`app/frontend/styles/tailwind.css`) is customised (preflight disabled — see
   [08 Styles](./08-styles-and-assets.md#decision-tailwind-v4--added-additive-july-2026)), so
   both `vite.config.mts` and `vitest.config.mts` alias the bare `tailwindcss` specifier
   (exact-match only, via regex — subpaths like `tailwindcss/theme.css` stay untouched) to that
   file. Any `<style>` block using `@apply`/`theme()` starts with:
   ```css
   @reference "tailwindcss";
   ```
   instead of a relative path back to the real entry file.
8. **Tailwind utility classes never sit in the template.** A component's `<template>` only ever
   carries semantic BEM classes (`ct-banner__title`, `ct-banner-content--is-active`, plus state
   toggles bound via `:class="{ ... }"`). Every Tailwind utility backing those classes lives in the
   SFC's own `<style scoped>` block, one rule per BEM class, using `@apply`:
   ```css
   @reference "tailwindcss";

   .ct-banner-content__title {
     @apply mt-0 mb-[0.5em] text-[1.125rem] font-bold leading-[1.3] text-theme-grey-black md:text-[1.25rem];
   }
   ```
   This keeps templates readable (class names describe *what*, not a long utility soup), keeps BEM
   selectors stable for tests that query them directly, and keeps the styling colocated with the
   component like any other scoped CSS. Only actual state flags that Vue needs to toggle (`is-active`,
   `active`, `:class="{ ... }"` bindings) belong in the template — never a raw utility class like
   `flex` or `text-theme-primary`.
9. **One attribute per line once an element has more than one.** Any tag with two or more
   attributes/bindings (including a single `v-if`/`v-for` plus a class) wraps each onto its own line,
   closing `>` on its own line too:
   ```html
   <button
     v-if="hasMultipleBanners"
     class="ct-banner__nav banner__nav--prev"
     @click="previousBanner"
   >
   ```
   A tag with exactly one attribute (e.g. `class="ct-banner__slides"`) can stay on one line.
10. **`defineProps` is assigned to `props`, never destructured.** Use
    `const props = defineProps<BannerProps>()` and reference `props.banners`/`props.signature`
    throughout the rest of `<script setup>` — destructuring props directly loses reactivity outside
    of Vue's opt-in reactive-props-destructure compiler transform, which this project doesn't enable.
11. **Boolean computed values are named `has`/`is` + noun.** e.g. `hasMultipleBanners`, not
    `multipleBanners` or `showNav`.
12. **Always re-declare an imported props type as a local alias before `defineProps<T>()`.**
    Every migrated component must do this:
    ```ts
    import type { ListingPageCardResourcesListProps } from '@/types/backend'

    type ListingPageCardResourcesList = ListingPageCardResourcesListProps
    defineProps<ListingPageCardResourcesList>()
    ```
    rather than `defineProps<ListingPageCardResourcesListProps>()` directly. **This is now a hard
    rule (Jul 2026), superseding the earlier "consistency convention, not a hard requirement" note**
    — passing an imported type straight into `defineProps<T>()` can compile fine at first but the
    Vue SFC compiler surfaces errors on it later (as the type is re-exported/re-shaped across
    changes), so alias it up front rather than fixing it under pressure later. `Search/SiteTopbar.vue`
    is the one remaining component that skips this — fix it the next time that file is touched.
13. **Use `v-text`/`v-html` instead of `{{ }}` mustache interpolation** for rendering a single
    dynamic value into an element, e.g. `<span v-text="textDownload.title" />` rather than
    `<span>{{ textDownload.title }}</span>` (and `v-html` when the string contains markup, e.g. CMS
    copy). `Download/Modal.vue` is the reference example. Existing `{{ }}` usage (e.g.
    `NavBar/Link.vue`) should be converted the next time that file is touched.
14. **A static class always goes in a plain `class="..."` attribute, never inside a `:class="[...]"`
    array.** Only genuinely dynamic/conditional classes belong in `:class`, and when both are needed
    on the same element, split them: `class="ct-card"` `:class="{ 'ct-card--link': props.url }"` —
    not `:class="['ct-card', { 'ct-card--link': props.url }]"`. Existing components that mix a static
    string into the `:class` array (`NavBar/Dropdown.vue`, `NavBar/Link.vue`, `Tooltip/Index.vue`,
    `Search/SiteInput.vue`, `ListingPageCard/Resources/{Index,Card}.vue`) should be split the next
    time each file is touched.

*Setup status: all of the above is built and verified (Jul 2026) — `app/frontend/types/backend`, the `@/` alias (`vite.config.mts` + `vitest.config.mts` `resolve.alias`,
`tsconfig.json` `paths`), the `typescript`/`vue-tsc` devDependencies + `yarn typecheck` script, and
the `tailwindcss` bare-specifier alias for point 7 all exist and were confirmed working (a scratch
`@reference "tailwindcss"` + `@apply` component built correctly, then removed). `Banner/Index.vue` +
`Banner/Content.vue` and `Tabs.vue` are the first components retrofitted to these conventions,
including point 8 — their templates carry only `ct-`-namespaced BEM classes, with every Tailwind
utility moved into each component's `<style scoped>` block via `@apply`. `app/frontend/styles/shared/base.css`
now exists, providing `tw-shared-base-container` (point 5) to both `Banner/Index.vue` and `Tabs.vue`.*

---

## Detail documents


| Doc                                                          | Contents                                             |
| ------------------------------------------------------------ | ---------------------------------------------------- |
| [00 Scope reference](./00-scope-and-backend-dependencies.md) | You vs backend, B0–B5 milestones (not a gated phase) |
| [01b Live inventory](./01-live-inventory.md)                 | Nav-led pages, entrypoints, dead vs live components  |
| [14 Architecture](./14-architecture-and-design.md)           | Islands, CMS patterns, mounts                        |
| [12 Gems & assets](./12-gemfile-frontend-dependencies.md)    | Gemfile / npm / Sprockets / Comfy admin              |
| [15 Docker Vite dev](./15-docker-vite-dev.md)                | Replace webpacker container with vite (phased)       |


*Updated July 2026*