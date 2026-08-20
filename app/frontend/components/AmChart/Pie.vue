<template>
  <div class="ct-am-chart-pie">
    <div
      ref="chartEl"
      class="ct-am-chart-pie__svg"
    />
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted, ref, watch } from 'vue'
import * as am5 from '@amcharts/amcharts5'
import * as am5percent from '@amcharts/amcharts5/percent'
import { PIE_COLOURS } from '@/constants/charts'
import { registerPendingRender } from '@/lib/pdfReady'
import type { AmChartPieProps } from '@/types/backend'

type AmChartPie = AmChartPieProps
const props = withDefaults(defineProps<AmChartPie>(), {
  doughnut: false,
  spacers: false
})

const chartEl = ref<HTMLElement | null>(null)
let root: am5.Root | null = null
let pieSeries: am5percent.PieSeries | null = null

// amCharts draws the actual slices asynchronously (its own render tick, not
// synchronously inside createChart()) - hold the PDF rasterizer's readiness
// flag open until that first draw genuinely lands. See pdfReady.ts.
const markChartRenderDone = registerPendingRender()

onMounted(createChart)
onUnmounted(() => root?.dispose())

watch(() => props.dataset, (dataset) => {
  pieSeries?.data.setAll(dataset)
})

function createChart() {
  if (!chartEl.value) {
    markChartRenderDone()
    return
  }

  root = am5.Root.new(chartEl.value)
  root.setThemes([])

  const chart = root.container.children.push(am5percent.PieChart.new(root, {
    radius: am5.percent(90),
    innerRadius: props.doughnut ? am5.percent(50) : 0
  }))

  pieSeries = chart.series.push(am5percent.PieSeries.new(root, {
    categoryField: 'title',
    valueField: 'value'
  }))
  // Fires once amCharts has processed `dataset` into actual slices - the real
  // "chart is visually drawn" signal, as opposed to this function returning.
  pieSeries.events.once('datavalidated', markChartRenderDone)
  pieSeries.data.setAll(props.dataset)

  removeActiveState()
  removeHoverState()
  removeLabels()
  setPieColours()
  setTooltip()

  if (props.spacers) createSpacers()
}

function removeActiveState() {
  pieSeries!.slices.template.states.create('active', { shiftRadius: 0 })
}

function removeHoverState() {
  pieSeries!.slices.template.states.create('hover', { scale: 1 })
}

function removeLabels() {
  pieSeries!.labels.template.set('forceHidden', true)
  pieSeries!.ticks.template.set('forceHidden', true)
}

function setPieColours() {
  pieSeries!.set('colors', am5.ColorSet.new(root!, {
    colors: PIE_COLOURS.map(colour => am5.color(colour))
  }))
}

function createSpacers() {
  pieSeries!.slices.template.setAll({
    stroke: am5.color('#ffffff'),
    strokeWidth: 2,
    strokeOpacity: 1
  })
}

function setTooltip() {
  pieSeries!.slices.template.set(
    'tooltipText',
    '{id}. [bold]{category}[/] {value}, {valuePercentTotal.formatNumber(\'#.#\')}%'
  )

  const tooltip = am5.Tooltip.new(root!, { getFillFromSprite: false, autoTextColor: false })
  tooltip.get('background')!.setAll({
    fill: am5.color('#000000'),
    stroke: am5.color('#000000')
  })
  tooltip.label.setAll({
    fill: am5.color('#ffffff'),
    fontSize: 18,
    textAlign: 'center',
    paddingTop: 0,
    paddingRight: 6,
    paddingBottom: 6,
    paddingLeft: 6
  })

  pieSeries!.set('tooltip', tooltip)
}
</script>

<style scoped lang="css">
@reference "#importtailwindcss";

.ct-am-chart-pie__svg {
  @apply h-70;
}
</style>
