# 13 — Work while Rails is still on 5.2 (parallel track)

| | |
|---|---|
| **Use when** | Backend upgrading **5.2 → 7+** |
| **Design** | [14 — Architecture](./14-architecture-and-design.md) |
| **Vite** | Foundation **not blocked** — [02a](./02a-vite-spike-rails-5.md) |

[← Back to overview](./README.md) · [00 — Scope reference](./00-scope-and-backend-dependencies.md)

---

## Gates

| Gate | Rails | You can |
|------|-------|---------|
| **G0** | **5.2 (today)** | Track A + B + **Vite 2 foundation (2a)** |
| **G1** | **7.1+** | `vite_rails` 3.x, Vite 5, Vue 3 ([02b](./02-vite-on-rails-8.md#phase-2b--on-upgrade-branch-rails-71)) |
| **G2** | **8.0** | Same frontend; backend gem alignment |

---

## Track A — Do now on `main` (Rails 5.2)

### 1. Discovery ([01](./01-discovery-and-inventory.md))

- [ ] ERB ↔ component spreadsheet (include **CMS pattern A/B/C** per [README](./README.md#cms--frontend-important--read-before-phase-3))
- [ ] Entrypoint list per [14](./14-architecture-and-design.md)
- [ ] Props schemas for `frontend_mount` helper (design doc, no Rails 7 required)
- [ ] Document thematic/equity tab redesign (pattern B) before Rails 7

### 2. Vue 2 prep (Webpacker unchanged)

- [ ] Search areas: download inside `SearchAreas.vue` (remove ERB slot)
- [ ] Maps: reduce ERB `v-slot` complexity ([03](./03-end-runtime-compilation.md))
- [ ] Fix `:` bindings on chart/search ERB tags
- [ ] Extract map mixins → `.js` modules (step toward composables)

### 3. Comfy admin JS

- [ ] Coffee → JS ([12](./12-gemfile-frontend-dependencies.md))
- [ ] Smoke `/admin`

### 4. Styles audit

- [ ] SCSS inventory; CDN duplicates; `pdf.css` usage

### 5. Testing

- [ ] Vitest for pure helpers ([09](./09-testing-and-qa.md))
- [ ] Playwright URL smoke list

### 6. Vite foundation ([02a](./02a-vite-spike-rails-5.md)) — **in progress**

- [x] Spike: `vite_rails` 2.x, build, layout tags, Docker Node 12
- [ ] `frontend_mount` helper + entrypoints per page type
- [ ] Dual-bundler page matrix (Webpacker vs Vite)
- [ ] Optional: `bin/vite dev` in compose for HMR experiments

### 7. Local spikes **in this repo**

Optional experiments (no dependency on other WCMC apps):

- [ ] amCharts 5 API trial for one chart type
- [ ] Mapbox GL v2 or MapLibre bundle size + one PP style URL

Do **not** require Vue 3 or Vite 5 on 5.2 — use Webpacker for Vue 2 until G1.

---

## Track B — Integration backend (you)

| Task | Rails 5.2? |
|------|------------|
| Design `frontend_mount` + `json_escape` props ([14](./14-architecture-and-design.md)) | Yes |
| Document `VITE_*` credential names | Yes |
| `vite_rails` 2.x + `config/vite.json` + entrypoints | **Yes** ([02a](./02a-vite-spike-rails-5.md)) |
| Remove dead gems after audit ([12](./12-gemfile-frontend-dependencies.md)) | Yes |
| Docker Node 20 proposal (for B0 target) | Yes |
| `vite_rails` 3.x + `vite.config.ts` + Vue 3 plugin | **Upgrade branch only** |

---

## Track C — Blocked until G1 (target stack)

- `vite_rails` 3.x, Vite 5, `@vitejs/plugin-vue`, Vue 3 production bundles
- Webpacker removal — see [02b](./02-vite-on-rails-8.md#phase-2b--on-upgrade-branch-rails-71), phases 3–9

---

## Example 4-week schedule

| Week | You | Backend |
|------|-----|---------|
| 1 | Inventory + `frontend_mount` design | Rails 7 branch |
| 2 | SearchAreas slot fix + Comfy JS + Vite entrypoint #2 | Boot blockers |
| 3 | Map mixin extract + Vitest helpers | **B0** |
| 4 | `vite_rails` 3.x PR on upgrade branch | CI |

---

## PR labels

| Label | Merge target |
|-------|----------------|
| `prep-rails7` | `main` |
| `needs-rails-7` | upgrade branch |

---

## Exit criteria

- [ ] ≥3 prep PRs on `main`
- [x] Vite spike on 5.2 validated ([02a](./02a-vite-spike-rails-5.md))
- [ ] `frontend_mount` + ≥1 real entrypoint beyond spike
- [ ] Architecture [14](./14-architecture-and-design.md) agreed by team
