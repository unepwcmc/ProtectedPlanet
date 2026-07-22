# 04 — Vue 3 and state

| | |
|---|---|
| **Estimate** | 8–12 weeks · ~2–3 months (overlaps phases 3, 5–7) |
| **Depends on** | [03 — End runtime compilation](./03-end-runtime-compilation.md) started |
| **Blocks** | Full cutover |

[← Back to overview](./README.md)

---

## Goal

All interactive islands run on Vue 3 APIs. Vuex is replaced. Vue 2–only dependencies are removed.

---

## Vue 3 migration checklist (per component)

- [ ] `export default` → `<script setup>` or `defineComponent` (team choice).
- [ ] `beforeDestroy` → `beforeUnmount`; `destroyed` → `unmounted`.
- [ ] `$on` / `$off` / `$once` removed — use props/emits or event bus replacement.
- [ ] `$listeners` merged into `$attrs` — audit parent/child bindings.
- [ ] `v-model` on custom components — `modelValue` + `update:modelValue`.
- [ ] Filters removed — use computed properties or methods.
- [ ] `$children` / `$scopedSlots` — refactor if used.

---

## Global patterns to remove

| Current | Location | Replacement |
|---------|----------|-------------|
| `$eventHub = new Vue()` | `vue.js` | `mitt` or Pinia store |
| Global component registration | `vue.js` | Local import per entrypoint / SFC |
| `mixins: [...]` | map, search, nav, table | Composables (`useX`) |
| `v-click-outside` directive | `vue.js` | Vue 3 directive API or `@vueuse/core` `onClickOutside` |

---

## State: Vuex → Pinia

| Vuex module | File | Notes |
|-------------|------|--------|
| `download` | `_store-download.js` | `localStorage` on `beforeunload` — retest |
| `map` | `_store-map.js` | Map layer / UI state |
| `pame` | `_store-pame.js` | PAME table filters |
| `table` | `_store-table.js` | Generic table state |

Tasks:

- [ ] Create Pinia stores with same behaviour first (parity), then refactor.
- [ ] `app.use(pinia)` per entrypoint that needs store (or shared `createApp` setup helper).
- [ ] Remove `vuex` dependency when all modules migrated.

---

## Dependency replacements

| Package (current) | Action |
|-------------------|--------|
| `vue@2.7` | `vue@3` |
| `vue-loader@15` | `@vitejs/plugin-vue` |
| `vue-analytics` | **`vue-gtag`** (GA4) |
| `vue-lazyload` | `@vueuse/core` / native `loading="lazy"` |
| `vue2-touch-events` | `@vueuse/gesture` or remove |
| `vue-flickity` | Modern carousel lib or CSS-only |
| `axios@0.19` | `axios@1.x` + shared `apiClient` module |
| `babel-polyfill` | Drop or `core-js` only if needed for target browsers |
| `url-search-params-polyfill` | Drop for modern browsers |
| `es6-promise` polyfill in store | Drop if unused |

---

## TypeScript (optional)

- [ ] Add `tsconfig.json` extending `@vue/tsconfig`.
- [ ] New entrypoints as `.ts`; migrate SFCs to `<script setup lang="ts">` incrementally.
- [ ] Type `data-props` payloads per feature (shared types in `app/frontend/types/`).

---

## ESLint / tooling

- [ ] ESLint 9 + `eslint-plugin-vue` + `@nuxt/eslint` optional — use [Vue ESLint docs](https://eslint.vuejs.org/) current majors.
- [ ] `vue-tsc` for CI typecheck if TypeScript adopted.

---

## Exit criteria

- No `vue@2` or `vuex@3` in `package.json`.
- No `mixins` left on migrated features (or documented exceptions).
- Pinia handles all former Vuex flows.
- ESLint passes on `app/frontend/` and migrated `app/javascript/components/`.

---

## Reference

- [Vue 3 migration guide](https://v3-migration.vuejs.org/)
- [Pinia](https://pinia.vuejs.org/core-concepts/)
- [14 — Architecture](./14-architecture-and-design.md) — store split, no `$eventHub`
