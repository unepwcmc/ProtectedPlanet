# 16 — SCSS → Tailwind migration (styling cutover)

| | |
|---|---|
| **Estimate** | 10–14 wk (~2.5–3.5 months) · 1 FTE with AI assistance |
| **Depends on** | [08](./08-styles-and-assets.md) (Tailwind v4 added additive, July 2026 — done) |
| **Blocks** | Enabling Tailwind preflight; deleting `sassc`/`sass-rails`/Bourbon/Neat; final "one styling system" exit criteria for [08](./08-styles-and-assets.md) |
| **Status** | **Re-audited 2026-08-10 against real file state — this doc had drifted badly.** Between 2026-08-04 and 2026-08-10 a large amount of real migration work landed via ~45 direct small commits ("feat: migrate resources", "feat: migrate cards, add cms text style", etc.) that were never logged back into this doc or CHANGELOG.md, whose last entry still describes T3 as "in progress." Reconciled findings: **T0-T2 done** (as before). **T3 is now fully done** — every item in its old "remaining scope" list (error-page, news, resource, `_site.scss` col-wrapper, static card grids, all 4 thematic/data-area page shells: marine/effectiveness/gdpame/wdpca, all 9 CMS layout templates, all 5 hero variants) is migrated and verified on disk; only `helpers/_cms.scss` remains, now fully orphaned (zero ERB consumers) and just needs deleting. **T7 (cards/carousel) is now almost done** (2026-08-13) — the ERB-only static card grids, `ListingPageCard/*`, `Carousel/Themes/Card.vue`, `SearchAreas/Results/{Index,Item}.vue`, and now `Search/Results/{Index,Item}.vue` are fully migrated (closes that rule-4 exception). `Attributes/ProtectedArea/*` turned out to already be done too — it was actually closed under **T6**, this doc's own T7 checklist just never got updated to say so (corrected this pass). Only `Dropdown/ParcelsDropdown.vue` remains. **T6 has one component done**: `Chart/RowPa` was renamed to `TotalCoverageChart.vue` during a "migrate coverage chart" commit and is fully `ct-`/`@apply`-based; the rest of T6 (Stats/*, RowStacked, AmChart/*) is untouched. **T4 is now fully done** (2026-08-11) — every named component (`NavBar/*`, `Listing/{Index,List}.vue` + shared `Filters/Trigger.vue`, `Listing/FiltersPanel`+`FilterGroup`, `Filters/Checkboxes/{Index,Item}`, `Pame/Table/Pagination`+`Search/Pagination`, `Download/{Index,Modal,Commercial,Popup,Item}`, `SearchAreas/TabStrip/{Index,Tab}`, `Search/Index`, `SearchAreas/{RadioButtons,CheckboxSearch,FilterGroup,FiltersPanel}`, and finally `SearchAreas/Page.vue`'s own root/container classes) is migrated — see the T4 section and CHANGELOG for the full detail across this multi-day wave. **T5 (Maps) is now fully done** (2026-08-12) — all 8 `Map/*` sub-islands + `Index`/`Base` rewritten to `ct-map-*`, `_map.scss`/`_autocomplete.scss`/8 `components/maps/*.scss` files + the now-fully-orphaned `helpers/_accessibility.scss` all deleted; the plan doc's own T5 scope (an ERB `_map-section` partial, a still-live legacy Vue2/mapboxgl map) turned out to be stale — both were already gone from earlier, undocumented commits (2026-07-24/2026-08-03) — see CHANGELOG for the full reconciliation. **T6 is now 11/~13 components done** (2026-08-12, up from 1 —
`AmChart/Multiline` turned out already done via an undocumented commit, and `AmChart/Pie`, `Chart/
RowStacked`, all of `Stats/*` except `Coverage`/`TooltipInfo`, all of `Attributes/*`, and the
`RegionCountryPages/Index` wrapper landed this session; also fixed a real regression where T7's SCSS
deletion had silently unstyled `Stats/Sites.vue` — see the T6 section and CHANGELOG). Only `Stats/
{Coverage,TooltipInfo}` and the `card--stats-overview` ERB card remain. **T8, T9 are confirmed still 100% untouched** (re-verified via fresh grep against current Vue component consumers, not just trusted from the old baseline). **Two new findings**: `shared/forms.css` and `shared/scrollbar.css` (from T1) are wired into `tailwind.css` but have zero live consumers anywhere — dead weight, flag for removal or reuse when T4/T8 land. The CMS layout files (`views/layouts/cms/*.css`) use three inconsistent `vw-` prefix schemes (`vw-layouts-cms-*`, `vw-cms-*`, mixed `@utility`/plain-class syntax) — violates rule 4c's path-mirroring rule (added 2026-08-05) but works today; worth a small consistency pass. Custom breakpoint tokens were reverted 2026-08-03 — every consumer uses native `md:`/`lg:`/`2xl:` — see CODE-CONVENTIONS.md rule 21. **2026-08-13: T7 and T8 are both now fully done** — `Dropdown/ParcelsDropdown.vue` closed out T7; the whole `Pame/*` family + `Dropdown/{Base,Options}` closed out T8, deleting `_dropdown.scss`, `_filters-pame.scss`, `_modal-pame.scss`, `table/{_table-pame,_table-head-pame,_table-horizontal-scroll,_table-head-horizontal-scroll}.scss`, `components/_table.scss`, `_tooltip.scss`, `components/_select.scss` + `select/{_select,_select-searchable}.scss`, and `base/_buttons.scss` — see the T7/T8 sections and CHANGELOG for full detail. **2026-08-14: T9 confirmed already done** (its named files/components were closed by same-day, undocumented direct commits after the T8 session ended — `_tabs.scss`/`_filters-sidebar.scss` no longer exist on disk, and `SearchAreas/{Index,CheckboxSearch,FilterGroup}`, `Listing/FilterGroup`, `RegionCountryPages/Index` are all already `ct-`-migrated with real `<style scoped>`). **T10 mostly done the same session**: found and fixed a live-breaking bug (`bundle exec rake assets:precompile` was failing — two files left over from the T8 deletion pass, `components/_filters.scss`/`_modal.scss`, still `@import`ed their now-deleted `filters-pame`/`modal-pame` targets), which cascaded into confirming and deleting the **entire remaining legacy SCSS tree** (24 more files — every `base/*`, `helpers/*`, `helpers/mixins/*`, `utilities/{_flexbox,_media-queries}.scss` file; `application.scss` now compiles to a byte-for-byte empty file) and removing the now-fully-unused `bourbon`/`neat` gems. Only `_settings.scss`, `utilities/_rem-calc.scss`, `application.scss` (now a stub), `pdf.scss` (kept — see T10), and the out-of-scope `comfy/admin/cms/custom.scss` remain on disk. **Only remaining checklist item in the whole plan: enable Tailwind preflight + do the final full-site visual sweep** — see T10 below. |

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

- **Current state (re-audited 2026-08-14, end of this session's T9/T10 work): 4 legacy `.scss` files
  remain** — `_settings.scss`, `utilities/_rem-calc.scss`, `application.scss` (now a stub importing
  just those two), and `pdf.scss` (kept on the SCSS pipeline, see T10's decision) — plus the
  out-of-scope `comfy/admin/cms/custom.scss`. Down from 131 originally. See the Status line above and
  CHANGELOG's T9/T10 sections for the full reconciliation — this count has drifted from hands-on
  commits outpacing doc updates several times now, re-verify with `find app/assets/stylesheets -name
  "*.scss" | wc -l` before trusting it in a future session regardless.
- **Original baseline — 131 files, 8,119 lines** under `app/assets/stylesheets/` (the ~100/~8.7k estimates in
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
    (`app/frontend/styles/views/{topbar,topbar-secondary}.css`, e.g. `vw-layouts-partials-topbar__container`). **Not
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

**Correction (T3, 2026-08-03): no bare utility classes in ERB markup, not even cross-cutting ones.**
T2 shipped an exception to the "one combined class per element" rule (below) for genuinely
cross-cutting utilities — e.g. `<div class="page--country vw-bg--grey-xlight vw-base-spacer-small--top">`
was left as three stacked classes, on the reasoning that `vw-base-*`/`vw-bg--*` "are the
shared-utility tier doing exactly what it's for" (see CHANGELOG's T2 entry). **That exception is
retracted.** Every element in ERB markup gets exactly **one** class, full stop — a page/view still
gets its own single `vw-<page>`/`vw-<page>__<part>` class (in `views/<page>.css`) even when all it
does is `@apply` a handful of `tw-shared-*` ingredients with no page-specific tweaks of its own.
Reasons: (1) it's the same rule Vue SFCs already follow (one template class, ingredients composed
in `<style scoped>`) — views shouldn't get a different rule just because they lack a component
boundary; (2) it keeps a page's styling changeable from one file (`views/<page>.css`) without
touching the ERB; (3) it gives every page shell a natural home for page-specific overrides later,
instead of "add a 4th stacked class" creeping back in. Applied retroactively to `country/show.html.erb`
(see T3 below) as the reference example; every remaining T3 page-shell file (region, protected-area/
site, error, news, resource, CMS static pages) gets the same treatment, not just new work.

**Correction (T3, 2026-08-03): `vw-base-*`/`vw-bg--*` were never `vw-` in the first place.**
Both are consumed standalone by many *unrelated* views (T2's own baseline already listed `hero.css`/
`cta.css`/`footer.css` plus 30+ ERB page templates) — that's the literal `tw-shared-` definition
above ("needed by >1 component or view"), not `vw-`'s ("chrome with no owning component" — singular,
one page). T2 misnamed and mis-homed the whole family in `views/base.css`/`views/background.css`.
Fixed in T3: moved wholesale to `shared/base.css`/`shared/background.css` as `tw-shared-base-*`/
`tw-shared-bg--*`, all ~40 consumers repointed. This also surfaced a real duplicate: `tw-shared-
base-container` already existed in `shared/base.css` (added in T1, consumed by `views/topbar.css`,
`views/topbar-secondary.css`, `Tabs.vue`, `Banner/Index.vue`) using native `md:`/`lg:` (768px/1024px)
breakpoints, written *before* T2's investigation into the legacy `.container` class's real compiled
breakpoints (`medium:`/`large:`, 1025px/1201px, see T2's own file-header comment on the shadowed
`gutters()` mixin). The two were never reconciled. Resolved by keeping one definition — the
legacy-verified `medium:`/`large:` version — so `topbar`/`Tabs`/`Banner` now inherit the corrected
breakpoints too. **This is a real, if narrow, behaviour change for those 3 pre-existing consumers**
(container padding now steps up at 1025px/1201px instead of 768px/1024px) — needs a live check on
tablet-width viewports for the topbar and any Tabs/Banner-bearing page, not just the pages this wave
already touches.

**Correction (T3, 2026-08-03, second pass): the retracted-exception fix above was only actually
applied to `country/show.html.erb` — every other file in the 40-consumer rename list was given a
purely mechanical `vw-base-*` → `tw-shared-base-*` / `vw-bg--*` → `tw-shared-bg--*` prefix swap,
which left every one of them with `tw-shared-*` classes exposed directly in ERB markup (often still
stacked 2-3 deep), the exact thing the rule above forbids. Tightened and made explicit:**
- **No `tw-shared-*` class (or any shared-tier class) may appear directly in a `class="..."`
  attribute in ERB, ever — not even a single one, not even with no page-specific tweaks.** Every
  element gets its own `vw-<page>`/`vw-<page>__<part>` class, defined in that page's
  `views/<page>.css`, whose `@apply` body is where `tw-shared-*` ingredients actually get consumed.
  `country/show.html.erb`/`views/country.css` is the reference shape. This is stricter than the
  first correction above (which only explicitly barred *stacking multiple* classes) — a page
  showing exactly one bare `tw-shared-base-container` is just as wrong as showing three stacked
  classes; the failure mode either way is the ERB depending on shared-tier naming directly instead
  of through its own page-owned indirection layer.
