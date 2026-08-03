# 16 — SCSS → Tailwind migration (styling cutover)

| | |
|---|---|
| **Estimate** | 10–14 wk (~2.5–3.5 months) · 1 FTE with AI assistance |
| **Depends on** | [08](./08-styles-and-assets.md) (Tailwind v4 added additive, July 2026 — done) |
| **Blocks** | Enabling Tailwind preflight; deleting `sassc`/`sass-rails`/Bourbon/Neat; final "one styling system" exit criteria for [08](./08-styles-and-assets.md) |
| **Status** | Wave T0 done (2026-08-03) — cleanup/convention fixes landed, see [CHANGELOG](./CHANGELOG.md#wave-t0--scsstailwind-cleanup--convention-fixes-done). T1 next. |

[← Summary](./README.md)

---

## Goal

Retire all ~8,100 lines of legacy global SCSS (`app/assets/stylesheets/`) in favour of Tailwind
utilities, so the codebase ends with **one** styling system instead of two running side by side.
Unlike the Vue 2→3 migration (component-by-component), this is a **CSS-class-by-CSS-class** cutover
that cuts across both ERB views and already-migrated Vue3 islands. It finishes with Tailwind
preflight enabled and the legacy Sass pipeline (`sassc`, Bourbon, Neat) deleted.

**Not this doc's scope:** the Dart Sass compiler swap (`sassc`→`dartsass-rails`) tracked in
[08](./08-styles-and-assets.md)'s "Sass / compiler" task list — that's a backend pipeline concern,
independent of whether the *content* is SCSS or Tailwind. If both land, do the compiler swap first
(cheap, de-risks nothing here) or drop it entirely once this doc's final wave deletes all SCSS.

---

## Baseline (audited August 2026)

- **131 files, 8,119 lines** under `app/assets/stylesheets/` (the ~100/~8.7k estimates in
  [08](./08-styles-and-assets.md) undercounted nested `card/`, `cards/`, `attributes/`, `stats/`
  sub-partials).
- **Only 15 of ~100 Vue3 islands have any `<style>` block at all.** The other **~85 are 100%
  dependent on legacy global SCSS** for every class-based style. **This means the CODE-CONVENTIONS.md
  rule-4 "exception" list (`ListingPageCard`, Wave 8 `Stats*`/`ChartRowPa`/`ChartRowStacked`, Wave 9
  `Dropdown`, Wave 10 `Pame/*`) badly undersells the real scope** — e.g. `NavBar/*`, all 8 `Map/*`
  sub-islands, `Search/*`, `SearchAreas/*` (except `SiteInput`/`TabStrip/Tab`), `Download/*`,
  `Carousel/Themes/Card.vue`, `RegionCountryPages/Index.vue`, `Attributes/*`, and more all still
  render unprefixed legacy BEM classes with zero component-owned styling. **A CSS migration wave has
  to touch nearly every island's template classes, not just the 6 named exceptions.**
- **Three class-naming buckets already exist in practice, only two are documented:**
  - `ct-` — Vue-component-scoped BEM (CODE-CONVENTIONS.md rule 4). ✅ documented.
  - `tw-shared-` — cross-cutting reusable `@apply` utilities, `app/frontend/styles/shared.css`
    (rule 5). ✅ documented, **but the doc's own reference (`styles/shared/base.css`) is stale — the
    real file is the flat `styles/shared.css`, no `shared/` subfolder exists.** Fix this doc bug in
    Wave 0.
  - `vw-` — ERB-**view**-level Tailwind classes for chrome that belongs to no single Vue component
    (`app/frontend/styles/views/{topbar,topbar-secondary}.css`, e.g. `vw-topbar__container`). **Not
    documented anywhere.** This migration touches views constantly, so codify it as rule 4b in Wave 0
    rather than leaving it an unnamed precedent.
- **Baseline correction (Wave T0 re-verify, confirms the "re-check for drift" risk below was real):**
  this doc originally listed `_popup.scss` and `_social.scss` as confirmed-dead. **They are not.**
  `_popup.scss`'s `.popup--download`/`.popup__ul`/`.popup__link` are actively rendered by
  `Download/Popup.vue` (with passing Vitest coverage) — folded into **Wave T4**'s Download family
  alongside `Modal`/`Commercial`. `_social.scss`'s `.social--media`/`.social__icon` are actively used
  by `_footer.html.erb`, `_head.html.erb`, `_topbar-secondary.html.erb`, `_social-share.html.erb`,
  `_social-follow.html.erb`, and two Comfy CMS partials — folded into **Wave T2** (views-only chrome).
  Neither was deleted; both need the normal rewrite-and-delete treatment in their assigned wave, not
  a T0 shortcut.
- **Confirmed dead SCSS** (re-verified via precise `class=`-usage grep, not just raw token match —
  several of the original candidates below turned out to have real consumers too and were kept, see
  per-file notes): `_selector.scss` (whole file, 0 consumers, deleted), plus the *class* (not mixin)
  halves of `base/_circles.scss` (only `.circle--grey-black`; `.circle-basic`/`-large`/`-medium`/
  `-small`/`-grey-xlight`/`-icon` mixins kept), `helpers/_accessibility.scss` (only the
  `.screen-reader{}` rule; the `@mixin screen-reader` itself stays — still `@include`d by
  `_v-map-filters.scss`, so this file could **not** be deleted outright as originally planned),
  `utilities/_media-queries.scss` (only the 4 `.breakpoint-*-up/down` classes; `breakpoint()`/
  `responsive()` mixins kept), `helpers/_helpers.scss` (only `.inline-block`, `.full-height`, `.red`,
  `.white`, `.thin`, `.ul-inline`, `.text-right`, `.text-left`, `.relative`, `.bottom-right`,
  `.center-right`, `.top-right`, `.margin-space--right`, `.no-padding`, `.no-select` — `.block`,
  `.bold`, `.p-larger`, `.ul-unstyled`, `.text-center`, `.no-margin`/`.no-margin--top`,
  `.margin-center`, `.margin-space--bottom`/`--left`, `.hover--pointer` all have real consumers and
  stay for now, migrated properly in T3/T4), `utilities/_flexbox.scss` (`.flex-1` plus all 47
  column/alignment variants below `.flex-1-half`; the 10 classes `.flex`, `.flex-inline`, `.flex-row`,
  `.flex-column`, `.flex-wrap`, `.flex-no-shrink`, `.flex-h-center`, `.flex-h-between`, `.flex-v-start`,
  `.flex-v-center` have real consumers and stay). Their **mixins/functions** (`circle-basic`,
  `breakpoint()`, `flex()`, `rem-calc()`, etc.) stay alive — dozens of still-migrating files `@include`
  them — and get ported in Wave 1, not deleted in Wave 0.
- **`pdf.scss` (39 lines) is on a separate, still-active pipeline** — Sprockets-only, loaded via
  `stylesheet_link_tag 'pdf'` when `@for_pdf` is true, feeding `lib/modules/download/generators/
  pdf.rb`'s puppeteer rasterizer. **Not** touched by the recent "move backend pdf generator to
  frontend" commit (that only moved the puppeteer scripts, not this CSS). Isolated and low-risk, but
  must not be silently dropped — handled explicitly in the final wave.
- **`comfy/admin/cms/custom.scss` (11 lines) is Comfy CMS admin-only** — out of scope; it styles the
  content-editor backend, not the public site. Leave it on Sass indefinitely or migrate separately,
  whenever the CMS admin itself gets attention.

---

## Decisions

### Decision: three-prefix naming convention, formalized

| Prefix | Scope | Where defined | Home |
|---|---|---|---|
| `ct-` | Vue SFC template classes (component-owned BEM) | CODE-CONVENTIONS.md rule 4 | component's own `<style scoped>` |
| `vw-` | ERB view chrome with no owning Vue component (page shells, nav/footer wrappers, hero blocks) | **new — add as rule 4b this wave** | `app/frontend/styles/views/<name>.css` |
| `tw-shared-` | Reusable `@apply` utility/composite needed by >1 component or view | CODE-CONVENTIONS.md rule 5 | `app/frontend/styles/shared.css` (split into multiple files as it grows — see Wave 1) |

Fix the stale `styles/shared/base.css` reference in README.md's "Setup status" section and
CODE-CONVENTIONS.md rule 5 to match the real flat `styles/shared.css` filename in the same pass that
adds rule 4b.

### Decision: preflight stays off until the final wave

Tailwind's base reset (`preflight.css`) stays disabled (per [08](./08-styles-and-assets.md)) through
every wave in this plan — enabling it early would break every page still holding legacy SCSS, i.e.
almost the whole site until the last wave lands. Flip it on only in the **Finish** wave, after the
last SCSS file is deleted, then do a full-site visual sweep.

### Decision: prefer `flex`/`grid` + `gap-*` over margin/padding-based spacing

**Much of the legacy SCSS spaces siblings apart with margin/padding on each child** (e.g.
`.card + .card { margin-left: ... }`, `> * { padding-bottom: ... }`) rather than a `flex`/`grid`
container with `gap-x-*`/`gap-y-*` on the parent. This is a real structural smell, not just a naming
one — margin-based spacing breaks down at the edges (first/last-child overrides), doesn't collapse
cleanly when items wrap, and scatters the "how far apart are these things" decision across every
child instead of owning it once on the container. **Every wave in this plan (T2 onward) should
actively restructure spacing to `flex`/`grid` + `gap-*` on the container, not just transliterate the
existing margin/padding values into Tailwind's `m-*`/`p-*` utilities.** A 1:1 `margin-left: 20px` →
`ml-5` port is not a pass here — check whether the parent is (or should become) a flex/grid container
first, and reach for `gap-*` before reaching for `m-*`/`p-*` on the children.

**Where this still doesn't apply:** padding on a single element's own edges (a card's internal
padding, a button's padding) is not spacing-between-siblings and stays as `p-*`/`px-*`/`py-*` — this
rule targets the "N children need consistent space between them" pattern specifically, not all
padding/margin usage.

### Decision: migrate templates and styles together, per file group

Because ~85 Vue islands have **zero** existing `<style>` — porting their CSS is not "add a
`<style>` block next to unchanged markup", it's "rewrite the template's classes to `ct-`-prefixed
BEM + add the component's own `<style scoped>` with `@apply`", exactly like every prior Vue-migration
wave already did for the 15 components that got done alongside their Vue-3 rewrite. Group work by
**shared legacy SCSS file**, not by directory of Vue components, since several unrelated components
often share one legacy partial (e.g. `_lists.scss` styles both `Attributes/*` and `Stats/*`).

---

## Wave overview

| Wave | Scope | Depends on | Touches |
|---|---|---|---|
| **T0** | Delete confirmed-dead SCSS; fix stale doc refs; codify `vw-` (rule 4b) | — | docs only + 8 files deleted |
| **T1** | Shared Tailwind foundation — port mixins/functions to `@theme`/`@utility`, split `shared.css` | T0 | `styles/shared.css` → `styles/shared/*.css`, `tailwind.css` `@theme` |
| **T2** | Views-only global chrome (nav/footer/hero/cta/content-banner/custom) | T1 | ERB only, 0 Vue |
| **T3** | Views-only page shells + static card grids + form + CMS wysiwyg | T1 | ERB only, 0 Vue |
| **T4** | Vue-only leaves with no existing coupling (NavBar, Listing, Pagination, Search/SearchAreas non-exception, Download, form checkboxes) | T1 | Vue templates + new `ct-` styles |
| **T5** | Maps (`Map/*` — 8 sub-islands, `_map.scss` views wrapper) | T1, T4 | Vue + 1 ERB wrapper |
| **T6** | Charts + Stats (closes Wave-8 rule-4 exceptions) | T1 | Vue only |
| **T7** | Cards family + Listing cards + Carousel (closes `ListingPageCard` exception) | T1, T4 | Vue + a few ERB card grids |
| **T8** | PAME + Dropdown + Select (closes Wave-9/10 rule-4 exceptions) | T1 | Vue only |
| **T9** | Residual tabs/filters coupling (`_tabs.scss`, `_filters-sidebar.scss`) | T4, T5, T7 | Vue only |
| **T10** | Finish — enable preflight, delete legacy pipeline, handle `pdf.scss` | T0–T9 | site-wide |

*Estimates below assume the same "AI-assisted, 1 FTE, verify live in browser every wave" cadence used
throughout the Vue migration (see CHANGELOG.md) — screenshots before/after, not just Vitest/typecheck,
since this is a pure-visual risk surface.*

---

## Wave T0 — Cleanup & convention fixes (~2–3 days)

**Goal:** shrink the real migration surface and lock in naming before any real work starts.

- [x] Re-verify each deletion with a fresh, precise (`class=`-usage, not raw-token) grep sweep across
      `app/views` + `app/frontend/components` before removing anything — the August baseline had
      drifted: `_popup.scss` and `_social.scss` turned out to have real consumers (moved to T4/T2
      respectively, see baseline correction above), and several `_helpers.scss`/`utilities/_flexbox.scss`
      classes assumed dead also had real consumers (kept, migrated properly in T3/T4 instead).
- [x] Delete confirmed-dead SCSS *classes* (keep mixins/functions): `_selector.scss` (whole file),
      the `.screen-reader{}` class rule in `helpers/_accessibility.scss` (mixin kept — still consumed
      by `_v-map-filters.scss`), `.circle--grey-black` in `base/_circles.scss`, the 4 `.breakpoint-*`
      classes in `utilities/_media-queries.scss`, and the confirmed-zero-consumer subset of
      `helpers/_helpers.scss` / `utilities/_flexbox.scss` classes (see baseline correction for the
      exact per-class list — most classes in those two files turned out to have real consumers and
      were left in place for proper T3/T4 migration, not deleted here).
- [x] Add **rule 4b (`vw-` prefix)** to CODE-CONVENTIONS.md, matching rule 4's format, with
      `views/topbar.css` as the reference example.
- [x] Fix the stale `styles/shared/base.css` reference in CODE-CONVENTIONS.md rule 5 + "Setup status"
      to say `styles/shared.css` (README.md turned out not to contain this reference — only
      CODE-CONVENTIONS.md did).
- [x] `yarn vite:build` clean; forced a full Sprockets `application.css` compile (caught + fixed two
      SCSS-internal breakages the deletions caused — a dangling `@import` in `_select.scss` and a
      dead `@extend` in `_charts.scss`, see CHANGELOG); live-curled home, gdpame, a country page, and
      two listing pages, all 200. Full detail: [CHANGELOG](./CHANGELOG.md#wave-t0--scsstailwind-cleanup--convention-fixes-done).

---

## Wave T1 — Shared Tailwind foundation (~1–1.5 wk)

**Goal:** give every later wave the shared primitives it needs, so T2+ is "apply an existing utility",
not "invent one per component."

- [ ] Split `app/frontend/styles/shared.css` into `app/frontend/styles/shared/{base,buttons,icons,
      forms,typography,shadows}.css` (one `@utility tw-shared-<name>` group per concern), per rule 5 —
      only split where >1 real consumer already exists; don't pre-create empty buckets.
- [ ] Port `utilities/_media-queries.scss`'s `breakpoint()` mixin usage to Tailwind's native
      `sm:`/`md:`/`lg:`/`xl:` breakpoints — confirm the legacy breakpoint pixel values match Tailwind's
      defaults or add matching values to `@theme` (`--breakpoint-*`) if they diverge.
- [ ] Port `utilities/_flexbox.scss`'s `flex()`/`flex-h-between` etc. mixins to Tailwind's native
      `flex`/`justify-*`/`items-*` utilities (1:1, no shared utility needed — these are Tailwind's own
      bread and butter).
- [ ] Port `utilities/_rem-calc.scss` — Tailwind's spacing scale is already rem-based; confirm existing
      `@theme` spacing (if customized) matches the legacy scale's actual pixel outputs before assuming
      arbitrary-value replacement is unnecessary.
- [ ] Turn `helpers/mixins/_text.scss` and `helpers/mixins/_icons.scss` (SVG icon mixins) into shared
      `@utility tw-shared-icon-*` classes — these back a large fraction of both views' and components'
      icon rendering (`_icons.scss` has 25 direct consumers across Views+Vue).
      `helpers/_border-and-shadows.scss` similarly → `tw-shared-shadow-*`.
      `helpers/_form-fields.scss` → `tw-shared-input-*` (feeds Wave T4's form work).
      `helpers/_images.scss` (`image-placeholder` mixin) → `tw-shared-image-placeholder`.
      `helpers/_beautify-scrollbar.scss` → `tw-shared-scrollbar` (feeds T7/T8's scrollable
      cards/tables).
- [ ] Extend the `@theme` color tokens in `tailwind.css` beyond the 8 already added if `_settings.scss`
      has more variables in active use (audit `_settings.scss`'s full variable list against what's
      actually still referenced once T0's dead code is gone).
- [ ] `yarn typecheck` / `yarn lint` / `yarn vite:build` clean. No visual change expected this wave
      (pure infrastructure) — spot-check anyway.

---

## Wave T2 — Global chrome, views-only (~1 wk)

**Goal:** the site-wide chrome every page shares, zero Vue coupling, lowest risk.

Files: `base/_base.scss` (`.site-width`/`.container`), `_nav.scss`'s ERB-owned parts (`_topbar.html.erb`
— `NavBar/Index.vue`'s own legacy-class usage is T4, not here), `_footer.scss`, `components/hero/*`
(5 files, 100% views-only), `_cta.scss` (100% views-only), `_content-banner.scss` +
`content-banner/_content-banner-basic.scss`, `custom.scss` (home page stat blocks),
`helpers/_background.scss` (`.bg--*`, 8 consumers, all views), `_social.scss` (moved here from the
T0 baseline's mistaken "dead" list — real consumers: `_footer.html.erb`, `_head.html.erb`,
`_topbar-secondary.html.erb`, `_social-share.html.erb`, `_social-follow.html.erb`, plus two Comfy CMS
partials, all views-only).

- [ ] Rewrite each `.erb` partial's markup to `vw-`-prefixed classes (rule 4b), backed by
      `app/frontend/styles/views/<name>.css` per file/section (e.g. `views/hero.css`, `views/footer.css`).
- [ ] Delete the corresponding legacy SCSS file once its last ERB consumer is switched (confirm via
      grep, same discipline as the Wave 12 Vue dead-code sweep).
- [ ] Live-verify: home, a hero-bearing thematic page, footer on any page, a CTA-bearing static page,
      effectiveness green-list tab (content-banner). Screenshot before/after (desktop + mobile), not
      just curl — this is a pure-visual wave.

---

## Wave T3 — Page shells & static card grids, views-only (~1 wk)

Files: `pages/_country.scss`, `_error-page.scss`, `_news.scss`, `_region.scss`, `_resource.scss`,
`_site.scss` (all `.page--*`, 0 Vue), `cards/_cards-circles.scss`, `_cards-facts.scss`,
`_cards-scrollable.scss`, `_cards-squares.scss`, `_cards-message.scss` (static content-page card
grids, not the Vue-rendered card families — those are T7), `components/_form.scss` + `form/*`
overlap-check (confirm `_checkbox`/`_input`/`_radio` really are Vue-only per baseline before assuming
0 views work here), `helpers/_cms.scss` (`.cms-wysiwyg` CMS rich-text wrapper).

- [ ] Same `vw-` treatment as T2.
- [ ] `_helpers.scss`'s remaining utility classes not already deleted in T0 (`.block`, `.red`, `.bold`,
      etc.) — replace call sites with native Tailwind equivalents (`block`, `text-red-500`, `font-bold`)
      directly in the ERB, then delete the file.
- [ ] Live-verify: country page, region page, a resource page, error page (404/500), one CMS static
      page with a facts/circles/squares/scrollable card grid.

---

## Wave T4 — Vue leaves with no existing styling (~1.5–2 wk, largest single wave)

**Goal:** close the ~85-component gap for the lowest-coupling islands first, mirroring the original
Vue-migration principle (leaf/zero-coupling before global chrome/state).

Components (confirmed zero `<style>` block, legacy-class-dependent): `NavBar/*`, `Listing/*`
(`_listing.scss`), `PaginationInfinityScroll`/`Pame/Table/Pagination`/`Search/Pagination`/
`SearchAreas/Index` pagination usage (`_pagination.scss`), `Search/*` except the already-migrated
`SiteInput.vue`, `SearchAreas/*` except `TabStrip/Tab.vue` (`_search-autocomplete.scss`,
`_search-results.scss`, `_search-results-areas.scss`, `_autocomplete.scss`), `Filters/Checkboxes/Item`,
`SearchAreas/{RadioButtons,CheckboxSearch,FilterGroup}` (`form/_checkbox.scss`, `_input.scss`,
`_radio.scss`), `Download/{Modal,Commercial,Popup}` (`modal/_modal-download.scss`,
`_modal-download-commercial.scss`, `components/_popup.scss` — moved here from the T0 baseline's
mistaken "dead" list; real consumer, with passing Vitest coverage to update alongside the rewrite).

- [ ] Per component: rewrite template classes to `ct-`-prefixed BEM, add `<style scoped>` with
      `@apply` (using T1's shared utilities where applicable), delete the legacy SCSS once its last
      consumer moves.
- [ ] Since several of these share one legacy file (e.g. `_search-autocomplete.scss` feeds both
      `Search/Index.vue` and `SearchAreas/InputAutocomplete.vue`), sequence components sharing a file
      together so the file can be deleted in one sub-step rather than left half-migrated.
- [ ] Existing Vitest coverage should mostly survive (BEM class renames may break class-based
      selectors in specs — update alongside, same as every prior wave).
- [ ] Live-verify: nav burger + search topbar, a listing page (news/resources), search results page,
      search-areas page with filters/pagination, a download modal + the commercial download modal.

---

## Wave T5 — Maps (~1 wk)

Files: `components/maps/*` (8 files: `_v-map-header`, `_v-map-filters`, `_v-map-filter`,
`_v-map-pa-search`, `_v-map-disclaimer`, `_v-map-toggler`, `_v-map-baselayer-controls`,
`_v-map-popup`), `_map.scss` (views wrapper).

- [ ] Same treatment as T4 for all 8 `Map/*` sub-islands (`Header`, `Filters`, `Filter`, `PaSearch`,
      `Disclaimer`, `Toggler`, `BaselayerControls`) plus the dynamically-set `.v-map-pin` class in
      `useMapPopups.ts` — that one is set via `pin.className = ...` in JS, not a template literal, so
      update the composable, not just a `.vue` template.
- [ ] `_map.scss`'s views-only wrapper markup → `vw-map-section` classes in `_map-section` ERB partials.
- [ ] **Real-browser verification is non-negotiable here** — per the existing Wave-6 "CORS bug" lesson
      already on file, map interaction bugs never show up in curl/Vitest. Test pan/zoom, filters panel
      open/close, baselayer toggle, PA search box, popups, on both a country map and the global map.

---

## Wave T6 — Charts + Stats, closes Wave-8 rule-4 exceptions (~1–1.5 wk)

Files: `components/_charts.scss` + `charts/*` (7 files), `card/stats/*` (9 files),
`components/_lists.scss` (shared by `Attributes/*` and `Stats/*`).

Components: `Chart/RowPa`, `Chart/RowStacked`, `AmChart/Pie`, `AmChart/Multiline`,
`Stats/{Sources,IucnCategories,Sites,TooltipInfo,Governance,Designations,Message,Coverage}`,
`Attributes/*` (Wave 9's family, sharing `_lists.scss`).

- [ ] Rewrite each to `ct-`-prefixed styles per the same pattern; this wave specifically **closes** the
      `Stats*`/`ChartRowPa`/`ChartRowStacked` rule-4 exception entries in CODE-CONVENTIONS.md — remove
      them from the exception-precedent list once done, so the doc doesn't keep advertising a resolved
      exception as current guidance.
- [ ] amCharts 4→5 is explicitly out of scope here (already deferred separately per README) — style
      the amCharts *wrapper* markup only, not the chart library's own internals.
- [ ] Live-verify: country/region page stats blocks, a PA show page's `attributes-*` cards, the
      coverage-growth chart, a stacked chart row.

---

## Wave T7 — Cards family, Listing cards, Carousel (~1–1.5 wk)

Files: `components/_cards.scss` (aggregator) + `cards/cards/{_cards-articles,_cards-basic,
_cards-resources,_cards-themes,_cards-search-results,_cards-search-results-areas}.scss`,
`card/_card-theme.scss`, `card/attributes/{_card-attributes-pa-and-parcels,
_card-attributes-parcels-dropdown}.scss`.

Components: `ListingPageCard/{News,Resources}/{Index,Card}`, `Carousel/Themes/{Index,Card}`,
`Search/Results/Item`, `SearchAreas/Results/Item`, `Attributes/ProtectedArea/*`,
`Dropdown/ParcelsDropdown.vue` (card-family consumer despite living in the `Dropdown/` folder — don't
conflate with T8's `ct-dropdown` work).

- [ ] This wave **closes the `ListingPageCard` rule-4 exception** — remove it from
      CODE-CONVENTIONS.md's exception-precedent list once done.
- [ ] `Carousel/Themes/Card.vue` already has partial `ct-theme-card` styling (from the Swiper
      migration) alongside leftover legacy `card__`/`card--` classes for some elements — finish the job
      rather than leaving it half-`ct-`/half-legacy.
- [ ] Live-verify: news/resources listing pages, home + marine carousels, search results (both site
      and area search), a PA show page's attributes cards, the gdpame parcels dropdown.

---

## Wave T8 — PAME + Dropdown + Select, closes Wave-9/10 rule-4 exceptions (~1–1.5 wk)

Files: `components/table/{_table-pame,_table-head-pame,_table-horizontal-scroll,
_table-head-horizontal-scroll}.scss`, `components/filters/_filters-pame.scss`,
`components/modal/_modal-pame.scss`, `card/attributes/_card-attributes-pame.scss`,
`components/_dropdown.scss`, `_tooltip.scss` (residual `.tooltip__target` in PAME table headers),
`components/select/{_select-searchable,_select}.scss`.

Components: `Pame/{Modal,Filters/**,Table/**}`, `Attributes/Pame/{Pame,List}`, `Dropdown/{Base,
Options}` (the true `ct-dropdown` — note it's pre-named `ct-` already but the CSS body underneath is
still plain legacy-mixin SCSS, not `@apply`, so it still needs the real rewrite).

- [ ] Closes the **Wave 10 `Pame/*`** and **Wave 9 `Dropdown`** rule-4 exceptions — remove both from
      CODE-CONVENTIONS.md's exception list once done.
- [ ] Confirm `_select-searchable.scss` is genuinely superseded by `Search/SiteInput.vue`'s existing
      Tailwind styling before assuming zero migration work — the T0-era audit flagged this as
      "not independently confirmed," verify directly before skipping it.
- [ ] `_table-horizontal-scroll.scss`/`_table-head-horizontal-scroll.scss` use
      `helpers/_beautify-scrollbar.scss`'s mixin (ported to `tw-shared-scrollbar` in T1) — use that
      shared utility rather than re-deriving scrollbar styling per table.
- [ ] Live-verify: gdpame page — table sort/scroll, filters panel, pagination, modal open, the sticky
      table header tooltip.

---

## Wave T9 — Residual tabs/filters coupling (~0.5 wk)

Files: `_tabs.scss` (distinct from the already-fully-migrated `Tabs.vue`'s own `ct-tabs*` styling —
this is the *other* `.tabs` consumers), `_filters-sidebar.scss`.

Components: `SearchAreas/Index.vue`, `SearchAreas/CheckboxSearch.vue`, `RegionCountryPages/Index.vue`
(all three still read the legacy `.tabs` class, unrelated to the `Tabs` island itself),
`SearchAreas/FilterGroup.vue`, `Listing/FilterGroup.vue`.

- [ ] Straightforward `ct-`-prefixed rewrite per the established pattern — small, isolated, last
      because it depends on T4/T5/T7's components already being done (shared filter-group patterns).
- [ ] Live-verify: search-areas page filters + tab strip, region/country page tabs, a listing page's
      filter sidebar.

---

## Wave T10 — Finish (~1 wk)

- [ ] Confirm zero remaining `@import` targets in `application.scss` besides `_settings.scss` (vars/
      functions, if anything still genuinely needs them) — delete `application.scss`'s glob imports,
      the `components/`, `pages/`, `helpers/`, `utilities/`, `base/` directories, `custom.scss`.
- [ ] Decide `pdf.scss`'s fate explicitly (do not let it become an accidental last SCSS file nobody
      decided about): either (a) port its 39 lines to a small hand-written Tailwind-adjacent CSS file
      the PDF pipeline links directly (simplest — it's tiny and isolated), or (b) leave it on the
      existing Sprockets/sassc path indefinitely since it's CMS/PDF-only and never touches Tailwind's
      `@source` scan anyway. Either way, **re-run a real PDF export smoke test** (per
      [08](./08-styles-and-assets.md)'s existing "PDF & Comfy" task) — this is the one path Tailwind's
      dev-server verification never covers.
- [ ] Leave `comfy/admin/cms/custom.scss` untouched (documented out-of-scope, Comfy admin only) unless
      separately requested.
- [ ] Remove `bourbon`/`neat` gems and the Sprockets `assets.paths` entries for them (per
      [08](./08-styles-and-assets.md)'s existing task, now finally safe — nothing imports them once all
      SCSS above is gone).
- [ ] Remove `sassc`/`sass-rails` from the Gemfile (or leave `dartsass-rails` if the compiler-swap task
      from 08 already landed separately — either way, there's no SCSS left to compile).
- [ ] **Enable Tailwind preflight** (`app/frontend/styles/tailwind.css` — uncomment
      `@import "tailwindcss/preflight.css" layer(base);`) — the one previously-forbidden change,
      now safe since no legacy SCSS remains to fight it.
- [ ] Full-site visual sweep post-preflight: every page type hit in every prior wave's "Live-verify"
      step, plus anything not explicitly covered above (404/500 pages, PDF export, Comfy admin — admin
      is unaffected since preflight only applies to the public-site Vite entrypoint, confirm that
      boundary holds).
- [ ] Update [08](./08-styles-and-assets.md)'s exit criteria checklist and this doc's Status line to
      "done."

---

## Cross-cutting rules for every wave

1. **Rewrite templates and styles together**, don't add Tailwind alongside untouched legacy markup —
   matches the existing Vue-migration convention (CODE-CONVENTIONS.md rule 4/8), just applied to a CSS-
   first wave grouping instead of a component-first one.
2. **Delete the legacy SCSS file the moment its last consumer moves**, confirmed via a fresh
   `grep -rl` sweep (not trusting this doc's baseline, which will drift as waves land) — mirrors the
   mark-and-sweep discipline used in the Wave 12 dead-code cleanup.
3. **Real-browser verification every wave**, not just `yarn typecheck`/`vite:build`/Vitest — this is a
   pure visual-regression risk surface, and multiple past waves (Maps' CORS bug, Carousel's
   transition-race bug) only surfaced live. Screenshot desktop + mobile before/after per wave.
4. **Update CODE-CONVENTIONS.md's rule-4 exception-precedent list as each exception closes** (T6, T7,
   T8) — don't let the doc keep citing a resolved exception as live guidance for future components.
5. **No silent scope drops.** If a wave's file list turns out to have a component this doc didn't
   anticipate (the baseline audit was a fast sweep, not exhaustive per-selector), log it in
   CHANGELOG.md the same way every prior wave's surprises were logged, rather than quietly absorbing
   or skipping it.
6. **Restructure sibling spacing to `flex`/`grid` + `gap-*`, don't just transliterate margin/padding.**
   Per the Decision above — this is a real per-file review step in every wave (T2–T9), not a one-time
   note: when a legacy rule spaces siblings via margin/padding on the children, convert the parent to
   `flex`/`grid` and move the spacing to `gap-x-*`/`gap-y-*` on the container, rather than porting the
   same margin values to `m-*` utilities on each child.

---

## Risks

| Risk | Mitigation |
|---|---|
| Baseline audit (Aug 2026) drifts as waves land — a "views-only" file turns out to have a Vue consumer added since | Re-`grep` before each wave starts, not just trust this doc |
| ~85-component gap is bigger than the named rule-4 exceptions suggested — a wave runs long | Waves T4–T9 are already sized around the real (audited) scope, not the doc's stale exception list; re-estimate after T4 (largest wave) actually lands |
| Enabling preflight in T10 breaks something not caught by per-wave spot checks | Full-site sweep is its own checklist item in T10, not assumed free from earlier waves' partial checks |
| `pdf.scss` gets forgotten since it's on a separate pipeline nobody touches day-to-day | Explicit T10 checklist item + PDF smoke test, not left implicit |
| Vitest specs querying legacy BEM class selectors silently pass on stale classes after a rename | Update specs in the same commit as the template rewrite, per component, not batched at the end |

---

## Exit criteria

- `app/assets/stylesheets/` contains at most `_settings.scss` (if anything in it survives) and
  `comfy/admin/cms/custom.scss` (explicitly out of scope) — everything else deleted.
- Tailwind preflight enabled.
- `bourbon`/`neat`/`sassc`/`sass-rails` removed from the Gemfile (or the Dart Sass swap done instead,
  per [08](./08-styles-and-assets.md), if that path was taken for the admin/PDF residue).
- CODE-CONVENTIONS.md rule 4's exception-precedent list is empty (or explicitly states none remain).
- PDF export smoke-tested post-cutover.
- Full-site visual sweep done and signed off.
