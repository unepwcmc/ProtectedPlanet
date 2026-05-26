# 09 — Testing and QA

| | |
|---|---|
| **Estimate** | 3–5 weeks · ~0.75–1.25 months (initial suite; ongoing during phases 4–7) |
| **Depends on** | [03](./03-end-runtime-compilation.md) started |
| **Blocks** | Production cutover confidence |

[← Back to overview](./README.md)

---

## Goal

Automated tests for migrated logic and a repeatable QA checklist for maps, charts, and downloads. Today ProtectedPlanet has **no frontend unit tests**.

---

## Unit / component tests (Vitest)

Use [Vitest](https://vitest.dev/guide/) + [@vue/test-utils](https://test-utils.vuejs.org/) + `happy-dom` (standard Vue 3 stack).

### Priority targets

- [ ] `apiClient` / CSRF header helper (ported from `axios-helpers.js`).
- [ ] Pinia `download` store — localStorage persistence.
- [ ] Composables extracted from map mixins (after migration).
- [ ] `SearchAreas` — filter state, tab switching (mock axios).
- [ ] `ListingPage` — filter query string behaviour.

### Setup tasks

- [ ] Add `vitest.config.ts` with `@` alias matching Vite.
- [ ] `tests/unit/` under repo root or `app/frontend/__tests__/` — match [14](./14-architecture-and-design.md) folder layout.
- [ ] CI job: `yarn test` on PRs touching `app/frontend/`.

---

## E2E smoke (Playwright recommended)

Minimum happy paths:

| Journey | Steps |
|---------|--------|
| Home | Load, nav burger opens, home search visible |
| Site search | Query + results |
| Search areas | Filter, tab, scroll/load more |
| Country page | Stats charts render, download button opens modal |
| Map page | Map loads tiles, layer toggle, PA search |
| CMS listing | Resources filter + pagination |
| Download | Start download, poll completes (staging fixture) |

- [ ] Run against staging after each phase merge.
- [ ] Store Playwright config in repo (`playwright.config.ts`).

---

## Visual / manual regression

- [ ] Screenshot baseline for 5–10 key URLs (country, marine, target dashboard).
- [ ] Chart data spot-check vs production (same country ISO).
- [ ] PDF export one country + one PA page (`@for_pdf`).

---

## Analytics verification

- [ ] GA4/GTM events fire for migrated components (replace `vue-analytics` / `ga-id` props audit).

---

## Exit criteria

- Vitest runs in CI with non-zero meaningful tests.
- Playwright smoke passes on staging before Webpacker removal.
- QA checklist signed by product/QA before production deploy.

---

## Reference

- [Vitest Vue guide](https://vitest.dev/guide/#vue)
- [Vue Test Utils](https://test-utils.vuejs.org/guide/)
