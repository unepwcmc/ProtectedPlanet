<template>
  <div class="ct-am-chart-multiline">
    <div
      ref="chartEl"
      class="ct-am-chart-multiline__chart"
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import * as am5 from '@amcharts/amcharts5'
import * as am5xy from '@amcharts/amcharts5/xy'
import { CHART_FONT_FAMILY, LINE_COLOURS } from '@/constants/charts'
import type { AmChartMultilineProps } from '@/types/backend'

type AmChartMultiline = AmChartMultilineProps
const props = withDefaults(defineProps<AmChartMultiline>(), {
  chartBackgroundColour: '#ffffff',
  dots: false
})

const chartEl = ref<HTMLElement | null>(null)
let root: am5.Root | null = null

onMounted(createChart)
onUnmounted(() => root?.dispose())

function createChart() {
  if (!chartEl.value) return

  root = am5.Root.new(chartEl.value)
  root.setThemes([])

  const chart = root.container.children.push(am5xy.XYChart.new(root, {
    layout: root.verticalLayout,
    paddingTop: 70,
    paddingRight: 20,
    paddingLeft: 10,
    paddingBottom: 20
  }))
  chart.set('background', am5.Rectangle.new(root, {
    fill: am5.color(props.chartBackgroundColour),
    fillOpacity: 1
  }))

  // Data comes from a yearly CSV (Thematic::MarineController#marine_growth_datapoints_from_csv),
  // so a fixed 1-year base interval is correct for this chart's only real caller.
  const data = props.data.datapoints.map(datapoint => ({
    ...datapoint,
    x: new Date(datapoint.x).getTime()
  }))

  const yAxis = createAxes(chart)
  createSeries(chart, yAxis, data)
  createLegend(chart)
}

function createAxes(chart: am5xy.XYChart) {
  const xAxis = chart.xAxes.push(am5xy.DateAxis.new(root!, {
    baseInterval: { timeUnit: 'year', count: 1 },
    renderer: am5xy.AxisRendererX.new(root!, { minGridDistance: 50 })
  }))
  const xRenderer = xAxis.get('renderer')
  xRenderer.grid.template.set('visible', false)
  xRenderer.setAll({ strokeOpacity: 1, strokeWidth: 1, stroke: am5.color('#c8c8c8') })
  xRenderer.ticks.template.setAll({
    visible: true,
    strokeOpacity: 1,
    stroke: am5.color('#c8c8c8'),
    length: 6
  })
  xRenderer.labels.template.setAll({ fontFamily: CHART_FONT_FAMILY, paddingTop: 10 })

  const yAxis = chart.yAxes.push(am5xy.ValueAxis.new(root!, {
    renderer: am5xy.AxisRendererY.new(root!, {})
  }))
  const yRenderer = yAxis.get('renderer')
  yRenderer.grid.template.set('visible', false)
  yRenderer.setAll({
    strokeOpacity: 1,
    strokeWidth: 1,
    stroke: am5.color('#c8c8c8')
  })
  yRenderer.labels.template.setAll({ fontFamily: CHART_FONT_FAMILY, paddingRight: 4 })

  yAxis.children.unshift(am5.Label.new(root!, {
    text: `[bold]${props.data.units}[/]`,
    fontFamily: CHART_FONT_FAMILY,
    fontSize: 14,
    position: 'absolute',
    x: am5.p0,
    centerY: am5.p100,
    dy: -10,
    dx: 40
  }))

  return yAxis
}

function createSeries(chart: am5xy.XYChart, yAxis: am5xy.ValueAxis<am5xy.AxisRenderer>, data: { x: number }[]) {
  const totalSeries = Object.keys(props.data.datapoints[0] ?? {}).length - 1

  for (let i = 0; i < totalSeries; i++) {
    const fieldName = `${i + 1}`
    const series = chart.series.push(am5xy.LineSeries.new(root!, {
      name: props.data.legend[i],
      xAxis: chart.xAxes.getIndex(0)!,
      yAxis,
      valueXField: 'x',
      valueYField: fieldName,
      stroke: am5.color(LINE_COLOURS[i]),
      fill: am5.color(LINE_COLOURS[i])
    }))
    series.strokes.template.set('strokeWidth', 4)
    series.data.setAll(data)

    if (props.dots) createDots(series, i)
  }
}

function createDots(series: am5xy.LineSeries, index: number) {
  series.bullets.push(() => am5.Bullet.new(root!, {
    sprite: am5.Circle.new(root!, {
      radius: 6,
      fill: am5.color(LINE_COLOURS[index])
    })
  }))
}

function createLegend(chart: am5xy.XYChart) {
  const legend = chart.children.push(am5.Legend.new(root!, {
    x: am5.percent(25),
    y: am5.percent(96),
    layout: root!.horizontalLayout
  }))
  legend.labels.template.setAll({ fontFamily: CHART_FONT_FAMILY })
  legend.data.setAll(chart.series.values)
}
</script>

<style scoped lang="css">
@reference "tailwindcss";

.ct-am-chart-multiline {
  @apply overflow-x-auto overflow-y-hidden md:overflow-hidden;
}

.ct-am-chart-multiline__chart {
  @apply h-101.25 min-w-162.5 md:w-full md:min-w-0;
}
</style>
