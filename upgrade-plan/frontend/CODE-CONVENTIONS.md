# Code conventions (Vue 3 / TypeScript)

**** This file is for AI to read.****

SCOPE: every component written or migrated from Wave 1 onward in the frontend upgrade (`app/frontend/`).
CROSS-REFS: [README.md](./README.md) = status/plan. [CHANGELOG.md](./CHANGELOG.md) = wave-by-wave history these rules were established/retrofitted against. [Component migration order](./README.md#component-migration-order-vue-2--vue-3) = the parent principle this file specifies: components are REWRITTEN to Composition API + TS + Tailwind + composables/utils, not ported as-is.

FORMAT PER RULE: RULE (imperative, always true) / WHY (only when non-obvious) / EXAMPLE / EXCEPTION / LINT (enforced-by-tool vs manual-review-only). Numbering is stable — other docs cite rules as "point N" / "§N".

1. TS ONLY.
   RULE: every new/migrated SFC is `<script setup lang="ts">`. No plain JS.

2. TYPE OWNERSHIP.
   RULE: no inline types in components/composables. All types live under `app/frontend/types/` OR colocated with their owning module, per split below.
   2a. Backend-shaped (Rails `frontend_mount` props payload, serializer JSON, controller-built hash) → `app/frontend/types/backend.ts`, even for a single consumer. Required: a comment above each type naming the producing `frontend_mount` call / controller / serializer.
       EXAMPLE: `MapProps`/`MapBaseProps` ← `frontend_mount "Map"`; `MapFilterProps` ← one item of `@main_map[:overlays]` (MapOverlaysSerializer); `PointQueryService` ← one entry of `MapHelper::ALL_SERVICES_FOR_POINT_QUERY`.
   2b. Frontend-only shared types → colocated with the composable/store/lib file that owns the behavior; import with `import type { X } from '@/composables/useX'`. Never copy-paste. Promote to `app/frontend/types/` only once a type has no single clear owner (≥2 unrelated features need it independently).
       EXAMPLE: `MapControlsOptions` (useMapInstance.ts), `MapLayer` (useMapLayers.ts), `BoundsUrl`/`ZoomToOptions` (useMapBoundingBox.ts), `MapOverlay` (useMapStore.ts), `MapBaselayer` (lib/mapDefaultOptions.ts) — Map-internal, stay put despite cross-component imports.
   2c. Type used by exactly one component → may stay defined in that component's own file (see rule 12).

3. COMPONENT NAMING = FLATTENED FOLDER PATH.
   RULE: folder path → PascalCase tag, Nuxt-style. `components/Chart/Circle.vue` → `<ChartCircle />`. Flatten outer→inner (`Chart/Circle.vue` → `ChartCircle`, NOT `CircleChart`).
   3a. Once a component gains sub-components: convert to `<Name>/Index.vue` + sub-components in the same folder (each already using its full tag name). `Index.vue` maps to the bare folder name: `Tabs/Index.vue` → `<Tabs />`, `Tabs/TabsTitle.vue` → `<TabsTitle />`. INVALID STATE: flat `Tabs.vue` sitting next to a `Tabs/` folder.
   3b. Applies even with no shared/base component — a family of leaf siblings sharing only a name prefix still gets a folder, with no `Index.vue` required: `ListingPageCard/{News,Resources}/Index.vue` → `<ListingPageCardNews />`/`<ListingPageCardResources />` (mounted list wrapper), `ListingPageCard/{News,Resources}/Card.vue` → per-item card (internal use only). INVALID: flat `ListingPageCardNews.vue`.
   REF: [CHANGELOG — Wave 1](./CHANGELOG.md#wave-1--simple-leaves-done) (history of this pair's evolution).

4. CSS = BEM, NAMESPACE `ct-`.
   RULE: component-scoped classes in new SFCs = `ct-block__element--modifier` (e.g. `ct-banner__nav`, `ct-banner-content--is-active`).
   LINT: enforced — `@namics/stylelint-bem`, `namespaces: ["app", "ct-"]` in `stylelint.config.mjs`.
   NOTE: legacy SCSS keeps its pre-existing unprefixed BEM (`chart-circle__label--active`) — untouched, not a violation.
   EXCEPTION: a migrated component may keep unprefixed legacy classes ONLY when reusing existing shared Webpacker SCSS mixins as-is and rewriting them is out of scope for that pass. Precedent (do not extend without cause): `ListingPageCard`. Wave 8 `Stats*`/`ChartRowPa`/`ChartRowStacked` closed T6, Wave 9 `Dropdown` and Wave 10 `Pame/*` closed T8 (2026-08-13) — none are active exceptions any more. Default for any component migrated from here on: fresh `ct-`-prefixed styles (`ct-card__date`, not `card__date`) even if markup was copied from a legacy `.vue` file.
   4a. Sub-component root gets its OWN top-level BEM block, never nested under the parent's: `Banner/Content.vue` root = `ct-banner-content`, NOT `ct-banner__content`.
   4b. Test-only hook classes may skip the `ct-` namespace: add a second, plain class purely for stable test/JS selection when two elements are visually identical — `class="ct-banner__nav banner__nav--prev"` (`ct-banner__nav` carries all `@apply` styling; `banner__nav--prev` exists only so a spec can distinguish prev/next). INVALID: putting Tailwind/`@apply` rules on the unnamespaced class.

4b. CSS = `vw-` PREFIX FOR VIEW-OWNED CHROME.
   RULE: ERB view chrome with no single owning Vue component (page shells, nav/footer wrappers, hero blocks, CTAs) → `vw-block__element--modifier` classes, backed by `app/frontend/styles/views/<name>.css` (e.g. `vw-topbar__container` in `styles/views/topbar.css`).
   WHY: distinguishes view-level chrome from component-scoped `ct-` (rule 4) and cross-cutting `tw-shared-` (rule 5) — was in use before this was written down; codified during [16 SCSS→Tailwind](./16-scss-to-tailwind-migration.md) Wave T0.
   REF: `styles/views/topbar.css`, `styles/views/topbar-secondary.css`.

4c. `vw-` BLOCK NAME MUST MATCH ITS OWNING `.erb` FILE'S FULL PATH, AND ITS CSS FILE MUST MIRROR THAT SAME PATH.
   RULE: the block segment of a `vw-` class is derived from the file's full path under `app/views`, never from just the leaf directory and never from the section's content/topic:
   - Page entry template (`index.html.erb`, `show.html.erb`) → block = kebab-case(full page directory path, segments joined by `-`). `data/gdpame/index.html.erb` → `vw-data-gdpame` (in `styles/views/data/gdpame.css`), `thematic/marine/index.html.erb` → `vw-thematic-marine` (in `styles/views/thematic/marine.css`) — NOT `vw-gdpame`/`vw-marine`, which drop the parent category and collide if two categories ever have same-named leaf directories.
   - Partial rendered from exactly one page (check every `render partial:`/`render "..."` call site — one owning page only) → block = `vw-<page-path>-<partial-slug>` (full page directory path + kebab-cased partial filename, leading `_` dropped, `_` → `-`). `data/gdpame/_tab_content.html.erb` (only rendered from `data/gdpame/index.html.erb`) → `vw-data-gdpame-tab-content`, NOT `vw-gdpame-tab-content` (drops `data-`) or `vw-gdpame__pame-table` (element name borrowed from the mounted widget instead of the file).
   - Partial rendered from ≥2 different pages (genuinely shared chrome, e.g. `partials/cards/*`, `partials/charts/*`, `layouts/cms/*`, `partials/thematic_and_data_area/*`) → block = `vw-<family-dir>-<partial-slug>` (`partials/cards/_circles.html.erb` → `vw-cards-circles`), UNLESS several sibling files in that family are interchangeable renderings of the same structural component (`_hero-*.html.erb`, `_chart-row-pa.html.erb`/`_chart-coverage-growth.html.erb`, `_social-follow.html.erb`/`_social-share.html.erb`, `ctas/_*.html.erb`) — those intentionally share ONE block (`vw-hero`, `vw-partials-charts-chart-row-pa`, `vw-social`, `vw-partials-ctas-api`) distinguished by `--modifier`, not by file. This bullet's family dir is already unambiguous as-is, so it does NOT get the parent-category prefix from bullets 1-2 (`partials/thematic_and_data_area/*` stays `vw-thematic-and-data-area-*`, not `vw-partials-thematic-and-data-area-*`).
   - The backing `styles/views/*.css` file (rule 4b) path mirrors its OWN `.erb` file 1:1, one CSS file per `.erb` file, never merged into another file's: `data/gdpame/index.html.erb` → `styles/views/data/gdpame/index.css`; `data/gdpame/_tab_content.html.erb` → `styles/views/data/gdpame/tab-content.css` (leading `_` dropped, `_` → `-`, same as the class-name transform); `thematic/effectiveness/_green_list_tab.html.erb` → `styles/views/thematic/effectiveness/green-list-tab.css`, sibling to that page's own `styles/views/thematic/effectiveness/index.css` — NOT folded into one shared file per page. A page with no owned partials stays a flat file (no folder needed): `thematic/marine/index.html.erb` → `styles/views/thematic/marine.css`. Precedent: `layouts/partials/footer/_index.html.erb` / `_social_follow.html.erb` → `styles/views/partials/footer/index.css` / `social-follow.css`.
   WHY: a block name that describes content instead of the file (`vw-green-list__banner` for `effectiveness/_green_list_tab.html.erb`) collides across pages and can't be traced back to its owning file or `styles/views/*.css` definition without grepping. Dropping the parent category directory (`vw-gdpame` instead of `vw-data-gdpame`) has the same problem one level up. Merging a partial's rules into its page's file has the same problem again — corrected 2026-08-05 after `thematic/marine`/`thematic/effectiveness` shipped with leaf-only class names, and after `thematic/effectiveness/_green_list_tab.html.erb`'s rules were merged into `thematic/effectiveness.css` instead of getting their own file.
   LINT: NOT enforced — manual review point.

5. SHARED TAILWIND CLASSES.
   RULE: reusable `@apply`-built utility/component classes needed by >1 component → `app/frontend/styles/shared/<name>.css`, one file per concern (`base`, `icons`, `typography`, `shadows`, `forms`, `images`, `scrollbar` — see [16](./16-scss-to-tailwind-migration.md) Wave T1, done), declared via `@utility tw-shared-<name>` (e.g. `tw-shared-base-container`). Never duplicated per-component or inlined ad hoc. Import order in `tailwind.css` matters — a file whose utilities `@apply` another shared utility (e.g. `forms.css`/`images.css` applying `tw-shared-icon-*`) must be imported after the file that declares it.
   EXCEPTION: `shared/icons.css`'s `tw-shared-icon-*` utilities are for **ERB view chrome only** (rule 4b `vw-` classes). See rule 5b — a Vue component never applies one of these.

5b. ICONS IN A VUE COMPONENT = AN `Icon/*.vue` COMPONENT, NEVER A CSS UTILITY.
    RULE: any icon rendered by a Vue component (new or migrated) is an inline-SVG component under `app/frontend/components/Icon/<Name>.vue` (`<svg fill="currentColor">...</svg>`), imported and used as a normal tag: `<IconSearch class="ct-search__icon" />`. Size and color are set by the CONSUMING component's own scoped `<style>` (`@apply size-3.75 text-theme-primary` on the class passed to the icon tag) — never hardcoded inside the `Icon/*.vue` file itself, so one icon file serves every color/size a caller needs.
    WHY: the legacy `_icons.scss` mixin needed a separate SVG file per color (`circle-chevron-green-left.svg` / `circle-chevron-grey-left.svg` / `circle-chevron-white.svg` — one shape, three files) because a CSS `background-image` can't be recolored; an inline `<svg fill="currentColor">` can, from any ancestor's `text-*` class, with zero duplication. Real SVG markup also gets standard accessibility semantics for free. This isn't a new decision — `Icon/{Search,Close,Arrow,Pin,ExclamationCircle}.vue` already exist and are already used this way by `Search/SiteInput.vue`, `Carousel/Themes/Ribbon.vue`, `Stats/TooltipInfo.vue`; this rule just writes the precedent down (same situation as rule 4b before it existed).
    MULTI-COLOR ICONS: an icon with independently-colored parts (e.g. a map pin's outline/fill/tick) puts one BEM class per `<path>`/`<g>` inside the `Icon/*.vue` file's own `<style scoped>` (`@apply fill-white` / `@apply fill-theme-bright-green` per part) — see `Icon/Pin.vue`. This is also the answer for icons the legacy SCSS mixin couldn't express as a flat background-image (e.g. `icon-pin($circle, $outline)`, deferred as "not portable" in [16](./16-scss-to-tailwind-migration.md) Wave T1) — it already IS portable, this way.
    EXCEPTION: ERB view chrome (rule 4b) has no Vue component system to hang an `Icon/*.vue` off — those icons stay `tw-shared-icon-*` background-image utilities from `shared/icons.css` (rule 5's exception).
    LINT: NOT enforced — manual review point.

6. IMPORTS = `@/` ALIAS ONLY.
   RULE: never relative paths (`../../../`). `import ChartCircle from "@/components/Chart/Circle.vue"`, `import { ProtectedArea } from "@/types/backend"`.

7. `@reference "#importtailwindcss"` IN SFC `<style>`.
   RULE: any `<style>` block using `@apply`/`theme()` opens with:
   ```css
   @reference "#importtailwindcss";
   ```
   not a relative path to the real Tailwind entry.
   WHY: `app/frontend/styles/tailwind.css` is customized (preflight disabled — [08 Styles](./08-styles-and-assets.md#decision-tailwind-v4--added-additive-july-2026)); `vite.config.mts` + `vitest.config.mts` alias the bare `tailwindcss` specifier (exact-match regex only — `tailwindcss/theme.css` etc. untouched) to that file.

8. NO TAILWIND UTILITIES IN `<template>`.
   RULE: `<template>` carries only semantic BEM classes + `:class="{...}"` state toggles. Every Tailwind utility backing a BEM class lives in the SFC's own `<style scoped>`, one rule per class, via `@apply`.
   EXAMPLE:
   ```css
   @reference "#importtailwindcss";

   .ct-banner-content__title {
     @apply mt-0 mb-[0.5em] text-[1.125rem] font-bold leading-[1.3] text-theme-grey-black md:text-[1.25rem];
   }
   ```
   WHY: template stays readable (class = *what*, not utility soup), BEM selectors stay stable for tests querying them directly, styling stays colocated like normal scoped CSS.
   EXCEPTION: only real Vue state flags belong in template (`is-active`, `active`, `:class="{...}"` bindings) — never a raw utility (`flex`, `text-theme-primary`).

9. ONE ATTRIBUTE PER LINE (≥2 attrs).
   RULE: any tag with ≥2 attributes/bindings (a single `v-if`/`v-for` + a class already counts) — one per line, closing `>` on its own line.
   EXAMPLE:
   ```html
   <button
     v-if="hasMultipleBanners"
     class="ct-banner__nav banner__nav--prev"
     @click="previousBanner"
   >
   ```
   EXCEPTION: exactly 1 attribute stays inline (`class="ct-banner__slides"`).

10. `defineProps` → `const props =`, NEVER DESTRUCTURED.
    RULE: `const props = defineProps<BannerProps>()`; reference `props.banners`/`props.signature` throughout `<script setup>`.
    WHY: destructuring loses reactivity — project does not enable Vue's opt-in reactive-props-destructure compiler transform.

11. BOOLEAN COMPUTED NAMING.
    RULE: `has`/`is` + noun. `hasMultipleBanners` — NOT `multipleBanners`, NOT `showNav`.

12. ALIAS IMPORTED PROP TYPES BEFORE `defineProps<T>()`. — HARD RULE
    RULE: always
    ```ts
    import type { ListingPageCardResourcesListProps } from '@/types/backend'

    type ListingPageCardResourcesList = ListingPageCardResourcesListProps
    defineProps<ListingPageCardResourcesList>()
    ```
    NEVER `defineProps<ListingPageCardResourcesListProps>()` directly.
    WHY: the direct form can compile fine initially, but the Vue SFC compiler surfaces errors on it later as the type gets re-exported/re-shaped across changes — alias up front, don't fix under pressure later.

13. `v-text`/`v-html` OVER MUSTACHE INTERPOLATION.
    RULE: rendering one dynamic value into an element → `v-text` (or `v-html` when the string contains markup, e.g. CMS copy), not `{{ }}`. `<span v-text="textDownload.title" />` — NOT `<span>{{ textDownload.title }}</span>`.
    REF: `Download/Modal.vue`.
    EXCEPTION: a string mixing static text with >1 interpolated part (`{{ i + 1 }}. {{ category.iucn_category_name }}`) — `v-text` can't express that; use mustaches, or a single template-literal bound via `v-text` (`` v-text="`${i + 1}. ${category.iucn_category_name}`" ``).

14. STATIC CLASS NEVER INSIDE `:class="[...]"` ARRAY.
    RULE: static class → plain `class="..."`. Only genuinely dynamic/conditional classes go in `:class`. Both needed on one element → split: `class="ct-card"` `:class="{ 'ct-card--link': url }"` — NOT `:class="['ct-card', { 'ct-card--link': url }]"`.

15. LIST/ITEM SPLIT NAMING. (extends rule 3)
    RULE: collection folder's `Index.vue` = the list (owns shared state: selection, reset keys, GA aggregation); per-item sibling = plain `Item.vue` (NOT `<Folder>Item.vue`).
    EXAMPLE: `Listing/Checkboxes/{Index,Item}.vue`. Compare `ListingPageCard/{News,Resources}/{Index,Card}.vue` — same Index-owns-list / per-item-file split, item file named `Card.vue` there because that's what one result renders as.
    15a. `Item.vue` takes the single data item + its own selection state as props, emits a plain `change` event — no knowledge of siblings/overall selection array (that stays in `Index.vue`).
    15b. Root element tag must match its container (`<ul>` parent → `<li>` item root — NOT `<div>`/`<p>`).

16. PROPS = camelCase EVERYWHERE.
    RULE: `defineProps` keys AND every parent template binding — camelCase, regardless of source JSON field naming. `:groupId="id"`, `:preSelected="..."`, `:gaId="..."`, `:filterCloseText="..."` — NOT `:group-id`/`:pre-selected`/`:ga-id`/`:filter-close-text`. Project-wide, not per-feature.
    EXCEPTION: native HTML/ARIA/`data-*` attributes on plain lowercase elements stay kebab-case (`:aria-expanded`, `:aria-describedby`, `:data-tab-panel`) — real DOM attribute names, not Vue props; camelCasing would render a nonstandard attribute instead of the real one.

17. EVENTS = camelCase EVERYWHERE.
    RULE: `defineEmits`, every `emit(...)` call, every parent `@listener` — camelCase. `defineEmits<{ requestMore: [page: number] }>()` / `emit('requestMore', ...)` / `@requestMore="..."` — NOT `'request-more'`/`@request-more`.
    17a. Colon-namespaced events (`update:x`, `toggle:x`): camelCase only the part after the colon — `update:filterGroup`, `toggle:filterPane` — NOT `update:filter-group`/`toggle:filter-pane`.

18. SAME-NAME PROP SHORTHAND (Vue 3.4+).
    RULE: `:title` — NOT `:title="title"` — when the bound identifier exactly equals the prop name. Any mismatch (different expression, renamed value, literal) needs the full `:prop="expression"` form.
    LINT: NOT enforced (`yarn lint` passes either way) — manual review point.
    REF: `Map/Index.vue`.

19. NO INLINE LOGIC IN `v-on`/TEMPLATE EXPRESSIONS.
    RULE: template event bindings reference ONLY a bare handler name defined in `<script setup>`. INVALID: `@click="emit('toggle')"`, `@click="$emit('toggle:filterPane')"`, `@click="mapStore.updateSelectedBaselayer(layer)"`, `@toggle="show = !show"`, any inline arrow function.
    PATTERN:
    ```ts
    const onChange = (event: Event) => emit('change', (event.target as HTMLInputElement).checked)
    ```
    ```html
    <input @change="onChange">
    ```
    19a. A handler that only forwards `$event`/args still needs the wrapper: `@requestMore="onRequestMore"` with `const onRequestMore = (page: number) => emit('requestMore', page)` — NOT `@requestMore="emit('requestMore', $event)"`.
    NOT A VIOLATION: calling an existing setup function with a plain argument (`@click="select(option)"`, `@click="toggleTooltip(true)"`).
    LINT: NOT enforced — manual review point.

20. REFERENCE PROPS BARE IN TEMPLATE — NEVER `props.xxx`.
    RULE: `<span v-text="title" />` — NOT `<span v-text="props.title" />`; `v-if="url"` — NOT `v-if="props.url"`.
    WHY: `<script setup>` exposes every declared prop directly to the template's render context; the `props.` prefix (rule 10) is needed only inside `<script setup>` itself, where destructuring would lose reactivity.
    20a. Combine with rule 18's shorthand: `:title`, not `:title="title"` or `:title="props.title"`.
    20b. If removing `props.` leaves `defineProps<T>()`'s return value completely unused elsewhere in `<script setup>`, also drop the `const props = ` assignment.
    LINT: NOT enforced — manual review point.

21. BREAKPOINTS = NATIVE TAILWIND ONLY, NEVER A CUSTOM `--breakpoint-*` TOKEN.
    RULE: any responsive variant, anywhere (`vw-`/`tw-shared-`/`ct-` classes alike) — use Tailwind's
    own `sm:`/`md:`/`lg:`/`xl:`/`2xl:` (640/768/1024/1280/1536px). Never add a `@theme { --breakpoint-
    <name>: ... }` token to `tailwind.css`, even to pixel-match a legacy SCSS breakpoint exactly.
    WHY: Wave T1 originally added `--breakpoint-small/medium/large/xlarge` to mirror the legacy
    `$small/$medium/$large/$xlarge` (767/1024/1200/1440px, exclusive via `breakpoint()`'s `+1px` →
    768/1025/1201/1441px) pixel-for-pixel. User rejected this outright (2026-08-03) — the custom
    tokens duplicated `md:`/`lg:` almost exactly for no real benefit, and worse, caused a real bug:
    legacy `$small` (768px) is numerically IDENTICAL to Tailwind's native `md:` (768px), so any call
    site that mixed the custom `small:` token with a native `md:` utility (several did, meaning
    `md:` as "the tier after small") silently collapsed both rules onto the same breakpoint — the
    smaller-tier value never rendered. See CHANGELOG.md's "Wave T3 correction — custom breakpoint
    tokens removed" for the full incident.
    MAPPING (when porting a legacy `breakpoint($x)` call site): `$small`(768px) → `md:` (exact
    match) · `$medium`(1025px) → `lg:` (1024px, ~1px off, immaterial) · `$large`/`$xlarge`
    (1201px/1441px) → `2xl:` (1536px) — collapse both onto one top tier rather than adding a
    distinct `xl:` step; a few pixels of drift from the legacy value is an accepted tradeoff here
    (precedent: T2/T3's `tw-shared-base-container` correction, CHANGELOG.md Wave T2).
    EXCEPTION: none. If a future legacy scale genuinely needs a 4th or 5th distinct tier, collapse
    the least-used ones onto an existing native tier — don't invent a new token to fit them all.
    LINT: NOT enforced — manual review point. Grep `--breakpoint-` in `app/frontend/styles/` to
    confirm none have crept back in.

---

## Setup status

VERIFIED BUILT: `app/frontend/types/backend`; `@/` alias (`vite.config.mts` + `vitest.config.mts` `resolve.alias`, `tsconfig.json` `paths`); `typescript`/`vue-tsc` devDependencies + `yarn typecheck` script; `tailwindcss` bare-specifier alias (rule 7).
REFERENCE IMPLEMENTATIONS: `Banner/Index.vue` + `Banner/Content.vue`, `Tabs.vue` (incl. rule 8 — Tailwind moved out of templates into `<style scoped>` via `@apply`). `app/frontend/styles/shared/base.css` provides `tw-shared-base-container` (rule 5) to both. `Icon/{Search,Close,Arrow,ExclamationCircle}.vue` (single-color, `fill="currentColor"`) + `Icon/Pin.vue` (multi-color, per-part `@apply fill-*`) are the rule 5b reference implementations, consumed by `Search/SiteInput.vue`, `Carousel/Themes/Ribbon.vue`, `Stats/TooltipInfo.vue`.
