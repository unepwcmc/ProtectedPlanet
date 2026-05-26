# 06 — Charts and visualisations

| | |
|---|---|
| **Estimate** | 4–6 weeks · ~1–1.5 months |
| **Depends on** | [03](./03-end-runtime-compilation.md), [04](./04-vue3-and-state.md) |
| **Blocks** | Stats page sign-off |

[← Back to overview](./README.md)

---

## Goal

All charts render under Vue 3. amCharts upgraded. Country/region/marine stats match current production visuals.

---

## Current stack

| Type | Components / files |
|------|-------------------|
| amCharts 4 | `AmChartLine`, `AmChartMultiline`, `AmChartPie` |
| Custom SVG/CSS | `ChartBar`, `ChartRowPa`, `ChartRowStacked`, `ChartTreemap`, `ChartSunburst`, `ChartDial`, … |
| D3 | `d3@5` in package.json (audit actual usage) |
| Data from Rails | Presenters + ERB partials under `app/views/partials/charts/`, `partials/stats/` |

---

## Tasks

### amCharts 4 → 5

- [ ] Inventory each amCharts SFC and its options/data shape.
- [ ] Port per [amCharts v5 docs](https://www.amcharts.com/docs/v5/); one chart type at a time with before/after screenshots.
- [ ] Dispose charts on unmount (memory leaks were common in v4).

### Custom charts

- [ ] List which stats partials use which component (grep `chart-` in `app/views`).
- [ ] Group into entrypoints per [14](./14-architecture-and-design.md): e.g. `stats-country.ts` with `StatsPage.vue` wrapper per page type.
- [ ] Fix ERB prop binding (`:` for numbers/booleans/objects).

### D3

- [ ] Grep `import.*d3` — migrate only if still used; else remove dependency.

### Visual regression

- [ ] Country show page — overview + tabs (WDPA / OECM if applicable).
- [ ] Region show page.
- [ ] Marine index + sections.
- [ ] Target 11 dashboard (`chart-dial`).
- [ ] Protected area show — stats tabs.

---

## Exit criteria

- No `@amcharts/amcharts4` imports.
- Product/NC team sign-off on key stats pages (screenshot comparison doc).
- No chart-related console errors on staging.

---

## Reference

- [amCharts 5 documentation](https://www.amcharts.com/docs/v5/)
- [14 — Architecture](./14-architecture-and-design.md) — stats entrypoint grouping
