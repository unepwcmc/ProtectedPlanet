# 09 — CMS — ComfortableMexicanSofa compat

| | |
|---|---|
| **Estimate** | 1–4 weeks · ~0.25–1 month (wide range depends on compat verdict) |
| **Depends on** | [01 — Gem audit](./01-gem-audit.md) (must investigate before Rails 7 work begins) |
| **Blocks** | **B3** (Comfy `/admin` on upgrade branch) · indirectly blocks frontend CMS pages |

[← Back to overview](./README.md)

---

## Goal

Confirm whether `comfortable_mexican_sofa ~> 2.0.0` works on Rails 7/8 and agree on a path. This is the **single highest-risk item** in the backend upgrade — investigate it first in [01 — Gem audit](./01-gem-audit.md) before writing any Rails upgrade code.

---

## Why this is high risk

- ComfortableMexicanSofa 2.x was last actively maintained for Rails 5/6. Rails 7 support is uncertain.
- The CMS drives a large portion of the public-facing site (resource pages, news, equity pages, thematic area copy).
- If Comfy breaks on Rails 7 and there is no maintained patch, the options involve significant work (fork, patch, or replace).
- **B3 milestone** (Comfy `/admin` works on upgrade branch) is a frontend dependency — if B3 slips, it delays CMS-related frontend pages.

---

## Investigation checklist (Phase 1 — do immediately)

- [ ] Check `comfortable_mexican_sofa` GitHub repo — is there a Rails 7 / Rails 8 branch or issue?
- [ ] Check if the gem is still actively maintained, or if it has been archived
- [ ] Look for community forks that add Rails 7/8 support (search: `comfortable_mexican_sofa rails 7`)
- [ ] Try booting the app on Rails 7.0 with Comfy loaded (upgrade branch) — note all errors
- [ ] Hit `/admin` — what breaks?
- [ ] Document every error with the offending file and line number

---

## Known Comfy dependencies to check independently

| Gem | Rails 7/8 concern |
|-----|-------------------|
| `tinymce-rails ~> 4.3.2` | TinyMCE 4 is EOL (2023). Rails 7/8 asset pipeline may not compile it the same way. Upgrade to `tinymce-rails ~> 6.x` or load TinyMCE via CDN in Comfy admin layout. |
| `jquery-rails` | Comfy admin may depend on jQuery via Sprockets — confirm it still loads on Rails 7 |
| CoffeeScript files | Already planned for migration by frontend ([frontend/12](../frontend/12-gemfile-frontend-dependencies.md)); do this before Rails 7 bump |

---

## Option A — Comfy works with minor patches

If Comfy boots and the admin UI mostly works with small fixes:

- Apply patches directly to `config/initializers/comfy_patching.rb` (already exists)
- Or fork `comfortable_mexican_sofa` as a private gem under the `unepwcmc` GitHub org
- Estimated extra effort: **1–2 weeks**

Checklist if patching:
- [ ] Login to `/admin` works
- [ ] List / edit / create CMS pages works
- [ ] TinyMCE editor loads and can save content
- [ ] Image/file upload works (ActiveStorage)
- [ ] Fixture import (`rake comfy:cms_seeds:import`) works
- [ ] Public CMS page rendering works (no `cms_fragment_render` errors)

---

## Option B — Comfy requires a significant Rails 7/8 fork

If the gem's internals are tightly coupled to Rails 5/6 internals (e.g., uses removed AR callbacks, old routing API):

- Fork `comfortable_mexican_sofa` under `unepwcmc` org
- Target minimal changes to get `/admin` working and public rendering stable
- Use `gem 'comfortable_mexican_sofa', git: 'https://github.com/unepwcmc/comfy-fork'` in Gemfile
- Estimated extra effort: **3–4 weeks**
- This work should be spiked early (before committing to the full Rails 7 timeline)

---

## Option C — Replace Comfy (long-term, not in this estimate)

If Comfy is unmaintained and forking is not viable, a CMS replacement is a separate, larger project:

- Options: custom `ActiveRecord`-backed CMS, Spina, Alchemy, or move to a headless CMS
- **Do not include in this upgrade estimate** — treat as a parallel stream with its own planning
- The frontend upgrade can proceed without a CMS replacement — static/CMS pages use pattern A (Vue-free) and can stay on Rails + ERB + Sprockets until the CMS is replaced

---

## B3 milestone definition

B3 is satisfied when, on the upgrade branch:

1. `/admin` loads without errors
2. Backend engineer can login, create/edit a CMS page with TinyMCE
3. File/image upload works
4. At least one public CMS page renders correctly
5. `rake comfy:cms_seeds:import` completes without errors

---

## Comfy admin assets — not on Vite

The frontend plan explicitly defers Comfy admin from Vite. Admin assets continue to be served by Sprockets through this upgrade. Do not attempt to move Comfy admin onto Vite as part of B3.

---

## Exit criteria

- Comfy compat verdict documented (Option A, B, or C decision recorded)
- If Option A or B: B3 checklist passes on staging
- If Option C: separate planning document created; backend upgrade continues without CMS-dependent pages in scope
- `tinymce-rails` updated or replaced (TinyMCE 4 EOL addressed)
