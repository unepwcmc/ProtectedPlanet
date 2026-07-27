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
import * as am4core from '@amcharts/amcharts4/core'
import * as am4charts from '@amcharts/amcharts4/charts'
import { LINE_COLOURS } from '@/constants/charts'
import type { AmChartMultilineProps } from '@/types/backend'

type AmChartMultiline = AmChartMultilineProps
const props = withDefaults(defineProps<AmChartMultiline>(), {
  chartBackgroundColour: '#ffffff',
  dots: false
})

const chartEl = ref<HTMLElement | null>(null)
let chart: am4charts.XYChart | null = null

onMounted(createChart)
onUnmounted(() => chart?.dispose())

function createChart() {
  if (!chartEl.value) return

  am4core.options.autoSetClassName = true

  chart = am4core.create(chartEl.value, am4charts.XYChart)
  chart.data = props.data.datapoints
  chart.paddingTop = 70
  chart.paddingRight = 40
  chart.paddingLeft = -20
  chart.background.fill = am4core.color(props.chartBackgroundColour)

  const yAxis = createAxis(chart)
  createSeries(chart, yAxis)
  createLegend(chart)
}

function createAxis(chart: am4charts.XYChart) {
  const xAxis = chart.xAxes.push(new am4charts.DateAxis())
  xAxis.renderer.grid.template.disabled = true
  xAxis.renderer.line.strokeOpacity = 1
  xAxis.renderer.line.strokeWidth = 1
  xAxis.renderer.line.stroke = am4core.color('#c8c8c8')
  xAxis.renderer.minGridDistance = 50
  xAxis.renderer.ticks.template.disabled = false
  xAxis.renderer.ticks.template.strokeOpacity = 1
  xAxis.renderer.ticks.template.stroke = am4core.color('#c8c8c8')
  xAxis.renderer.ticks.template.length = 6

  const yAxis = chart.yAxes.push(new am4charts.ValueAxis())
  yAxis.title.text = `[bold]${props.data.units}[/]`
  yAxis.title.rotation = 0
  yAxis.title.valign = 'top'
  yAxis.title.dy = -50
  yAxis.title.dx = 40
  yAxis.renderer.grid.template.disabled = true
  yAxis.renderer.line.strokeOpacity = 1
  yAxis.renderer.line.strokeWidth = 1
  yAxis.renderer.line.stroke = am4core.color('#c8c8c8')

  return yAxis
}

function createSeries(chart: am4charts.XYChart, yAxis: am4charts.ValueAxis) {
  const totalSeries = Object.keys(props.data.datapoints[0] ?? {}).length - 1

  for (let i = 0; i < totalSeries; i++) {
    const series = chart.series.push(new am4charts.LineSeries())
    series.dataFields.valueY = `${i + 1}`
    series.dataFields.dateX = 'x'
    series.name = props.data.legend[i]
    series.stroke = am4core.color(LINE_COLOURS[i])
    series.strokeWidth = 3
    series.yAxis = yAxis

    if (props.dots) createDots(series, i)
  }
}

function createDots(series: am4charts.LineSeries, index: number) {
  const bullet = series.bullets.push(new am4charts.CircleBullet())
  bullet.fill = am4core.color(LINE_COLOURS[index])
}

function createLegend(chart: am4charts.XYChart) {
  // No maxWidth override — am4charts.Legend has no default width cap to undo.
  const legend = new am4charts.Legend()
  chart.legend = legend
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
