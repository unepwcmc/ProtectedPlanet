<template>
  <div class="am-chart--pie">
    <div class="chart__chart">
      <div 
        class="chart__svg"
        id="chart-pie"
      />
    </div>
  </div>
</template>

<script>
import * as am4core from "@amcharts/amcharts4/core"
import * as am4charts from "@amcharts/amcharts4/charts"

export default {
  name: 'AmChartPie',

  props: {
    dataset: {
      required: true,
      type: Array // [{ title: String, value: Number }]
    },
    doughnut: {
      default: false,
      type: Boolean
    },
    spacers: {
      default: false,
      type: Boolean
    }
  },

  mounted () {
    this.createChart()
  },

  methods: {
    createChart () {
      const chart = am4core.create('chart-pie', am4charts.PieChart);
      chart.data = this.dataset
      chart.radius = am4core.percent(90)

      if(this.doughnut) {
        chart.innerRadius = am4core.percent(50)
      }

      const pieSeries = chart.series.push(new am4charts.PieSeries())
      pieSeries.dataFields.value = 'value'
      pieSeries.dataFields.category = 'title'
      
      if(this.spacers) {
        pieSeries.slices.template.stroke = am4core.color('#ffffff')
        pieSeries.slices.template.strokeWidth = 2
        pieSeries.slices.template.strokeOpacity = 1
      }

      pieSeries.labels.template.disabled = true
      pieSeries.ticks.template.disabled = true

      pieSeries.tooltip.getFillFromObject = false
      pieSeries.tooltip.background.fill = am4core.color('#000000')
      pieSeries.tooltip.background.stroke = am4core.color('#000000')
      pieSeries.tooltip.label.fontSize = 18
      pieSeries.tooltip.label.fontWeight = 'bold'
      pieSeries.tooltip.label.textAlign = 'middle'

      const activeState = pieSeries.slices.template.states.getKey('active')
      activeState.properties.shiftRadius = 0

      let hoverState = pieSeries.slices.template.states.getKey('hover')
      hoverState.properties.scale = 1
    }
  }
}
</script>