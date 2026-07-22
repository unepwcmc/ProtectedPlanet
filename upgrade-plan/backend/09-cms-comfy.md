# 09 — CMS — ComfortableMexicanSofa → Comfortable Media Surfer

| | |
|---|---|
| **Estimate** | 2–3 weeks · ~0.5–0.75 month |
| **Depends on** | [02 — Ruby ≥ 3.2](./02-ruby-upgrade.md) · [04 — Rails 7.0](./04-rails-7.md) (gem requires both) |
| **Blocks** | **B3** (CMS admin on upgrade branch) · indirectly blocks frontend CMS pages |

[← Back to overview](./README.md)

---

## Goal

Replace the dead `comfortable_mexican_sofa 2.0.19` with the maintained fork **`comfortable_media_surfer`**, and port our Comfy customisations onto its internals.

This was previously the highest-risk unknown in the backend upgrade ("does Comfy work on Rails 7 at all?"). It is now a **known port with a known destination** — the risk moved from *strategic* (might have to replace the CMS) to *tactical* (how much of our monkey-patching still applies).

---

## Decision — use Comfortable Media Surfer

| | |
|---|---|
| Gem | `comfortable_media_surfer` ([shakacode/comfortable-media-surfer](https://github.com/shakacode/comfortable-media-surfer)) |
| Latest | **3.1.7** (Feb 2026) — actively released |
| Requires | **Ruby >= 3.2**, **Rails >= 7.0** |
| Rails 8 | Rails 8.1 compatibility since **3.1.5** |
| Schema | **Table names unchanged** (`comfy_cms_*`) — no core data migration |

### Why not the alternatives

| Option | Verdict |
|---|---|
| Stay on `comfortable_mexican_sofa 2.0.19` | Not possible — last release **31 Dec 2019**, no Rails 7/8 support, upstream dormant |
| Fork Comfy ourselves under `unepwcmc` | **Rejected** — Media Surfer already is that fork, maintained by someone else |
| Replace the CMS (Spina / Alchemy / headless) | **Rejected** — Media Surfer keeps our schema and content intact; a replacement is a separate project with a content migration attached |

The previous Option A / B / C decision tree in this document is closed. This is now a port, not an investigation.

---

## What is *not* a drop-in

Media Surfer 3.x is the **unreleased Comfy master line**, not a patched 2.0.19. Two sources of work:

### 1. Gem-side breaking changes (2.0.19 → 3.1.7)

| Change | Impact on us |
|---|---|
| Rails 5 and 6 support dropped | Fine — we adopt at the Rails 7.0 step |
| `sassc-sprockets` removed; **Propshaft support added**; **Node now required** for admin assets | Conflicts with the current "Comfy admin stays on Sprockets" assumption — see below |
| Editor is **Redactor + CodeMirror** (not TinyMCE) | `config.tinymce.install = :compile` in `config/application.rb:40` becomes dead; `tinymce-rails` can likely be dropped entirely rather than upgraded |
| New migration for Markdown snippets (3.1.2) | Run the engine's migrations |

### 2. Our own Comfy coupling

We don't use Comfy, we've grown into it — **64 `Comfy::` references** across `app/`, `lib/`, `config/`. Each one touches engine internals that may have moved:

| Our code | What it depends on | Port risk |
|---|---|---|
| `config/initializers/comfy_patching.rb` | `class_eval` on `Comfy::Cms::Fragment`, `Page`, `Layout`; `after_save` hook; parses `layout.content_tokens`; overrides the exporter | **High** — `content_tokens` and the exporter are private engine API |
| `app/models/comfy/cms/{page_category,layout_category,layouts_category,pages_category}.rb` | Four custom models extending the engine schema | Medium |
| `app/models/comfy/cms/searchable_{page,fragment,translation}.rb` | Feed CMS content into Elasticsearch | Medium — see [07](./07-elasticsearch.md) |
| `lib/cms_tags/categories.rb` | Custom CMS tag — depends on the tag registration API | **High** — tag API changed between Comfy 2.x and master |
| `lib/modules/cms_transfer.rb`, `lib/modules/sync_seeds.rb` | Fixture/seed export + import to S3 | Medium |
| `lib/tasks/cms_categories.rake`, `lib/tasks/update_cms_tags.rake` | Category + tag maintenance tasks | Low |
| `app/assets/javascripts/comfy/admin/cms/custom.js` | Sprockets `//= require comfy/admin/cms/editor` | Medium — target moves under Propshaft |

Expect the time to go into `content_tokens` parsing, the exporter override, and the custom CMS tag — not into the gem swap itself.

---

## Admin asset pipeline — assumption to revisit

The frontend plan currently states that **Comfy admin stays on Sprockets** through the upgrade and is explicitly kept off Vite ([frontend/15](../frontend/15-docker-vite-dev.md)).

Media Surfer 3.1 removed sassc-sprockets, added Propshaft support and requires Node for its admin assets. That assumption needs re-testing at the swap, not assumed forward.

- [ ] Confirm whether Media Surfer's admin assets render under our Sprockets setup as-is
- [ ] If not, decide: Propshaft for the admin namespace only, or serve admin assets from the gem's own build
- [ ] Flag the outcome to the frontend team — it affects [05 — Rails 8 / Propshaft](./05-rails-8.md) too

---

## Sequencing

Media Surfer needs **Ruby ≥ 3.2 and Rails ≥ 7.0**, so it cannot be adopted early. The plan is:

1. Keep `comfortable_mexican_sofa 2.0.19` through the **Rails 6.0 and 6.1** hops — it works on 6.x in practice
2. Do the **Ruby 3.2+ bump before Rails 7.0** rather than after — see [02](./02-ruby-upgrade.md)
3. Swap to `comfortable_media_surfer` as **part of the Rails 7.0 step**, as one cutover on the branch — see [04](./04-rails-7.md)

```
Rails 5.2 ──▶ 6.0 ──▶ 6.1 ──▶ [Ruby 3.2] ──▶ 7.0 ──▶ 7.1 (B0)
   sofa 2.0.19 ─────────────────────────┘         │
                          media surfer 3.1.7 ─────┴──▶
```

---

## Port checklist

### Swap

- [ ] Remove `gem 'comfortable_mexican_sofa', '~> 2.0.0'` from `Gemfile`
- [ ] Add `gem 'comfortable_media_surfer', '~> 3.1'`
- [ ] Remove `tinymce-rails` and `config.tinymce.install = :compile` (`config/application.rb:40`) — confirm nothing else uses TinyMCE first
- [ ] Run the engine's pending migrations (incl. Markdown snippets, 3.1.2)
- [ ] Confirm no `comfy_cms_*` table is renamed or dropped — **take a DB snapshot before running migrations**

### Port our customisations

- [ ] `comfy_patching.rb` — re-verify each `class_eval` against 3.1.7 internals; `content_tokens` is the one most likely to have moved
- [ ] `lib/cms_tags/categories.rb` — re-register against the current tag API
- [ ] Custom category models — confirm associations and `accepts_nested_attributes_for` still resolve
- [ ] Exporter override — re-verify against the current exporter
- [ ] `searchable_*` models — confirm ES indexing still picks up fragments

### Verify (B3)

- [ ] `/admin` loads without errors
- [ ] Login works
- [ ] List / create / edit a CMS page
- [ ] **Redactor** editor loads and saves content
- [ ] Image / file upload works (ActiveStorage — already S3 in staging/production)
- [ ] Category assignment (topics / types) works on pages and layouts
- [ ] Public CMS page rendering — no `cms_fragment_render` errors
- [ ] Custom `categories` CMS tag renders on a live layout
- [ ] `rake comfy:cms_seeds:import` completes
- [ ] `CmsTransfer` / `SyncSeeds` round-trip to S3 works
- [ ] CMS content still appears in site search (Elasticsearch)

### Content sanity

Page content is stored as fragments rather than editor-specific markup, so the TinyMCE → Redactor switch should not damage it. Verify anyway:

- [ ] Spot-check the richest CMS pages (resource pages, news, equity, thematic areas) before and after
- [ ] Confirm no HTML is stripped or re-escaped on first save through Redactor

---

## B3 milestone definition

B3 is satisfied when, on the upgrade branch:

1. `/admin` loads and login works
2. A CMS page can be created and edited through the **Redactor** editor and saved
3. File / image upload works
4. At least one public CMS page renders correctly, including the custom `categories` tag
5. `rake comfy:cms_seeds:import` completes without errors

---

## Open questions

- **Encore precedent** — Encore has already done the sofa → Media Surfer move. Ask Leo for notes on the custom-fragment/tag port and the admin asset pipeline; this could cut the estimate materially.
- Whether Media Surfer's admin assets work under Sprockets or force a partial Propshaft move (see above).

---

## Exit criteria

- `comfortable_media_surfer ~> 3.1` in the Gemfile, `comfortable_mexican_sofa` removed
- `tinymce-rails` removed
- All customisations in the table above ported and verified
- B3 checklist passes on staging
- Admin asset pipeline decision recorded and communicated to the frontend team