- **Default every rule to a real `@utility` (or, when the cascade-layer bug applies, a plain
  selector — see the existing pattern) applied *directly to the element that needs it*, never to a
  descendant reached via a parent class (`.parent h2 { ... }`), *unless* that descendant is
  CMS-authored rich-text content the developer cannot add a class to** (e.g. `.cms-wysiwyg`'s
  database-sourced `h1`/`h2`/`p`/`a` output — the one legitimate case for a bare-tag descendant
  selector, since there's no ERB `class="..."` to edit). Any element rendered by an ERB
  `<tag>...</tag>` — even one holding a CMS *value* like `<h2><%= title %></h2>` — is
  developer-controlled markup: give it its own class directly rather than reaching for it from the
  parent. Caught one real violation of this while fixing the above:
  `shared/base.css`'s `.tw-shared-base-container--component h2 { margin-top: 0; }` targets a plain
  ERB-authored `<h2>` (in `_chart-row-pa.html.erb`/`_chart-coverage-growth.html.erb`, both fully
  developer-controlled, no CMS content) — fixed by giving that `h2` its own class directly instead
  of a descendant selector.

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

| Wave | Scope | Depends on | Touches | Status (re-audited 2026-08-10) |
|---|---|---|---|---|
| **T0** | Delete confirmed-dead SCSS; fix stale doc refs; codify `vw-` (rule 4b) | — | docs only + 8 files deleted | ✅ done |
| **T1** | Shared Tailwind foundation — port mixins/functions to `@theme`/`@utility`, split `shared.css` | T0 | `styles/shared.css` → `styles/shared/*.css`, `tailwind.css` `@theme` | ✅ done (+ 7 more shared files added post-hoc, see T1 addendum) |
| **T2** | Views-only global chrome (nav/footer/hero/cta/content-banner/custom) | T1 | ERB only, 0 Vue | **✅ done** |
| **T3** | Views-only page shells + static card grids + form + CMS wysiwyg | T1 | ERB only, 0 Vue | **✅ done** (only `helpers/_cms.scss` deletion + `_helpers.scss` cleanup + a live-browser check left) |
| **T4** | Vue-only leaves with no existing coupling (NavBar, Listing, Pagination, Search/SearchAreas non-exception, Download, form checkboxes) | T1 | Vue templates + new `ct-` styles | **✅ done** |
| **T5** | Maps (`Map/*` — 8 sub-islands, `_map.scss` views wrapper) | T1, T4 | Vue only (the ERB-wrapper part of the original scope turned out to already be done, see below) | **✅ done** |
| **T6** | Charts + Stats (closes Wave-8 rule-4 exceptions) | T1 | Vue only | 11/~13 components done — `TotalCoverageChart`, `AmChart/{Pie,Multiline}`, `Chart/RowStacked`, `Stats/{Designations,IucnCategories,Governance,Sites,Sources,Message}`, `Attributes/*`, `RegionCountryPages/Index` (wrapper); only `Stats/{Coverage,TooltipInfo}` + the `card--stats-overview` ERB card remain |
| **T7** | Cards family + Listing cards + Carousel (closes `ListingPageCard` exception) | T1, T4 | Vue + a few ERB card grids | **✅ done** (2026-08-13) — everything including `Dropdown/ParcelsDropdown.vue` (the last item) migrated |
| **T8** | PAME + Dropdown + Select (closes Wave-9/10 rule-4 exceptions) | T1 | Vue only | **✅ done** (2026-08-13) |
| **T9** | Residual tabs/filters coupling (`_tabs.scss`, `_filters-sidebar.scss`) | T4, T5, T7 | Vue only | **✅ done** (2026-08-14 — confirmed already closed by undocumented commits) |
| **T10** | Finish — enable preflight, delete legacy pipeline, handle `pdf.scss` | T0–T9 | site-wide | **almost done** (2026-08-14) — legacy SCSS tree + bourbon/neat deleted; only preflight-enable + full sweep left |

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

- [x] Split `app/frontend/styles/shared.css` into `app/frontend/styles/shared/{base,icons,typography,
      shadows,forms,images,scrollbar}.css` (one `@utility tw-shared-<name>` group per concern), per
      rule 5. **`buttons.css` was NOT created** — nothing in this wave's own scope needed
      `tw-shared-button-*` yet (base/_buttons.scss's mixins have real consumers, but none of them are
      migrated this wave), so per "don't pre-create empty buckets" it's deferred to whichever wave
      first migrates a button-heavy component. **`images.css` and `scrollbar.css` were added beyond
      the originally-named 6 buckets** — `image-placeholder` and the webkit-scrollbar mixin are their
      own concerns that don't fit `base`/`icons`/`typography`/`shadows`/`forms`; both have real
      consumers (3 and 2 respectively), so this isn't an empty-bucket violation, just a bucket-list
      correction — logged here per cross-cutting rule 5.
- [x] ~~Ported `utilities/_media-queries.scss`'s breakpoint *values* to `@theme` as new, distinctly-named
      breakpoints (`--breakpoint-small/medium/large/xlarge`) rather than overriding `sm:`/`md:`/`lg:`/`xl:`.~~
      **REVERTED (2026-08-03, see CHANGELOG's T3-correction entry and CODE-CONVENTIONS.md rule 21).**
      The custom tokens duplicated Tailwind's own `md:`/`lg:` almost exactly and, worse, collided with
      them — legacy `$small` (768px) is numerically identical to Tailwind's native `md:` (768px), so any
      call site mixing the custom `small:` token with a native `md:` utility (several did, meaning to
      express "the tier after small") silently collapsed both to one breakpoint. Current, correct
      mapping — legacy `$small`(768px)→`md:` (exact), `$medium`(1025px)→`lg:` (1024px, ~1px off,
      immaterial), `$large`/`$xlarge`(1201px/1441px, rare)→`2xl:` (1536px, collapsing the two rather
      than adding an `xl:` step). Actual component call sites (`@include breakpoint($small)` → `md:`)
      get migrated per-file in T2+, not here.
- [x] Confirmed `utilities/_flexbox.scss`'s mixins map 1:1 to Tailwind's native `flex`/`flex-row`/
      `flex-wrap`/`justify-*`/`items-*` utilities — no shared utility created, per-file call-site
      migration happens in T2+.
- [x] Confirmed `utilities/_rem-calc.scss` matches Tailwind's rem-based spacing scale exactly — Foundation's
      `$global-font-size: 100%` (=16px) is never overridden in `_settings.scss`, so `rem-calc(N)` and
      Tailwind's `N/16` rem arbitrary-value math agree with no drift. No `@theme` spacing changes needed.
- [x] Ported `helpers/mixins/_text.scss` → `shared/typography.css` (`tw-shared-text-*`/`tw-shared-h*`).
      `helpers/mixins/_icons.scss` → `shared/icons.css` (`tw-shared-icon-*`), backed by 36 SVGs duplicated
      into new `app/frontend/assets/icons/` (Vite-processed/fingerprinted; legacy copies under
      `app/assets/images/icons/` untouched until T10).
      `helpers/_border-and-shadows.scss` → `shared/shadows.css` (`tw-shared-shadow-*`/`tw-shared-border-*`;
      `border-radius-top`/`-bottom` skipped — native `rounded-t`/`rounded-b` cover them 1:1).
      `helpers/_form-fields.scss` → `shared/forms.css` (`tw-shared-input-*`; `input-hidden`/
      `input-custom-focus` skipped — native `sr-only`/`outline-none` cover them 1:1). Width/height stay
      the consuming component's own `w-*`/`h-*` rather than baked in, since the legacy mixins took a
      `$width` arg per call site.
      `helpers/_images.scss` → `shared/images.css` (`tw-shared-image-placeholder`).
      `helpers/_beautify-scrollbar.scss` → `shared/scrollbar.css` (`tw-shared-scrollbar`).
- [x] **Post-wave correction (2026-08-03): added CODE-CONVENTIONS.md rule 5b** after discovering this
      wave had missed an already-established precedent — `app/frontend/components/Icon/{Search,Close,
      Arrow,Pin,ExclamationCircle}.vue` already exist (used by `Search/SiteInput.vue`,
      `Carousel/Themes/Ribbon.vue`, `Stats/TooltipInfo.vue`) and render icons as inline
      `<svg fill="currentColor">` Vue components sized/colored by the *consumer's* own scoped
      `@apply`, not as `tw-shared-icon-*` CSS background-image classes. Rule 5b now codifies: a
      Vue-rendered icon is always an `Icon/*.vue` component; `shared/icons.css`'s `tw-shared-icon-*`
      utilities are for ERB view chrome (rule 4b) only. Three follow-on fixes to this wave's own
      output:
      - `icon-pin($circle, $outline)` (+ `-marine`/`-oecm`/`-terrestrial`/`-light` variants) was
        originally logged above as "not portable to a CSS utility, decide later" — it's already
        solved, by `Icon/Pin.vue`'s existing per-part `@apply fill-*` pattern. T5 (`_v-map-popup.scss`)
        and T7 (`card/_card-theme.scss`) reuse/extend that component rather than inventing a solution.
        `icon-pin-outline`/`icon-pin-map` stay in `shared/icons.css` as before (plain background-image,
        valid *if* an ERB view — not a Vue component — turns out to need them).
      - `forms.css`'s `tw-shared-input-custom-checkbox-selected` (`@apply tw-shared-icon-tick`) was
        removed — its only real consumers (`Filters/Checkboxes/Item`, `SearchAreas/{RadioButtons,
        CheckboxSearch,FilterGroup}`) are Vue/T4. T4 adds `Icon/Tick.vue` and renders it in the
        checkbox's own `:checked` markup instead.
      - `images.css`'s `tw-shared-image-placeholder` dropped its `::after` icon overlay — its real
        consumers (`Search/Results/Item`, `SearchAreas/Results/Item`, via `_cards.scss`) are Vue/T7.
        The utility now provides only the non-icon shell (flex-center, grey background, sizing); T7
        renders its own placeholder icon component inside it.
      `shared/icons.css` itself keeps its full ~30-icon set for now (pruning which ones truly have an
      ERB consumer vs. only a Vue one that should use `Icon/*.vue` instead is deferred to T2/T3/T4,
      per the same mark-and-sweep discipline as legacy SCSS deletion — see file header comment).
- [x] Extended the `@theme` color tokens: `--color-theme-grey-xdark`, `--color-theme-green-dark`,
      `--color-theme-chart-purple`, `--color-theme-chart-green` — audited against actual usage across
      T2/T3's file scope (`$white`/`$black` also appear there but need no token, Tailwind ships
      `white`/`black` natively already).
- [x] `yarn typecheck` / `yarn lint` / `yarn vite:build` / `yarn test` (Vitest) all clean in the
      `protectedplanet-web` container — one bug caught by the build itself: a doc comment in
      `shadows.css` containing a literal `*/` (inside "rounded-t-*/rounded-b-*") closed its CSS comment
      early, flagged by Vite's CSS optimizer as "Unexpected token Delim('*')"; fixed by rewording. The
      pre-existing `SearchSiteInput.spec.ts` lint error (1) and 4 Vitest failures are unrelated to this
      wave — reproduced identically on a stash of this wave's changes (i.e. present on `master`/this
      branch beforehand). No visual change from this wave (pure infrastructure, nothing consumes the new
      utilities yet) — spot-check deferred to T2, the first wave that actually applies them.
