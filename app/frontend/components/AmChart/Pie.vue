<template>
  <div class="am-chart--pie chart__chart">
    <div
      ref="chartEl"
      class="chart__svg"
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch } from 'vue'
import * as am4core from '@amcharts/amcharts4/core'
import * as am4charts from '@amcharts/amcharts4/charts'
import { PIE_COLOURS } from '@/constants/charts'
import type { AmChartPieProps } from '@/types/backend'

type AmChartPie = AmChartPieProps
const props = withDefaults(defineProps<AmChartPie>(), {
  doughnut: false,
  spacers: false
})

const chartEl = ref<HTMLElement | null>(null)
let chart: am4charts.PieChart | null = null
let pieSeries: am4charts.PieSeries | null = null

onMounted(createChart)
onUnmounted(() => chart?.dispose())

watch(() => props.dataset, (dataset) => {
  if (chart) chart.data = dataset
})

function createChart() {
  if (!chartEl.value) return

  chart = am4core.create(chartEl.value, am4charts.PieChart)
  chart.data = props.dataset
  chart.radius = am4core.percent(90)

  pieSeries = chart.series.push(new am4charts.PieSeries())
  pieSeries.dataFields.id = 'id'
  pieSeries.dataFields.category = 'title'
  pieSeries.dataFields.value = 'value'

  removeActiveState()
  removeHoverState()
  removeLabels()
  setPieColours()
  setTooltip()

  if (props.spacers) createSpacers()
  if (props.doughnut) chart.innerRadius = am4core.percent(50)
}

function removeActiveState() {
  const activeState = pieSeries!.slices.template.states.getKey('active')
  activeState!.properties.shiftRadius = 0
}

function removeHoverState() {
  const hoverState = pieSeries!.slices.template.states.getKey('hover')
  hoverState!.properties.scale = 1
}

function removeLabels() {
  pieSeries!.labels.template.disabled = true
  pieSeries!.ticks.template.disabled = true
}

function setPieColours() {
  pieSeries!.colors.list = PIE_COLOURS.map(colour => am4core.color(colour))
}

function createSpacers() {
  pieSeries!.slices.template.stroke = am4core.color('#ffffff')
  pieSeries!.slices.template.strokeWidth = 2
  pieSeries!.slices.template.strokeOpacity = 1
}

function setTooltip() {
  pieSeries!.slices.template.tooltipText = '{id}. [bold]{category}[/] {value.value}, {value.percent.formatNumber(\'#.#\')}%'

  pieSeries!.tooltip!.getFillFromObject = false
  pieSeries!.tooltip!.background.fill = am4core.color('#000000')
  pieSeries!.tooltip!.background.stroke = am4core.color('#000000')
  pieSeries!.tooltip!.label.fontSize = 18
  pieSeries!.tooltip!.label.padding(0, 6, 6, 6)
  pieSeries!.tooltip!.label.textAlign = 'middle'
}
</script>
