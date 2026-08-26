// The chart colours amCharts needs. It renders to canvas/SVG and inherits no
// page CSS, so these have to be literals handed to am5.color() — they can't come
// from a class. Their counterparts for everything CSS *can* style live in the
// chart @theme block in styles/tailwind.css; keep the two in step.

// The palette, in the same order as --color-theme-chart-1..12.
export const CHART_PALETTE = [
  '#64BAD9', '#A54897', '#65C9B2', '#5F81CB', '#FAA51B', '#EF5F6C',
  '#151617', '#71A22B', '#F5F58A', '#EF266C', '#1A4D9F', '#E57133'
]

// First 3 of CHART_PALETTE, kept separate since AmChartMultiline only ever has
// up to 3 line series (national/ABNJ/global).
export const CHART_LINE_COLOURS = CHART_PALETTE.slice(0, 3)

// Axis lines and ticks (--color-theme-grey-light), slice spacers, and tooltips.
export const CHART_AXIS_COLOUR = '#c8c8c8'
export const CHART_SURFACE_COLOUR = '#ffffff'
export const CHART_TOOLTIP_COLOUR = '#000000'
export const CHART_TOOLTIP_TEXT_COLOUR = '#ffffff'

// The `tw-shared-chart-theme-*` class (styles/shared/themes.css) for a zero-based
// series index, wrapping round when a chart has more series than colours.
export function chartThemeClass(index: number): string {
  return `tw-shared-chart-theme-${(index % CHART_PALETTE.length) + 1}`
}

// amCharts5 renders to SVG/canvas and inherits no page CSS, so the body font
// must be set explicitly on every chart text element.
export const CHART_FONT_FAMILY = 'Hind Siliguri, sans-serif'