- [x] **Post-hoc addition (found during 2026-08-10 re-audit, not logged at the time):** 7 more
      `shared/*.css` files were created between T2 and T3 that this checklist never listed —
      `container.css` (the `tw-shared-base-container*` family, actually landed here instead of staying
      in `base.css` as T3's narrative describes), `flex.css` (the widest-reused shared file of all, 38
      consumers — the `gap-*` spacing primitives Decision above calls for), `buttons.css` (ported
      `base/_buttons.scss`'s mixins, ~16 consumers), `hero.css`, `map.css`, `themes.css` (chart-legend
      colour swatches, Rails-rendered), and `cms.css` (`tw-shared-cms-wysiwyg`, replacing
      `helpers/_cms.scss`'s `.cms-wysiwyg` — see T3 below, that legacy file is now fully orphaned).
      All are wired into `tailwind.css` and have real consumers except two: **`forms.css`**
      (`tw-shared-input-custom-{radio,radio-selected,checkbox}`) and **`scrollbar.css`**
      (`tw-shared-scrollbar`) are imported but currently have **zero live consumers anywhere** — they
      were pre-built for T4/T8 components (checkboxes, PAME table horizontal-scroll) that haven't
      landed yet. Not a bug, just noting so a future "unused CSS" sweep doesn't flag them as dead.

---

## Wave T2 — Global chrome, views-only (~1 wk) — **DONE**

**Goal:** the site-wide chrome every page shares, zero Vue coupling, lowest risk.

Files: `base/_base.scss` (`.site-width`/`.container`), `_nav.scss`'s ERB-owned parts (`_topbar.html.erb`
— `NavBar/Index.vue`'s own legacy-class usage is T4, not here), `_footer.scss`, `components/hero/*`
(5 files, 100% views-only), `_cta.scss` (100% views-only), `_content-banner.scss` +
`content-banner/_content-banner-basic.scss`, `custom.scss` (home page stat blocks),
`helpers/_background.scss` (`.bg--*`, 8 consumers, all views), `_social.scss` (moved here from the
T0 baseline's mistaken "dead" list — real consumers: `_footer.html.erb`, `_head.html.erb`,
`_topbar-secondary.html.erb`, `_social-share.html.erb`, `_social-follow.html.erb`, plus two Comfy CMS
partials, all views-only).

- [x] Rewrite each `.erb` partial's markup to `vw-`-prefixed classes (rule 4b), backed by
      `app/frontend/styles/views/<name>.css` per file/section (e.g. `views/hero.css`, `views/footer.css`).
      `custom.scss` had zero live consumers anywhere (not even compiled into `application.css`) —
      deleted outright instead. `_nav.scss` couldn't be fully rewritten-and-deleted — only
      `.nav--primary`'s own 2 declarations are ERB-owned; the file stays alive for T4. Full detail,
      including a cascade-layer bug found via real-browser check (5 classes needed to be plain CSS,
      not `@utility`, to correctly override retained bare `h1`/`h2`/`a` element rules): see
      [CHANGELOG](./CHANGELOG.md#wave-t2--global-chrome-views-only-done).
- [x] Delete the corresponding legacy SCSS file once its last ERB consumer is switched (confirm via
      grep, same discipline as the Wave 12 Vue dead-code sweep). `helpers/_background.scss` kept its
      mixins alive (still `@include`d by T4/T7 files) — only the classes section was removed.
- [x] Live-verify: home, a hero-bearing thematic page, footer on any page, a CTA-bearing static page,
      effectiveness green-list tab (content-banner). Screenshot before/after (desktop + mobile), not
      just curl — this is a pure-visual wave. `chromium-cli` wasn't available in this environment;
      used `playwright-core` directly instead (chromium already cached locally).

---

## Wave T3 — Page shells & static card grids, views-only (~1 wk) — **DONE** (re-confirmed 2026-08-10)

Files (as originally scoped — several names below never matched real files, see the re-audit note
at the end of this wave): `pages/_country.scss` (**deleted**), `_error-page.scss`, `_news.scss`,
`_region.scss`, `_resource.scss`, `_site.scss` (all `.page--*`, 0 Vue), `cards/_cards-circles.scss`,
`_cards-facts.scss`, `_cards-scrollable.scss`, `_cards-squares.scss`, `_cards-message.scss` (static
content-page card grids, not the Vue-rendered card families — those are T7), `components/_form.scss`
+ `form/*` overlap-check (confirm `_checkbox`/`_input`/`_radio` really are Vue-only per baseline
before assuming 0 views work here), `helpers/_cms.scss` (`.cms-wysiwyg` CMS rich-text wrapper).

- [x] **Shared foundation correction (2026-08-03, done ahead of the rest of this wave):** moved
      `views/base.css` + `views/background.css` wholesale into `shared/base.css`/
      `shared/background.css` as `tw-shared-base-*`/`tw-shared-bg--*` (see the two Decisions
      corrections above), repointed all ~40 consumers (`hero.css`/`cta.css`/`footer.css`/
      `content-banner.css` plus every ERB page template that had them). Added
      `tw-shared-region-country-site__overview` to `shared/base.css` for the `flex-stack-mobile` mixin shared
      by country/region/site's identical `.page__section--overview-map` rule (country is its first
      consumer; region/site pick it up when their own rows below land).
- [x] **`country/show.html.erb` done** — one class per element per the retracted-exception
      Decision above: `page--country vw-bg--grey-xlight vw-base-spacer-small--top` → `vw-country`,
      `vw-base-container` → `vw-country__container`, `page__section--overview-map` →
      `vw-country__overview` (`@apply tw-shared-region-country-site__overview`), all in new
      `views/country.css`. `pages/_country.scss` deleted (its only rule is now the
      `tw-shared-region-country-site__overview` application above); `pdf.scss`'s `.page--country` selector
      repointed to `.vw-country` so the PDF-export transparent-background override keeps matching.
- [x] **Second pass (2026-08-03): every remaining `tw-shared-*` class exposed directly in ERB
      markup wrapped in its own `vw-*` class.** The first pass above only fully applied the
      retracted-exception fix to `country/show.html.erb` — every other one of the ~40 consumers got
      a purely mechanical prefix rename, leaving `tw-shared-*` classes (often still stacked 2-3
      deep) directly in `class="..."` attributes across the rest of the site. Fixed exhaustively —
      `grep -rn "tw-shared-" --include="*.erb" app/views/` now returns zero matches. New/extended
      `views/*.css` files, one per page or reused block (see file header comments for the exact
      class-per-element mapping):
      - `region.css` — `region/show.html.erb` fully retired like country (`.page--region`'s only
        real rule was the same `flex-stack-mobile` on `.page__section--overview-map`, now
        `vw-region__overview`); `pages/_region.scss` deleted (`.page__2cols` was already dead,
        confirmed via grep), `pdf.scss`'s `.page--region` repointed to `.vw-region`.
      - `site.css` — `protected_areas/show.html.erb`'s `tw-shared-*` usages wrapped in `vw-protected-areas*`
        classes, but `.page--site` itself **stays** in the ERB (unlike country/region) since
        `_site.scss`'s `.page__col-wrapper`/`__col-1`/`__col-2` have real PDF-width-conditional
        content this wave doesn't touch — only the now-independent `.page__section--overview-map`
        rule was deleted from `_site.scss` and replaced by `vw-protected-areas__overview`.
      - `home.css`, `search.css`, `search-areas-home.css` (the `SearchAreasHome` widget wrapper,
        reused by `home/index.html.erb` and `data/wdpca/_tab_extras.html.erb`), `error-page.css`
        (identical `layouts/404.html.erb`/`500.html.erb` markup shares one file),
        `cms-layouts.css` (all `layouts/cms/_*.html.erb` page-type templates — each CMS layout
        template counts as one "view" even though many CMS-authored pages instantiate it, same as
        a Vue component template being reused by many instances still getting one `ct-` class),
        `thematic-pages.css` (marine/effectiveness/gdpame/wdpca + the `thematic_and_data_area`
        shared footer/panel partials), `chart-row.css` (the chart-row wrapper block reused by
        `_chart-row-pa.html.erb`/`_chart-coverage-growth.html.erb`), `static-cards.css`
        (`cards/_themes.html.erb`/`_circles.html.erb` — their own `cards--themes`/`cards--circles`
        legacy classes are untouched, T7 scope; only the `tw-shared-*` sibling was wrapped).
      - Extended existing `cta.css` (`vw-partials-ctas-api__container--live-report`, `vw-partials-ctas-api__intro`,
        `vw-partials-ctas-api__title--white` for the `_api`/`_mpa-guide` partials that were still using bare
        `tw-shared-base-h2-big-white`/`tw-shared-base-text-intro`) and `hero.css`
        (`vw-hero__title--home`, moved in from `shared/base.css`'s `tw-shared-base-h1-home` — that
        class only ever had one consumer, so it never actually met the `tw-shared-`'s own ">1 view"
        bar for living in `shared/` to begin with) and `content-banner.css`
        (`vw-layouts-partials-hero-green-list__container--full`, replacing a literal `' tw-shared-base-container'`
        string that `_content-banner.html.erb` interpolated straight into its `class="..."`
        attribute for non-`contained:` callers).
      - **Also fixed a descendant-selector violation of the *other* new rule** (prefer a real
        utility applied directly to the element, only fall back to a bare-tag descendant selector
        for CMS-uncontrolled rich text): `shared/base.css` had
        `.tw-shared-base-container--component h2 { margin-top: 0; }` reaching into a fully
        developer-authored `<h2><%= title %></h2>` (in the two chart-row partials, no CMS content
        involved) from the parent. Replaced with `vw-partials-charts-chart-row-pa__title` applied directly to the
        `h2`.
      - Two pre-existing, *unrelated* dead-code call sites found while doing this (not fixed, only
        renamed for source hygiene, logged so they aren't mistaken for new bugs): `effectiveness/
        index.html.erb` and `gdpame/index.html.erb` both pass a `classes: "...tw-shared-bg-image-
        overlay--white"` local into `hero-basic` via `thematic_and_data_area_hero_locals(...).merge(...)` —
        but that helper always also sets `image:`, and `hero-basic.html.erb`'s `if local_assigns.has_key?
        :image` branch never calls `get_local_classes`, so this local has silently never rendered
        onto the header. Renamed to `vw-effectiveness__hero-overlay`/`vw-gdpame__hero-overlay` as
        source hygiene only — fixing the actual dead branch is a separate, unrelated task.
      - Full re-verification: `yarn vite:build`/`yarn typecheck` clean, every new class confirmed
        present in the compiled CSS (`grep` against `layout-*.css`), and live-checked in a real
        browser — home, country, region, and a protected-area page all render their new classes
        with the expected computed styles (background colour, container max-width/padding,
        flex/flex-wrap behaviour). CMS/thematic page routes couldn't be reached in this dev
        environment's seed data (`/marine`, `/search`, `/data/gdpame` etc. 404 through to
        `ProtectedAreasController`/Comfy's catch-all — a routing/seed-data gap, confirmed
        unrelated to this change via the server log) — re-verify those visually once real content
        is available.
- [x] **`_error-page.scss`, `_news.scss`, `_resource.scss` — done.** All three legacy files are
      deleted (`git log --diff-filter=D` shows `b1fa85e73 feat: migrate error page`,
      `69abff942 feat: migrate news-and-stories`, `a4103c0b9 feat: migrate resource`). Backed by
      `views/layouts/error-page.css`, `views/layouts/cms/news-and-stories{,-article}.css`,
      `views/layouts/cms/resource{,s}.css`.
- [x] **Static card grids — done, under different filenames than originally guessed.** The legacy
      filenames listed above (`cards/_cards-circles.scss` etc.) never actually existed on disk — the
      real partials are `app/views/partials/cards/_{circles,facts,squares,news,resources,sites}.html.erb`
      and `_themes.html.erb`, all now rewritten to `vw-partials-cards-*`/`vw-cards-*` classes backed by
      `views/partials/cards/{circles,facts,squares,news,resources,sites,themes/{index,card}}.css`. No
      "scrollable" or "message" card-grid partial was ever found — likely dead scope from the start,
      not something this wave skipped.
- [x] **`_site.scss`'s `.page__col-wrapper`/`__col-1`/`__col-2` — done**, contrary to this item's
      original "deliberately left alone" note. Ported into `views/site.css` as
      `vw-protected-areas__col-wrapper`/`__col-1`/`__col-2` (the `.pdf .vw-protected-areas__col-1/2` PDF-width override kept
      as an unlayered plain selector, same treatment as other PDF-conditional rules elsewhere in this
      doc); `pages/_site.scss` fully deleted.
- [x] **All 9 CMS layout templates + all 4 thematic/data-area page shells (marine, effectiveness,
      gdpame, wdpca) + all 5 hero variants — done.** These were flagged as "couldn't be reached in
      this dev environment's seed data" in the second-pass note above; re-verified 2026-08-10 that
      every one of `views/layouts/cms/{about,basic,data-areas,news-and-stories(-article),resource(s),
      thematic-and-data-area-default,thematic-areas}.css`, `views/thematic/{marine,effectiveness/
      {index,green-list-tab}}.css`, `views/data/{gdpame,wdpca}/{index,tab-content|tab-extras}.css`,
      and `views/layouts/partials/hero/{basic,green-list,home,marine,small}.css` exist, define real
      `vw-*` classes, and are consumed by their exact owning `.erb` file (confirmed via static
      grep-cross-reference, not a live route hit — the seed-data gap noted above may still apply for
      an actual browser check). **Naming inconsistency found while confirming this:** the CMS layout
      files use three different `vw-` prefix schemes (`vw-layouts-cms-*` as plain classes,
      `@utility vw-cms-*`, and a mixed `.vw-cms-*` plain-class form) — this doesn't match rule 4c's
      path-mirroring convention (added 2026-08-05, after these files shipped) consistently. Works
      today; a follow-up consistency pass would normalize all of them to `vw-layouts-cms-*` per rule
      4c's own worked example. Not blocking, just logged so it isn't mistaken for a bug later.
- [x] **`components/_form.scss` + `form/*` overlap check — resolved, confirms Vue-only.** Re-verified
      2026-08-10: `_checkbox.scss`/`_radio.scss`/`_input.scss` are consumed exclusively by
      `Filters/Checkboxes/Item.vue` and `SearchAreas/RadioButtons.vue` (both still 100% legacy,
      zero `<style>` blocks) — zero ERB consumers. This was already correctly listed under **T4**'s
      scope; nothing to do here in T3, the "overlap check" this item asked for is done and confirms
      no T3 work is needed.
- [x] **`helpers/_cms.scss` — now dead, not migrated in place.** `.cms-wysiwyg` has zero remaining
      ERB consumers (`grep -rn cms-wysiwyg app/views` returns nothing) — every real consumer now uses
      the new `tw-shared-cms-wysiwyg` utility in `shared/cms.css` instead. The legacy file itself
      (27 lines) is still sitting on disk and still `@import`ed via `helpers/_helpers.scss` →
      `application.scss`, so it's pure dead weight now, not "unresolved migration work." **Delete it**
      — this is the one concrete file-deletion action left in T3.
- [ ] `_helpers.scss`'s remaining utility classes not already deleted in T0 (`.block`, `.red`, `.bold`,
      etc.) — replace call sites with native Tailwind equivalents (`block`, `text-red-500`, `font-bold`)
      directly in the ERB, then delete the file. **Still genuinely open** — re-checked 2026-08-10,
      file (and its `@import`s of `_cms.scss`/`_background.scss`/etc.) still present, not reverified
      further this pass.
- [ ] Live-verify in a real browser (still open — this pass was static/grep-based, not a live-route
      check): a resource page, error page (404/500), one CMS static page with a facts/circles/
      squares card grid, and marine/effectiveness/gdpame/wdpca now that the ERB side is confirmed
      done. **Also re-check topbar and any Tabs/Banner-bearing page at tablet widths (768-1024px)** —
      the base-container breakpoint correction above changes their container padding step point.

---

## Wave T4 — Vue leaves with no existing styling (~1.5–2 wk, largest single wave) — **done** (started 2026-08-10, closed 2026-08-11)

**Goal:** close the ~85-component gap for the lowest-coupling islands first, mirroring the original
Vue-migration principle (leaf/zero-coupling before global chrome/state).

**Correction to this wave's own earlier framing (same day):** `Listing/FiltersPanel.vue`/
`FilterGroup.vue` were initially deferred to T9 on the reasoning that they share `_filters-sidebar.scss`
with unmigrated `SearchAreas/FilterGroup.vue`/`FiltersPanel.vue`. **Retracted after user feedback** —
sharing a legacy SCSS file doesn't mean sharing a component; `SearchAreas`'s panel/group are their own
independent `.vue` files with zero markup overlap, so `Listing`'s side could (and should) migrate on
its own schedule, leaving `_filters-sidebar.scss` itself alone until `SearchAreas`'s turn comes. Also
migrated as a real `{Desktop,Mobile}.vue` component split per direct user request, not just responsive
CSS on one component — see below.

Components (confirmed zero `<style>` block, legacy-class-dependent): ~~`NavBar/*`~~ (**done**,
see below), ~~`Listing/{Index,List}.vue` + `Filters/Trigger.vue` + `Listing/FiltersPanel.vue` +
`Listing/FilterGroup.vue`~~ (**done**, see below), ~~`Filters/Checkboxes/{Index,Item}.vue`~~ (**done**,
landed in the same commit as the `Listing`/`Trigger`/`FilterGroup` slice, `form/_checkbox.scss`
deleted), ~~`Pame/Table/Pagination`/`Search/Pagination` (`_pagination.scss`)~~ (**done**, see below;
`PaginationInfinityScroll.vue` needed nothing beyond its earlier dead-CSS class rename), ~~`SearchAreas/
InputAutocomplete.vue`~~ (**done** — landed 2026-08-07 in `511c2f5eb`, mis-tracked as open until the
2026-08-11 re-audit), ~~`SearchAreas/TabStrip/{Index,Tab}.vue` (`_tabs.scss`)~~ (**done**, see below —
closes the file entirely, including its `--hero`/`--underlined` sub-scope which turned out to have
zero live consumers left, ported or not), ~~`Search/Index.vue`~~ (**done**, see below — its
`search--main`/`search__spinner` classes both turned out to have zero real CSS behind them already;
`SiteInput`/`TabStrip`/`Pagination` children were already migrated in earlier slices, `Results/Index`
stays T7), ~~`SearchAreas/{RadioButtons,CheckboxSearch,FilterGroup,FiltersPanel}`~~ (**done**, see
below — closes `form/_radio.scss` and `components/filters/_filters-sidebar.scss` entirely, plus
`form/_input.scss`'s `.input--search` class), `SearchAreas/Page.vue`'s own root/container classes
(`search--results-areas`, `search__bar`, `search__bar-content`, `search__main`, `search__results`,
`search__spinner` — backed by the remainder of `_search-results-areas.scss`; `&__filter-trigger`
already closed out alongside `Filters/Trigger.vue` — this is the one piece of `SearchAreas/*` still
genuinely open, distinct from `SearchAreas/Results/Item.vue`'s own card markup which is T7 scope),
`Search/Results/Item.vue`/`SearchAreas/Results/Item.vue` (T7, `_search-results.scss`/
`_search-results-areas.scss`'s card rules — not touched by the above),
~~`Download/{Index,Modal,Commercial,Popup,Item}.vue`~~ (**done**, see below).

- [x] **`NavBar/{Index,Link,Dropdown}.vue` done, `components/_nav.scss` deleted.** New
      `ct-nav-bar*`-prefixed styles, new `Icon/Burger.vue`, reused existing `Icon/Close.vue`/
      `Icon/Arrow.vue` per rule 5b. `_topbar.html.erb`'s now-dead `nav--primary` mount class
      dropped. Full detail, including two dead-code findings (an unstyled `<span>` and a
      cascade-shadowed utility-class stack) and the Vue-attrs-fallthrough class-merging note for
      future sub-component work in this wave: see
      [CHANGELOG](./CHANGELOG.md#wave-t4--vue-leaves-with-no-existing-styling-started-navbar-slice-done).
- [x] **`Listing/{Index,List}.vue` + shared `Filters/Trigger.vue` done, `components/_listing.scss`
      deleted** (plus the now-dead `button-filter-trigger`/`icon-filters` mixins and the dormant
      `tw-shared-icon-filters` utility). New `Icon/Filters.vue` + `Icon/LoadingSpinner.vue` per rule
      5b. Closed a real behavioural gap in passing — `Trigger.vue`'s disabled state is now one real,
      working `ct-filters-trigger--disabled` shared by both its consumers (`Listing/Index.vue` never
      had working disabled styling before; `SearchAreas/Page.vue` did) — plus two independent
      pre-existing dead-CSS bugs (the `icon-visible` spinner-toggle class and a `search__results-none`
      selector that only worked nested under a `.search--results-areas` ancestor `Listing` never has).
      Full detail: see
      [CHANGELOG](./CHANGELOG.md#wave-t4--vue-leaves-with-no-existing-styling-started-navbar-slice--listing-slice-done).
- [x] **`Listing/FiltersPanel.vue` + `Listing/FilterGroup.vue` done** (same-day follow-up, user
      feedback-driven). New `Listing/FiltersPanel/{Desktop,Mobile}.vue`, mirroring the
      `NavBar/{Desktop,Mobile}.vue` split precedent but `v-if`/`v-else`-gated via `useBreakpoint()`
      (single DOM tree mounted at a time) rather than CSS `hidden`/`flex` toggling — a deliberate
      departure since the two variants differ structurally, not just visually (full-screen drawer
      with topbar+close-footer vs. a plain static sidebar column). `FiltersPanel.vue` itself is now a
      thin switcher. Cutoff is 1024px (`isLarge || isXLarge`), narrower than the legacy SCSS's 768px —
      a deliberate simplification, not a straight port; tablet widths now get the mobile drawer too.
      `FilterGroup.vue` migrated once, shared by both variants (no breakpoint distinction in its own
      legacy CSS). `_filters-sidebar.scss` is **not** touched/deleted — still has real
      `SearchAreas/{FilterGroup,FiltersPanel}.vue` consumers, its own separate unmigrated files. Full
      detail: see
      [CHANGELOG](./CHANGELOG.md#wave-t4--vue-leaves-with-no-existing-styling-started-navbar-slice--listing-slice--filterspanel-slice-done).
- [x] **`Pame/Table/Pagination.vue` + `Search/Pagination.vue` done, `components/_pagination.scss`
      deleted** (2026-08-11), plus its now-dead `button-next`/`button-prev`, `icon-circle-chevron-
      {green,grey}-{left,right}`, and `text-pagination`/`text-pagination-no-results` mixins. Both
      buttons' circle-chevron icon reuses the existing `Icon/CircleChevron.vue`, extended with
      `direction`/`circleColor` props rather than duplicated. Found and fixed a latent bug shared by
      every `Icon/*.vue` component (icon root is `display: inline`, so a sizing utility on it is a
      silent no-op unless the consumer happens to be a flex item) — fixed locally via `inline-flex` on
      the pagination buttons; flagged for a wider sweep. Could not live-verify `Pame/Table/Pagination.vue`
      (its only mount route, `/data/gdpame`, 500s on a pre-existing dev seed-data gap) — verified via
      Vitest instead. Full detail: see
      [CHANGELOG](./CHANGELOG.md#wave-t4--vue-leaves-with-no-existing-styling-started-navbar-slice--listing-slice--filterspanel-slice-done).
- [x] **`Download/{Index,Modal,Commercial,Popup,Item}.vue` done** (2026-08-11), closing
      `components/_download.scss`, `components/modal/_modal-download.scss`,
      `components/modal/_modal-download-commercial.scss`, and `components/_popup.scss` (all 4
      deleted) plus their now-dead `button-download*`/`icon-warning` mixins. New `Icon/{CircleClose,
      Minus,Warning}.vue`; the two legacy fallthrough-class size variants (`download--search`/
      `download--small`) collapsed into one new `compact` prop on `DownloadProps`, since the only
      real difference between them was a single mobile-breakpoint square-size override. `.download__
      target`'s toggle wrapper `<div>` was dropped outright in favour of a plain `v-if`. Full detail:
      see [CHANGELOG](./CHANGELOG.md#wave-t4--vue-leaves-with-no-existing-styling-started-navbar-slice--listing-slice--filterspanel-slice-done).
- [x] **`SearchAreas/TabStrip/{Index,Tab}.vue` done, `components/_tabs.scss` deleted entirely**
      (2026-08-11), plus its now-dead `button-tab-rounded` mixin (`base/_buttons.scss`). The 4 legacy
      fallthrough-class variants (`tabs--search-main`/`--search-areas`/`--rounded`/`--rounded-small`)
      were first ported 1:1 via a `variant` prop, then simplified same-day to one universal style for
      every consumer (`Tab.vue` always `size="default"`, no `variant` prop at all) — **current state
      has no variant system**; see CHANGELOG for the full before/after. Also found and dropped, not
      ported: the `--hero`/`--underlined` sub-scope (their own mixins, `tab-trigger-underlined`/
      `tabs-horizontal-scroll`'s standalone use) had zero live consumers anywhere (grepped) — neither
      variant is used by `TabStrip` OR anything else; only `Tabs.vue`'s own already-fully-migrated
      `ct-tabs__triggers` remained, an unrelated class. Full detail: see
      [CHANGELOG](./CHANGELOG.md#wave-t4--vue-leaves-with-no-existing-styling-started-navbar-slice--listing-slice--filterspanel-slice-done).
- [x] **`Search/Index.vue` done** (2026-08-11) — its root `search--main` and the spinner's
      `icon--loading-spinner`/`icon-visible`/`search__spinner` classes turned out to have **zero
      real CSS anywhere** already (a scope-mismatch + genuinely-undefined-class combo, not a fresh
      finding to delete — nothing to delete, just to stop using). New `ct-search-site` root +
      `ct-search-site__spinner`/`--visible`, reusing `Icon/LoadingSpinner.vue` (same `size-10
      mx-auto my-13.75` sizing precedent as `Listing/Index.vue`'s identical spinner, itself the
      Tailwind port of the same `search-spinner` mixin's 55px value). Full detail: see
      [CHANGELOG](./CHANGELOG.md#wave-t4--vue-leaves-with-no-existing-styling-started-navbar-slice--listing-slice--filterspanel-slice-done).
- [x] **`SearchAreas/{RadioButtons,CheckboxSearch,FilterGroup,FiltersPanel}` done** (2026-08-11),
      closing `components/form/_radio.scss` and `components/filters/_filters-sidebar.scss` entirely
      (both deleted), plus `form/_input.scss`'s now-dead `.input--search` class and 5 mixins that
      turned out to have zero remaining consumers once these two files were gone
      (`input-hidden`/`input-custom-radio`/`input-custom-radio-selected`/`button-clear`/`text-filter`,
      the last of these shared with `_filters-sidebar.scss`) — plus 2 more (`input-custom-checkbox`/
      `input-custom-checkbox-selected`) found already-orphaned from an earlier wave's `_checkbox.scss`
      deletion and swept in the same pass. `SearchAreas/FiltersPanel.vue` (flat file) split into
      `FiltersPanel/{Index,Desktop,Mobile}.vue`, mirroring the `Listing/FiltersPanel` precedent — the
      aggregation logic that combines each `FilterGroup`'s `update:filter` into one
      `Record<string, unknown>` for `SearchAreas/Page.vue` moved from the old monolithic component
      into the new `Index.vue` switcher, since `Listing`'s simpler forward-only version didn't need
      to carry that logic itself. Full detail: see
      [CHANGELOG](./CHANGELOG.md#wave-t4--vue-leaves-with-no-existing-styling-started-navbar-slice--listing-slice--filterspanel-slice-done).
- [x] **`SearchAreas/Page.vue`'s own root/container classes done, 2026-08-11 — this was T4's last
      open item.** New `ct-search-areas-page` root/`__bar`/`__main`/`__filters`/`__results`/
      `__spinner`, closing out `_search-results-areas.scss` down to just the 3 rules
      (`&__results`/`&__results-none`/`&__results-bar`) that still back `SearchAreas/Results/Index.vue`
      (T7 scope — its card-rendering children stay separate, not conflated with this page-shell work).
      Also swept 2 now-dead classes (`search__bar`, orphaned by an earlier concurrent flattening of
      the ERB-adjacent wrapper `<div>`) and 2 always-dead ones (`search__map`/`search__map-container`,
      this page never rendered a map) plus the now-unused `search-spinner` mixin and 3 pre-existing
      dead `$search-input-size-*` variables. **Every named T4 component is now done** — remaining
      cross-cutting items below are legacy notes from when this wave still had open components; see
      the CHANGELOG entry for the audit method used to confirm no other silent class-transfer gaps
      remain in `SearchAreas/Page.vue`'s tree.
- [x] Per remaining component: rewrite template classes to `ct-`-prefixed BEM, add `<style scoped>`
      with `@apply` (using T1's shared utilities where applicable), delete the legacy SCSS once its
      last consumer moves. — done for every T4 component; T5/T6/T7/T8/T9 pick up the rest of the app.
- [x] Existing Vitest coverage mostly survived BEM class renames across every T4 slice; updated
      alongside each one. 3 spec failures remain in `SearchAreas/__tests__/Page.spec.ts` as of
      2026-08-11, but they trace to two *other*, still-in-progress restructurings (`TabStrip` moving
      out of `SearchAreas/` to a shared top-level location, `FiltersPanel` gaining a `v-if="isActive"`
      gate on desktop too) — not to any T4 CSS migration itself. Fix when those land, not folded in
      here.
- [x] Live-verified across the wave: nav burger + search topbar, a listing page (news/resources),
      the site search page (`/en/search`), search-areas page with filters/pagination/download
      (`/en/search-areas`), a download modal + the commercial download modal. `RegionCountryPages`'
      `rounded` tab-strip variant and `SearchAreas/RadioButtons.vue` couldn't be reached in this dev
      environment's seed data — verified structurally via their own specs instead.

---

## Wave T5 — Maps (~1 wk) — **done** (2026-08-12)

**Scope correction found before starting** (both confirmed via `git log --diff-filter=D`, well before
this wave's "not started" status was last touched): the `_map-section` ERB partial this section
originally described migrating never needed touching — `partials/maps/_main.html.erb`/`_header.html.erb`
were already deleted 2026-07-24, and all 7 `frontend_mount "Map"` call sites already sit inside an
already-migrated `vw-*__map`/`vw-*__overview` wrapper from T2/T3. The legacy Vue2 map + CDN
`mapbox-gl.js` this section's file comments described as "still loaded" was also already fully deleted
(2026-07-24/2026-08-03) — the `.mapboxgl-*` half of every duplicated selector in `_map.scss`/
`_v-map-popup.scss`/`pdf.scss` was dead weight, not live legacy support.

Files actually migrated: `components/maps/*` (8 files: `_v-map-header`, `_v-map-filters`, `_v-map-filter`,
`_v-map-pa-search`, `_v-map-disclaimer`, `_v-map-toggler`, `_v-map-baselayer-controls`, `_v-map-popup`),
`_map.scss`, plus a 9th file this section's original scope missed — `components/_autocomplete.scss`
(sole remaining consumer `Map/PaSearch.vue`, its T4 sibling `SearchAreas/InputAutocomplete.vue` already
migrated off it). All 9 deleted, along with the now-fully-orphaned `helpers/_accessibility.scss`.

- [x] Same treatment as T4 for all 8 `Map/*` sub-islands (`Header`, `Filters`→`Panel`, `Filter`,
      `PaSearch`, `Disclaimer`, `Toggler`, `BaselayerControls`) plus `Base`/`Index` — rewritten to one
      `ct-map-<name>` BEM block per SFC. The dynamically-set `.v-map-pin` class in `useMapPopups.ts`
      (set via `pin.className = ...` in JS, not a template literal) renamed to the already-existing
      `tw-shared-icon-pin-map` shared utility — a deliberate rule-5b carve-out, since there's no Vue
      render tree at that point to mount an `Icon/*.vue` component into. The composable's hardcoded
      `mapboxgl-popup-content__*` class strings were renamed to `maplibregl-popup-content__*` in the
      same pass (they only ever worked because the legacy SCSS duplicated the rule under both prefixes;
      dropping the dead `.mapboxgl-*` half without this rename would have silently broken every popup).
- [x] ~~`_map.scss`'s views-only wrapper markup → `vw-map-section` classes in `_map-section` ERB
      partials.~~ Turned out to already be done (see scope correction above) — nothing left to migrate
      on the ERB side.
- [x] **Real-browser verification done via Playwright** (`playwright-core`, no `chromium-cli` available):
      home page at 1400px/375px (mobile↔desktop header swap, panel width-at-breakpoint, filter rows,
      a working toggler click, baselayer-control selected state, disclaimer, zoom controls, map tiles),
      the country page's `isHidden: true` disclaimer-only path, `/en/data/wdpca`'s tab-extras mount, and
      the PA-search input's visual appearance while typing. Point-query popups and the PA-search-to-
      zoomTo flow couldn't be exercised live (external ArcGIS-style query services unreachable from this
      dev sandbox) — relied on `Base.spec.ts`'s existing passing Vitest coverage of the popup HTML
      content instead. Full detail: see
      [CHANGELOG](./CHANGELOG.md#wave-t5--maps-map-8-sub-islands--_mapscss--_autocompletescss--done).

---

## Wave T6 — Charts + Stats, closes Wave-8 rule-4 exceptions (~1–1.5 wk) — **done** (2026-08-12)

**Pre-work audit (2026-08-12) found two more doc-drift issues, same recurring pattern as every prior
wave:** (1) `AmChart/Multiline.vue` was already fully migrated (`ct-am-chart-multiline*`) via an
undocumented commit — this doc's "confirmed still 100% untouched" line was wrong for it, real progress
was 2/13 not 1/13 before this session started. (2) **`Stats/Sites.vue` was a live regression, not just
unmigrated** — Wave T7 deleted `cards/cards/_cards-search-results-areas.scss` on the claim of "confirmed
zero other consumers," but `Sites.vue`'s own "other protected areas" card grid (`cards--search-results-
areas preview`, `card__link`/`__image-placeholder`/`__image`/`__content`/`__title`) depended on that
exact file and had been rendering completely unstyled since T7 landed. Fixed as part of this wave (see
below), not filed as a separate bug — it's the same file-family work either way.

Files: `components/_charts.scss` + `charts/*` (6 files, not 7 — the doc's own count included
`_charts.scss` itself), `card/stats/*` (9 files), `components/_lists.scss` (shared by `Attributes/*` and
`Stats/*`). **All deleted by the end of this wave** — `components/charts/` and `card/stats/` are now gone
as directories entirely; `_lists.scss` closed alongside its last real consumer (`Stats/Sources.vue`'s
sibling `Attributes/ProtectedArea/Source/*`).

**Done this wave:**
- [x] **`AmChart/Pie.vue`** — `ct-am-chart-pie*`. Its own `.chart__chart` padding rule turned out to be
      dead (a same-element, not-descendant selector mismatch — `class="am-chart--pie chart__chart"` was
      on one div, so `.am-chart--pie .chart__chart` never matched); not ported. `.chart__svg`'s
      `height: 280px` was real (genuine descendant match) — ported as `h-70` on `__svg`.
      `_am-chart-pie.scss` deleted.
- [x] **`Chart/RowStacked.vue`** — `ct-chart-row-stacked*`. Its only real caller (`Stats/Designations.vue`
      — confirmed via `ChartRowStackedRow`'s own type comment, "TabPresenter#designations' only") never
      actually triggers the legacy `chart-row-stacked` mixin's own two variants directly; it relies on an
      ancestor class (`chart--row-stacked--designation`) the parent passes via attrs fallthrough. The
      component is now fully self-contained instead: no `theme` prop → per-bar colour from a new 12-entry
      palette (`tw-shared-chart-theme-1..12` in `shared/themes.css`, matching `$theme-chart`/`PIE_COLOURS`
      order) with alternating above/below tooltip placement by index (the old `chart-bars`/`chart-legend-
      key` nth-child mixins); `theme` prop given → single colour for every bar via the existing
      `tw-shared-chart-legend-colour-*` classes, tooltip always above (the old `--basic` variant — real
      but untriggered by any caller today, ported as genuinely working code rather than left dead, same
      as T4's `Trigger.vue` disabled-state precedent). The tooltip "speech bubble" reuses
      `TotalCoverageChart.vue`'s already-established caret pattern (`tw-shared-border-radius` +
      `before:border-x-13` triangle) — the legacy mixin's `::before`/`::after` double-caret was redundant
      (both the same colour, so only one triangle is ever visually distinct). `_chart-row-stacked.scss`
      deleted, along with `_charts.scss`'s now-fully-dead `chart-target-line`/`chart-scrollable`/
      `chart-tooltip` mixins and 4 unused `$chart-*` variables (zero remaining `@include` callers once
      `_chart-line.scss` — already dead, see below — and this file were gone).
- [x] **`_chart-line.scss` deleted** — confirmed zero consumers even before this wave (its sole would-be
      trigger, `chart--line`, was already replaced when `AmChart/Multiline.vue` was migrated in an earlier
      undocumented commit).
- [x] **`Stats/Designations.vue`** — `ct-stats-designations*`, using the new `ChartRowStacked` and the
      12-colour palette for its own legend-key swatches (same palette, one shared source of truth for
      both). Jurisdiction sub-list uses new `shared/list.css` (`tw-shared-list-underline-*`) — the first
      real consumer of `tw-shared-scrollbar`, pre-built dead-but-flagged since T1. `list__a`'s `::after`
      chevron background-image → real `Icon/CircleChevron.vue` per rule 5b. New `shared/card.css`
      (`tw-shared-card-stats`) for the legacy `card-stats` mixin, including its `.pdf &` override as a
      plain rule (can't live in scoped SFC style, same stylelint-bem-namics restriction T5 hit).
      `_card-stats-designations.scss` deleted (zero consumers once its own `card--stats-designations`
      class stopped being rendered).
- [x] **`Stats/IucnCategories.vue` + `Stats/Governance.vue`** — both `ct-stats-{iucn-categories,
      governance}*`, sharing new `tw-shared-card-stats-half`/`tw-shared-card-stats-wrapper` (`shared/
      card.css`) for the legacy `card--stats-half`/`--wrapper` layout and `shared/list.css` for their
      `list--underline` rows (same per-index palette applied to `.list__icon`, confirming the legacy
      `theme-chart-list-icon` mixin already ran unconditionally for every `list--underline` consumer —
      `Governance`'s own `.theme--governance` modifier turned out to be a no-op duplicate of the same
      nth-child logic, not a distinct visual). "View list" link ported to the same `Icon/CircleChevron.vue`
      + `max-lg:hidden` text (the legacy `text-indent:-9999px` mobile icon-only technique).
      `_card-stats-iucn.scss` deleted. `_card-stats-governance.scss` **also deleted, but it was already
      fully dead before this wave** — `Governance.vue` has only ever rendered `card--stats-iucn`, never
      its own same-named file's `card--stats-governance` class (confirmed via grep, zero consumers ever).
- [x] **`RegionCountryPages/Index.vue`** (the wrapper nesting the whole Stats family on country/region
      pages, not separately named in this wave's original component list but load-bearing) — its
      `card--stats-toggle`/`card--stats-wrapper` wrapper divs now use the new `tw-shared-card-stats`/
      `tw-shared-card-stats-wrapper` shared classes. Closed `_card-stats.scss`'s own `&--stats-wrapper`/
      `&--stats-toggle` blocks (zero other consumers) and deleted `_card-stats-toggle.scss` outright
      (its only content was the now-closed `&--stats-toggle`). `&--stats-half`/`&--feault-block` stay —
      `Stats/Coverage.vue` and `Stats/Sources.vue`/`Attributes/ProtectedArea/Source/List.vue`/
      `Dropdown/ParcelsDropdown.vue` (T8) still depend on them.
- [x] **`_card-stats-overlap.scss` deleted** — turned out to never even be `@import`ed by `_card-stats.scss`
      in the first place (missing from its own import list), on top of having zero template consumers.
      Pure dead weight from before this wave started.
- [x] **`Stats/Sites.vue` regression fixed** — see the pre-work audit note above. Rebuilt as `ct-stats-
      sites*`, mirroring `SearchAreas/Results/Item.vue`'s already-established card shell (same legacy
      file family) rather than reinventing one, plus the two behaviours specific to this "preview" usage
      that `SearchAreas`'s version never needed: hide the 3rd card on mobile (`nth-child(3):max-md:hidden`)
      and the trailing-lone-2nd-of-3 centering hack (`:not(:first-child, :nth-child(3n+1), :nth-child(3n)):
      last-child`). No placeholder-icon fallback needed — `thumbnail_link` is a required field, unlike
      `SearchAreas`'s optional `image`.
- [x] **`Stats/Sources.vue`** → `ct-stats-sources*`, reusing `tw-shared-card-stats` (its root was
      `card--feault-block`, the same `@include card-stats` mixin as the three components above) and the
      `_lists.scss` `list--underline-sources` variant (new `tw-shared-list-underline-scrollbar` +
      per-field `md:w-[15%]/[40%]/[45%]` widths, ported to `shared/list.css`). Dropped `sm-sources` — a
      bare class with zero backing CSS anywhere, shared with `Attributes/ProtectedArea/Source/List.vue`
      below, confirmed dead via grep across the whole tree, not carried forward. `card__content`'s
      `flex`/`flex-col`/`md:flex-row` (the `card-stat-content` mixin) ported directly since this
      component owns its own `card--feault-block` root.
- [x] **`Stats/Message.vue`** — already had a partial `<style>` block (its own two link variants); closed
      the remaining gap (`card--message`'s wrapper + `list--links`' chip-row list). `card--message`/
      `card__warning` confirmed to have **zero backing CSS anywhere** even in the legacy source — carried
      forward unstyled, not invented. New `tw-shared-list-links-item` (`shared/list.css`).
- [x] **`Attributes/Pame/{List,Pame}.vue`** — `card--attributes-pame`/`list--stripes` → `ct-attributes-
      pame-list*`/`ct-attributes-pame*`, reusing `tw-shared-card-stats` and a new `tw-shared-list-stripes-
      item`/`-title` pair (`shared/list.css`). The legacy `.pdf &` override targets the *root card*
      itself (flex-col, 2rem gap between multi-parcel instances in PDF mode), not `.card__all-attributes`
      as originally guessed — that class turned out to be a pure marker with zero own CSS, dropped.
      `card__h3` (the per-parcel subtitle) confirmed to belong to an unrelated `card-news` mixin (T3,
      already migrated) — Pame's own `<h3>` never matched it, carried forward unstyled.
      `_card-attributes-pame.scss` deleted.
- [x] **`Attributes/ProtectedArea/{Index,AttributeList}.vue`** — same `list--stripes` shell as Pame,
      `card--attributes-pa-and-parcels` → `ct-attributes-protected-area*`. Unlike Pame, this root is
      *always* `flex flex-col gap-4` (not pdf-conditional) — the pdf-only piece here is
      `.card__all-attributes` itself gaining `flex-col gap-16`, a genuinely different shape from Pame's
      file despite the near-identical markup. `_card-attributes-pa-and-parcels.scss` deleted.
- [x] **`Attributes/ProtectedArea/Source/{Attributes,List}.vue`** — same `card--feault-block`/
      `list--underline-sources` shell as `Stats/Sources.vue` (byte-for-byte identical legacy markup,
      confirmed by reading both side by side), ported the same way; `Attributes.vue` (the leaf) has no
      own card-stats root — it's always nested inside `List.vue`'s, so its `card__h2`/`card__content`
      rules were only ever real via that ancestor relationship, same conclusion applied here.
      `sm-sources` dropped again (see `Stats/Sources.vue` above).
- [x] **`Attributes/Affiliations/{Affiliation,Index,List}.vue`** — `card--stats-affiliations` →
      `ct-attributes-affiliations*`. Two dead-code findings preserved, not fixed: `.card__button`
      (`translations.more`) is `display: none` in the legacy source with its own "to be added later"
      comment — ported hidden, not completed; and `.card__subtitle--link`'s flex/no-underline rules were
      never actually paired with the base `.card__subtitle`'s bold/margin in the real markup (the two
      were never stacked on the same element) — preserved as two independent, non-overlapping classes
      rather than "fixed" to match the modifier-implies-base BEM convention the legacy code never
      actually followed. `card__logo`/`card__h3` (the per-parcel subtitle) confirmed unstyled, same as
      Pame. `_card-stats-affiliations.scss` deleted.
- [x] **`_stats-related-countries.html.erb`** (ERB, `country/show.html.erb`'s `relatedCountriesHtml`
      prop — rendered server-side, then injected into `RegionCountryPages/Index.vue` via `v-html`) →
      `vw-partials-stats-stats-related-countries*` (rule 4c path-mirroring), new `views/partials/stats/
      stats-related-countries.css`. Reuses `tw-shared-card-stats` + `tw-shared-list-underline-*` from
      shared/card.css`/`list.css` — the first ERB (non-Vue) consumer of either. The "View" link's chevron,
      a Vue `Icon/CircleChevron.vue` component in every other consumer, becomes the pre-existing
      `tw-shared-icon-circle-chevron-black` CSS background-image utility instead (rule 5b's ERB-view-chrome
      carve-out — no Vue render tree to mount a component into from a `link_to` helper call).
      `_card-stats-related.scss` deleted.
- [x] **`_card-stats.scss` trimmed further**: removed the now-dead `&--feault-block .card__content` rule
      (its `card-stat-content` mixin has no remaining caller under this selector — `Dropdown/
      ParcelsDropdown.vue`, the one real `card--feault-block` consumer left, uses its own unrelated
      `card__top` class, not `card__content`) and the now-dead `card-button-external` mixin (its one
      caller was the just-deleted `_card-stats-affiliations.scss`). `&--feault-block`'s `card-stats`
      include + `.card__h2` rule stay — `ParcelsDropdown.vue` (T8) still needs both.
- [x] **`Stats/Coverage.vue`** — `ct-stats-coverage*`, reusing `tw-shared-card-stats`/`-half`. The
      `theme--${type}` square (`_chart-square.scss`) becomes two real modifiers (`--marine`/
      `--terrestrial`, `bg-theme-blue`/`bg-theme-bright-green` — both already-existing tokens, exact hex
      matches for `$marine`/`$terrestrial`) — confirmed via `CountryPresenter#yml_key` that the real prop
      value is always one of those two strings, never the literal `'land'` its own Vitest spec's fixture
      data uses (a pre-existing test/reality mismatch, not fixed — the fixture's `type: 'land'` still
      resolves to no matching modifier, same dead-in-practice outcome as before). `_card-stats-coverage.
      scss`/`_chart-square.scss` deleted; the now-fully-dead `card-stat-content`/`card-stats-number`
      mixins removed from `_card-stats.scss` too (zero remaining callers once this file's `card--stats-
      coverage`/`_card-stats-overview.scss` — see below — were gone). `_card-stats.scss`'s own
      `&--stats-half` block also removed (dead — every real `card--stats-half` consumer had already
      moved to `tw-shared-card-stats-half` earlier this wave).
- [x] **`Stats/TooltipInfo.vue`** — `ct-stats-tooltip-info*`. `.carousel__tooltip` (the class it passed
      onto `TooltipSecond`) had zero backing CSS anywhere — dropped, not ported.
- [x] **The ERB `card--stats-overview` card** (`_stats-overview.html.erb`/`-country.html.erb`, both
      identical apart from two extra `StatsTooltipInfo` mounts — same "one shared file" precedent as T3's
      `error-page.css`) → `vw-partials-stats-stats-overview*`, new `views/partials/stats/stats-overview.
      css`. `.card__flag.icon--flag-outline`'s two stacked legacy classes merged into one
      (`__flag`); `.card__subtitle-margined.card__flex`/`.card__subtitle.card__flex`'s stacked pairs each
      became one combined class (`flex` wins over `card-stats-overview-subtitle`'s own `display: block`
      in the legacy cascade — it's there to sit the label next to `StatsTooltipInfo`'s trigger, so flex is
      the intended, not accidental, outcome). `.card__external-text` confirmed to have zero backing CSS
      (same as `Stats/Message.vue`'s `card__warning` earlier this wave) — carried forward unstyled.
      `card__external-button`'s `@extend .button--link-external` (icon-arrow-external `::after`, no
      color/font of its own) → the existing `tw-shared-icon-arrow-external` utility via `after:`, ERB's
      standard rule-5b icon carve-out. `_card-stats-overview.scss` deleted whole — every one of its rules
      turned out to belong to either this ERB card or `TooltipInfo.vue`, nothing left over.
- [x] **`_chart-legend.scss`'s `--map`/`--points-poly` blocks** (the last two live variants — `--
      designation` moved into `Stats/Designations.vue` earlier this wave, `--vertical` was already dead)
      → `_chart-legend.html.erb` rewritten to `vw-partials-charts-chart-legend*`, new `views/partials/
      charts/chart-legend.css`. Its own `row[:theme]` was previously a **full legacy class-name string**
      built in Ruby (`'theme--primary'`, `'theme--terrestrial'`, etc., from `{country,region}_presenter.
      rb#chart_point_poly` and `map_helper.rb#map_legend`) stacked directly onto `chart__legend-key` —
      interpolating that into a `vw-` element would mean ERB rendering a raw legacy/`tw-shared-*` class
      name directly, which rule 4c forbids. Changed all three Ruby call sites to emit a short key
      (`'primary'`/`'primary-dark'`/`'terrestrial'`/`'marine'`/`'oecm'`) instead, so the partial can build
      its own `vw-partials-charts-chart-legend__key--<variant>-<key>` class name from data it controls
      end to end. Same fix applied to `_chart-row.html.erb` (→ `vw-partials-charts-chart-row*`, new `
      views/partials/charts/chart-row.css`), the other consumer of the same `chart_point_poly` rows —
      `chart__bar-overseas` (zero consumers anywhere, confirmed via grep) dropped, not ported.
      `_chart-legend.scss`/`_chart-row.scss` deleted, and with them `components/_charts.scss` itself —
      empty once both were gone, so it and the now-empty `components/charts/` directory are gone too.
- [x] Fixed a typography-routing gap this same session: `Coverage.vue`/`TooltipInfo.vue`/`stats-overview.
      css` initially landed with raw `text-*`/`font-*` combos instead of going through `shared/
      typography.css`, inconsistent with how every other T6 component already routed size+weight(+colour)
      combos through a named `tw-shared-font-*` utility (bare single-property utilities like a lone
      `font-bold` or `text-sm` stay unwrapped — only true combos need a named utility). Added two new
      ones (`tw-shared-font-hind-siliguri__normal-4xl`, `...bold-3xl-md-4xl-leading-none-primary`) for the
      two combos with no existing match; everything else composed onto what already existed (e.g. the
      ERB card's `card__h1`'s 20→25px bold white reuses `tw-shared-font-hind-siliguri__normal-xl-white` +
      `md:text-2xl`, `--text-2xl`'s custom 1.565rem token being an exact match for legacy's 25px).
      `TooltipInfo.vue`'s literal `color: black` (not the site's usual `grey-black`) folded into the
      existing `tw-shared-font-hind-siliguri__light-base-grey-black` — the only place in the whole
      codebase that ever used true black instead of grey-black, read as an authoring slip rather than a
      deliberate distinct colour.
- [x] **This wave closes the Wave-8 `Stats*`/`ChartRowPa`/`ChartRowStacked` rule-4 exception** — removed
      from CODE-CONVENTIONS.md's exception-precedent list.
- [ ] amCharts 4→5 is explicitly out of scope here (already deferred separately per README) — style
      the amCharts *wrapper* markup only, not the chart library's own internals.
- [x] Live-verified (Playwright, `/en/country/BRA` for the full stats-overview card — flag/heading/h1,
      map legend's 3 correctly-coloured swatches, the polygons/points chart-row bar + its own legend,
      computed font-size/weight/colour on `__h1`/`__number`/`__subtitle-margined` all matching the ported
      typography exactly; `/en/country/{USA,IND,DEU}` for `StatsTooltipInfo`'s trigger icon rendering.
      `Stats/Coverage.vue` itself never appeared on any country tried in this dev environment's seed data
      — verified by code-reading + its own passing Vitest spec instead, same seed-data-gap pattern as
      `Stats/Sites.vue`/`Attributes/Affiliations` earlier this wave) plus everything verified earlier this
      wave (see above). `yarn typecheck`/`stylelint`/`yarn lint`/`vite:build`/`bundle exec rake assets:
      precompile` all clean (2 pre-existing unrelated TS parse errors in `useMapBoundingBox.spec.ts`/
      `useMapLayers.spec.ts` reproduce identically on unmodified HEAD, not from this wave). `yarn vitest`
      all green except one pre-existing failure (`TotalCoverageChart.spec.ts`'s legend-colour assertion,
      reproduces identically via `git stash`) — a stale `showSitePid` prop reference in `AttributeList.
      spec.ts` (left over from the user's own concurrent `showSitePid`→`forPdf` prop rename) was a real
      regression, fixed in this pass.

---

## Wave T7 — Cards family, Listing cards, Carousel (~1–1.5 wk) — **partially done** (re-audited 2026-08-10)

**Remaining files** — re-verified still on disk with real Vue consumers: `cards/cards/{_cards-articles,
_cards-basic,_cards-resources,_cards-search-results,_cards-search-results-areas}.scss`,
`card/attributes/{_card-attributes-pa-and-parcels,_card-attributes-parcels-dropdown}.scss`.
**Already deleted, contrary to this wave's original file list**: `components/_cards.scss` no longer
has a live `.card`/`.cards` class body worth migrating (the family aggregator, superseded by the ERB
work below), `cards/cards/_cards-themes.scss`, and `card/_card-theme.scss` — both gone, folded into
`Carousel/Themes/Card.vue`'s own `ct-theme-card*` scoped styles (see below).

**Components — split by actual status, re-verified 2026-08-10:**
- [x] `ListingPageCard/{News,Resources}/{Index,Card,Info}.vue` — **done.** Fully `ct-listing-page-
      card-*` prefixed with scoped `@apply` styles, zero unprefixed legacy classes remain in either
      the templates or their specs. **This wave closes the `ListingPageCard` rule-4 exception** —
      remove it from CODE-CONVENTIONS.md's exception-precedent list.
- [x] `Carousel/Themes/{Index,Card}.vue` — **done**, contrary to this wave's original "half-`ct-`/
      half-legacy, finish the job" framing. `Card.vue` is now fully `ct-theme-card*` with no leftover
      `card__`/`card--` classes anywhere in the file or its spec.
- [x] The static ERB card grids (`partials/cards/_{circles,facts,squares,news,resources,sites,
      themes}.html.erb`) — already confirmed done under **Wave T3** above (they were misfiled as T7
      cards-family work in this wave's old framing, but their real consumer is ERB, not Vue — no
      overlap with the Vue items below).
- [x] `SearchAreas/Results/{Index,Item}.vue` — **done.** Fully `ct-search-areas-results*`-prefixed
      with scoped `@apply` styles; the fallback image now renders `Icon/PlaceholderImage.vue` per
      rule 5b instead of the legacy `::after` mixin. `cards/cards/_cards-search-results-areas.scss`
      and `search/_search-results-areas.scss` (plus `_search.scss`'s import of the latter) deleted —
      confirmed zero other consumers.
- [x] `Search/Results/{Index,Item}.vue` — **done (2026-08-13).** `Index.vue` root/total/grid now
      `ct-search-results`/`ct-search-results__total`/`ct-search-results__list` (vertical `gap-y-5`
      list per the flex/grid-over-margin Decision, replacing the legacy `margin: 20px 0` on each
      card); `Item.vue` is `ct-search-results-item*`, with the no-image fallback rendering
      `Icon/PlaceholderImage.vue` per rule 5b (same pattern as `SearchAreas/Results/Item` above) instead
      of a bare `:style` background. Added `tw-shared-font-hind-siliguri__bold-lg-md-xl-grey` to
      `shared/typography.css` for the `.search__total` count text (bold, `$grey`, 18px/`$small`→20px,
      i.e. `text-lg md:text-xl`) — no existing utility matched. The legacy `.card__title`/`.card__summary`
      selectors were empty rules (bare browser-default `h3`/`p`, no deliberate styling) — left with no
      `@apply` counterpart rather than inventing a font treatment that never existed. `cards/cards/
      _cards-search-results.scss` and `components/search/_search-results.scss` (plus `_search.scss`'s
      import of the latter) deleted — confirmed zero other consumers; `.search`'s own `&--pa` block
      (unrelated) stays.
- [x] `Attributes/ProtectedArea/*` — **stale, already done.** This item was never actually T7 scope —
      `Attributes/ProtectedArea/{Index,AttributeList,Source/{Attributes,List}}.vue` were migrated under
      **T6** (see that section's entries above; `_card-attributes-pa-and-parcels.scss` is already
      deleted). Re-verified 2026-08-13: all four files are fully `ct-attributes-protected-area*`/no bare
      legacy classes remain. Corrected here so this checklist stops claiming 100%-legacy for files that
      no longer exist on disk.
- [x] `Dropdown/ParcelsDropdown.vue` — **done** — `ct-parcels-dropdown*`, reusing `tw-shared-card-stats`/
      `tw-shared-list-title`/`tw-shared-list-underline-value`. `card/attributes/
      _card-attributes-parcels-dropdown.scss` and the now-fully-dead `_card-stats.scss` deleted. T7
      is now fully done.
- [x] Live-verified: gdpame page's parcels dropdown (via the shared `Dropdown/Base.vue` it wraps),
      search results, PA attributes cards — see T8 below for the same session's full live-verify pass.

**T7 is now fully done (2026-08-13).**

---

## Wave T8 — PAME + Dropdown + Select, closes Wave-9/10 rule-4 exceptions — done (2026-08-13)

Files: `components/table/{_table-pame,_table-head-pame,_table-horizontal-scroll,
_table-head-horizontal-scroll}.scss`, `components/filters/_filters-pame.scss`,
`components/modal/_modal-pame.scss`, `components/_dropdown.scss`, `_tooltip.scss`,
`components/_select.scss` + `components/select/{_select-searchable,_select}.scss`,
`base/_buttons.scss`. (`card/attributes/_card-attributes-pame.scss` turned out already deleted under
T6 — see that section.)

Components: `Pame/{Modal,Filters/**,Table/**}`, `Dropdown/{Base,Options}`. (`Attributes/Pame/
{Pame,List}` turned out already done under T6 — this wave's original component list mis-tracked them,
same recurring doc-drift pattern as T7's `Attributes/ProtectedArea/*`.)

- [x] Closes the **Wave 10 `Pame/*`** and **Wave 9 `Dropdown`** rule-4 exceptions — remove both from
      CODE-CONVENTIONS.md's exception list.
- [x] `Dropdown/Base.vue`/`Options.vue` — real `@apply` styles added. `Base.vue`'s button reuses
      `tw-shared-button--border-theme-primary` (exact match for legacy `button-outline($black,1px)`);
      `Options.vue`'s list reuses `tw-shared-shadow-grey`. Renamed `ct-dropdown` → `ct-dropdown-base`
      mid-wave to disambiguate from `Options.vue`'s `ct-dropdown-options` (propagated into both specs).
      `_dropdown.scss` deleted.
- [x] `Pame/Modal.vue` — `ct-pame-modal*`. Close button is now a real `Icon/Close.vue` (rule 5b) instead
      of the `button-close`/`icon-cross` mixin. `z-300`/`z-400` are valid bare Tailwind v4 utilities
      (not arbitrary values). `_modal-pame.scss` deleted.
- [x] `Pame/Filters/*` family — `ct-pame-filters`/`ct-pame-filter`/`ct-pame-filter-option`. Chevron and
      tick-mark background-image swaps replaced with real `Icon/Arrow.vue` (rotated) and a new
      `Icon/Tick.vue`. Confirmed via `PameEvaluation.filters` that the legacy `--category`/`--donors`/
      `--ocean-region` per-filter max-width variants are dead (no such filter exists) — only the real
      `--country` variant was ported. `_filters-pame.scss` deleted.
- [x] `Pame/Table/*` family — `ct-pame-table*`. `$large` (1200px) mapped to native `xl:` for the
      desktop-table/mobile-card switch. `Row/Mobile.vue` dropped 9 per-field modifier classes confirmed
      to have zero CSS backing (including a pre-existing `able__list-item--site-id` typo). `Head/*`'s
      decorative sort icons got the same real-`Icon/Arrow` treatment as the filter chevron.
      `Table/DownloadCsv.vue`'s one dangling legacy spinner closed out with `tw-shared-icon-loading-spinner`
      (not `.button`/`.button__text` as originally flagged — that part was already done in an earlier
      undocumented pass). `table/_table-pame.scss`, `table/_table-head-pame.scss`, `components/_table.scss`
      deleted.
- [x] Confirmed-dead, deleted without migration: `table/_table-horizontal-scroll.scss` +
      `table/_table-head-horizontal-scroll.scss` (a second, separate table variant, zero consumers
      ever); `_tooltip.scss` (`Tooltip/Index.vue` + `Tooltip/Second.vue` were both already fully
      migrated from an earlier undocumented pass, so the legacy `.tooltip*` classes were already dead);
      `components/_select.scss` + `components/select/{_select,_select-searchable}.scss` (confirmed
      superseded by `Search/SiteInput.vue` — the "not independently confirmed" flag from the T0-era
      audit is now resolved; `select/_select.scss` itself was never even `@import`ed); `base/_buttons.scss`
      (zero remaining class/mixin consumers once the above landed).
- [x] Live-verified via Playwright screenshots on the gdpame page: filters open/close, checkbox + tick
      icon + badge counter, Apply correctly filters (and correctly shows "no records" + disables CSV
      when zero results), modal opens/closes with content, sticky table header holds on scroll, mobile
      viewport switches to the card-list layout, no new console errors. `ParcelsDropdown`'s live click-
      through wasn't reachable (no real multi-parcel PA in the dev seed data) — covered instead by the
      full green `Dropdown`/`ParcelsDropdown` Vitest suite.

---

## Wave T9 — Residual tabs/filters coupling (~0.5 wk) — **done** (confirmed 2026-08-14)

**Re-audited before starting, per this doc's own repeated drift lesson — and found the whole wave
was already closed.** `_tabs.scss` and `_filters-sidebar.scss` no longer exist anywhere on disk
(`find app/assets/stylesheets -iname "*tabs*" -o -iname "*filters-sidebar*"` returns nothing). All
5 named components already render fully `ct-`-prefixed markup with their own `<style scoped>`:
`SearchAreas/CheckboxSearch.vue` (`ct-search-areas-checkbox-search*`), `SearchAreas/FilterGroup.vue`
(`ct-search-areas-filter-group*`), `Listing/FilterGroup.vue` (`ct-listing-filter-group*`),
`RegionCountryPages/Index.vue` (`ct-region-country-pages*`). `SearchAreas/Index.vue` turned out to be
a thin wrapper with zero markup classes of its own (just renders `SearchAreas/InputAutocomplete.vue`)
— nothing to migrate there either. This landed via the same undocumented-direct-commit pattern as
every prior doc-drift episode (see [[scss-tailwind-plan-drift-2026-08-10]] in memory) — the 2026-08-13
"migrate search page, pa page" / "migrate pa site" / "migrate country region pages" / "migrate
attributes" commits closed this wave's scope without it ever being logged here.

No code changes were needed for T9 itself — see T10 below for what this session's re-audit turned up
instead (a live-breaking bug plus the rest of the legacy tree turning out to be dead too).

---

## Wave T10 — Finish (~1 wk) — **almost done** (started 2026-08-14)

**Started by re-auditing T9 (above) and immediately found a live-breaking bug**, not just doc drift:
`bundle exec rake assets:precompile` was failing outright —
```
SassC::SyntaxError: Error: File to import not found or unreadable: ./filters/filters-pame.
  on line 9:3 of app/assets/stylesheets/components/_filters.scss
  from line 7:1 of app/assets/stylesheets/application.scss
```
`components/_filters.scss` and `components/_modal.scss` were left behind by the T8 session's deletion
of `_filters-pame.scss`/`_modal-pame.scss` — their own only content was `@import`ing those now-gone
files, so they'd been silently broken since 2026-08-13. This would have broken any real deploy
(`assets:precompile` is a hard requirement) and, since `_head.html.erb` links `application.css`
whenever `@for_pdf` is true, PDF export specifically. `bin/rails runner` is still broken in this
container (prints `rails new` help regardless of script, same issue noted in
[[t8-pame-dropdown-select-wave-done]]) — used `docker exec ... bundle exec rake assets:clobber
assets:precompile` directly against `protectedplanet-web` to reproduce and then re-verify after each
fix, since Vite's dev server never touches this Sprockets pipeline at all.

**Fixing it cascaded into finishing the rest of this wave's SCSS deletion in one pass**, because once
`_filters.scss`/`_modal.scss` were confirmed to have zero other content, a full fresh
`class="..."`-usage grep sweep (across `app/frontend` + `app/views`, careful to exclude `ct-`/
`tw-shared-`/`vw-` prefixed false-positive substring matches — e.g. `cards--resources` inside
`ct-listing-list__cards--resources`) found **the entire remaining legacy SCSS tree had zero live
consumers left**:

- [x] `components/{_filters,_modal,_search,_cards}.scss` + `components/{cards,form}/**` (the
      `.filters`/`.modal`/`.search--pa`/`.card--message`/`.cards--{articles,basic,resources}`
      families, plus the bare `input {}` tag selector in `form/_input.scss` — every real `<input>`
      consumer, e.g. `Search/SiteInput.vue`, already has its own `<style scoped>` with zero reliance
      on it) — all confirmed zero consumers, deleted.
- [x] `base/_base.scss` — already 100% commented out since preflight/Tailwind fonts took over
      (see the 2026-08-07 finding above); deleted outright, nothing to migrate.
- [x] `base/_circles.scss`, `base/_icons.scss`, `base/_svgs.scss`, `base/_themes.scss` — every
      `.icon--*`/`.svg--*`/`.theme--*`/`circle-*` class and mixin confirmed zero consumers; deleted.
- [x] `base/_fonts.scss` — the legacy `MuseoSans`/`MuseoSlab` `@font-face` declarations, fully
      superseded by `app/frontend/styles/fonts.css`'s self-hosted Hind Siliguri/Playfair Display
      (confirmed via `grep -rl MuseoSans` returning only the file itself); deleted.
- [x] `helpers/_cms.scss` — already flagged dead in this doc's own T3 section (zero `.cms-wysiwyg`
      ERB consumers left, `tw-shared-cms-wysiwyg` replaced it); deleted, closing that lingering T3 item.
- [x] `helpers/{_background,_beautify-scrollbar,_border-and-shadows,_form-fields,_images}.scss` —
      every mixin's `@include` consumers were themselves already-dead files from this same list (e.g.
      `input-custom-focus`'s only caller was the already-commented-out `base/_base.scss`); deleted.
- [x] `helpers/_helpers.scss` — the T3 "still genuinely open" item (`.block`/`.bold`/`.ul-unstyled`/
      `.no-margin`/`.margin-center`/`.hover--pointer`) — all confirmed zero consumers now (unlike at
      T3's own check); deleted, along with its `@import` chain into the 5 files above.
- [x] `helpers/mixins/{_cards,_icons,_layout,_text}.scss` — pure mixin files, only ever `@include`d
      by the now-deleted files above; deleted.
- [x] `utilities/{_flexbox,_media-queries}.scss` — same; **`utilities/_rem-calc.scss` kept**, since
      `_settings.scss` itself calls `rem-calc()` to compute its own `$gutter-*`/`$spacer-*` variables.
- [x] `application.scss` rewritten to just `@import './utilities/rem-calc'; @import './settings';` —
      confirmed via the compiled output that it's now a byte-for-byte empty file (`sha256` of `''`,
      `wc -l` = 0). This is expected, not a bug: recall the 2026-08-07 finding that `application.css`
      hasn't been linked on normal page loads for a while now anyway (PDF-export-only) — every class
      that ever lived in it has either been ported to Tailwind already or, per the checks above, had
      zero real consumers left to port.
- [x] Remaining tree: only `_settings.scss`, `utilities/_rem-calc.scss`, `application.scss` (stub),
      `pdf.scss`, and the out-of-scope `comfy/admin/cms/custom.scss`.

**`pdf.scss`'s fate — decided as option (b), left on the existing Sprockets/sassc path.** It only
`@import`s `settings` (no dependency on anything just deleted) and every class it references
(`.vw-layouts-partials-topbar`, `.vw-country`/`.vw-protected-areas`/`.vw-region`, `.ct-map-baselayer-controls`, `.container`,
etc.) is either already a live Tailwind-era class or a pre-existing, separately-tracked legacy
oddity (`.pa-card`, `.leaflet-control*` — dead Leaflet-era selectors from before the MapLibre
migration, out of scope here, harmless to leave). It's 39 lines, isolated, and still compiles
standalone — porting it to hand-written Tailwind-adjacent CSS (option a) would add risk for no
real benefit. **Because of this decision, `sassc`/`sass-rails` must stay in the Gemfile** — they're
still the only thing that compiles `pdf.scss` (and the now-stub `application.scss`) — the "remove
sassc/sass-rails" item below only applies if a future session instead chooses option (a).

- [x] Remove `bourbon`/`neat` gems and their Sprockets `assets.paths` entry — confirmed zero
      remaining `@import`/mixin usage anywhere in the 5-file tree above (bourbon/neat mixins were
      never used by `_settings.scss`, `_rem-calc.scss`, or `pdf.scss`). Removed from `Gemfile` +
      `config/initializers/assets.rb`; `bundle install` inside `protectedplanet-web` completed clean
      (400 gems, both gone from `Gemfile.lock`); re-ran `assets:precompile` after — still clean.
- [ ] Remove `sassc`/`sass-rails` from the Gemfile — **not done, and shouldn't be** unless a future
      session revisits the `pdf.scss` decision above (option a instead of b).
- [ ] **Enable Tailwind preflight** (`app/frontend/styles/tailwind.css` — uncomment
      `@import "tailwindcss/preflight.css" layer(base);`) — not done this session. Risk is now much
      lower than when this item was originally written (there is no legacy SCSS left to fight at all,
      versus "almost the whole site" when this decision was first made), but it's still the one
      previously-forbidden change and deserves its own dedicated live full-site sweep rather than
      being folded into an already-large session — see the next item.
- [ ] Full-site visual sweep post-preflight: every page type hit in every prior wave's "Live-verify"
      step, plus 404/500 pages, PDF export, Comfy admin (admin is unaffected since preflight only
      applies to the public-site Vite entrypoint — confirm that boundary holds).
- [ ] Update [08](./08-styles-and-assets.md)'s exit criteria checklist and this doc's Status line to
      "done."

**Verified this session**: `bundle exec rake assets:clobber assets:precompile` clean (exit 0) after
every batch of deletions. `bundle install` clean after the gem removal. Live PDF-export smoke test —
`GET /country/USA?for_pdf=true` returns 200, both `pdf.self-*.css` and `application.self-*.css`
`<link>` tags resolve, rendered HTML has the `.pdf` root class present (matches `pdf.scss`'s
selectors). Live Playwright check (home, country pages, 1400px viewport, after restarting the
crash-prone `protectedplanet-vite` container per [[vite-dev-server-optimize-deps-crash]]): both fully
styled, no visual regression from any of the deletions above (expected, since none of the deleted
classes had live consumers to begin with). Remaining console noise/500s are pre-existing and
unrelated: a WebSocket HMR handshake warning (Playwright-vs-dev-server artifact, not a real user
issue) and `/search` 500ing with `PageNotFound in ProtectedAreasController#show` — the same seed-data
routing gap already documented in T3's "couldn't be reached in this dev environment's seed data" note,
confirmed via the server log to predate this session.

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
7. **An icon rendered by a Vue component is an `Icon/*.vue` component, never a `tw-shared-icon-*` CSS
   class** (CODE-CONVENTIONS.md rule 5b, added during T1) — applies to every wave from here that
   migrates an icon-consuming component (T2's ERB-only chrome is the one exception, since `vw-`
   classes have no Vue component to hang an icon off). When a legacy icon mixin needs per-instance
   color variation (like the old `icon-pin($circle, $outline)` family), follow `Icon/Pin.vue`'s
   per-part `@apply fill-*` pattern rather than reaching for a background-image utility or inventing
   a new mechanism.

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
