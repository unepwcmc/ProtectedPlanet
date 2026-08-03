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
   EXCEPTION: a migrated component may keep unprefixed legacy classes ONLY when reusing existing shared Webpacker SCSS mixins as-is and rewriting them is out of scope for that pass. Precedent (do not extend without cause): `ListingPageCard`, Wave 8 `Stats*`/`ChartRowPa`/`ChartRowStacked`, Wave 9 `Dropdown`, Wave 10 `Pame/*` (see CHANGELOG.md). Default for any component migrated from here on: fresh `ct-`-prefixed styles (`ct-card__date`, not `card__date`) even if markup was copied from a legacy `.vue` file.
   4a. Sub-component root gets its OWN top-level BEM block, never nested under the parent's: `Banner/Content.vue` root = `ct-banner-content`, NOT `ct-banner__content`.
   4b. Test-only hook classes may skip the `ct-` namespace: add a second, plain class purely for stable test/JS selection when two elements are visually identical — `class="ct-banner__nav banner__nav--prev"` (`ct-banner__nav` carries all `@apply` styling; `banner__nav--prev` exists only so a spec can distinguish prev/next). INVALID: putting Tailwind/`@apply` rules on the unnamespaced class.

4b. CSS = `vw-` PREFIX FOR VIEW-OWNED CHROME.
   RULE: ERB view chrome with no single owning Vue component (page shells, nav/footer wrappers, hero blocks, CTAs) → `vw-block__element--modifier` classes, backed by `app/frontend/styles/views/<name>.css` (e.g. `vw-topbar__container` in `styles/views/topbar.css`).
   WHY: distinguishes view-level chrome from component-scoped `ct-` (rule 4) and cross-cutting `tw-shared-` (rule 5) — was in use before this was written down; codified during [16 SCSS→Tailwind](./16-scss-to-tailwind-migration.md) Wave T0.
   REF: `styles/views/topbar.css`, `styles/views/topbar-secondary.css`.

5. SHARED TAILWIND CLASSES.
   RULE: reusable `@apply`-built utility/component classes needed by >1 component → `app/frontend/styles/shared.css` (split into `styles/shared/<name>.css` per concern once it grows — see [16](./16-scss-to-tailwind-migration.md) Wave T1), declared via `@utility tw-shared-<name>` (e.g. `tw-shared-base-container`). Never duplicated per-component or inlined ad hoc.

6. IMPORTS = `@/` ALIAS ONLY.
   RULE: never relative paths (`../../../`). `import ChartCircle from "@/components/Chart/Circle.vue"`, `import { ProtectedArea } from "@/types/backend"`.

7. `@reference "tailwindcss"` IN SFC `<style>`.
   RULE: any `<style>` block using `@apply`/`theme()` opens with:
   ```css
   @reference "tailwindcss";
   ```
   not a relative path to the real Tailwind entry.
   WHY: `app/frontend/styles/tailwind.css` is customized (preflight disabled — [08 Styles](./08-styles-and-assets.md#decision-tailwind-v4--added-additive-july-2026)); `vite.config.mts` + `vitest.config.mts` alias the bare `tailwindcss` specifier (exact-match regex only — `tailwindcss/theme.css` etc. untouched) to that file.

8. NO TAILWIND UTILITIES IN `<template>`.
   RULE: `<template>` carries only semantic BEM classes + `:class="{...}"` state toggles. Every Tailwind utility backing a BEM class lives in the SFC's own `<style scoped>`, one rule per class, via `@apply`.
   EXAMPLE:
   ```css
   @reference "tailwindcss";

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

---

## Setup status

VERIFIED BUILT: `app/frontend/types/backend`; `@/` alias (`vite.config.mts` + `vitest.config.mts` `resolve.alias`, `tsconfig.json` `paths`); `typescript`/`vue-tsc` devDependencies + `yarn typecheck` script; `tailwindcss` bare-specifier alias (rule 7).
REFERENCE IMPLEMENTATIONS: `Banner/Index.vue` + `Banner/Content.vue`, `Tabs.vue` (incl. rule 8 — Tailwind moved out of templates into `<style scoped>` via `@apply`). `app/frontend/styles/shared.css` provides `tw-shared-base-container` (rule 5) to both.
