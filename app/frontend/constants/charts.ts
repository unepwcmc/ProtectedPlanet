// Must match the chart theme colours in styles/shared/themes.css.
export const PIE_COLOURS = [
  '#64BAD9', '#A54897', '#65C9B2', '#5F81CB', '#FAA51B', '#EF5F6C',
  '#151617', '#71A22B', '#F5F58A', '#EF266C', '#1A4D9F', '#E57133'
]

// First 3 of PIE_COLOURS, kept separate since AmChartMultiline only ever has
// up to 3 line series (national/ABNJ/global).
export const LINE_COLOURS = ['#64BAD9', '#A54897', '#65C9B2']

// amCharts5 renders to SVG/canvas and inherits no page CSS, so the body font
// must be set explicitly on every chart text element.
export const CHART_FONT_FAMILY = 'Hind Siliguri, sans-serif'
