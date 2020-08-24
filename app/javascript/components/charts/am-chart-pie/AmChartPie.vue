<template>
  <div class="am-chart--pie">
    <div class="chart__chart">
      <div 
        class="chart__svg"
        :id="id"
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
    id: {
      required: true,
      type: String
    },
    spacers: {
      default: false,
      type: Boolean
    }
  },

  date () {
    return {
      chart: {},
      pieSeries: {}
    }
  },

  mounted () {
    this.createChart()
  },

  methods: {
    createChart () {
      this.chart = am4core.create(this.id, am4charts.PieChart);
      this.chart.data = this.dataset
      this.chart.radius = am4core.percent(90)

      this.createDataFields ()
      this.removeActiveState()
      this.removeHoverState()
      this.removeLabels()
      this.setPieColours()
      this.setTooltips()

      if(this.spacers) { this.createSpacers() }
      if(this.doughnut) { this.createDoughnutShape() }
    },

    createDataFields () {
      this.pieSeries = this.chart.series.push(new am4charts.PieSeries())
      this.pieSeries.dataFields.id = 'id'
      this.pieSeries.dataFields.category = 'title'
      this.pieSeries.dataFields.value = 'value'
    },

    createDoughnutShape () {
      this.chart.innerRadius = am4core.percent(50)
    },

    createSpacers () {
      this.pieSeries.slices.template.stroke = am4core.color('#ffffff')
      this.pieSeries.slices.template.strokeWidth = 2
      this.pieSeries.slices.template.strokeOpacity = 1
    },

    removeActiveState () {
      const activeState = this.pieSeries.slices.template.states.getKey('active')
      activeState.properties.shiftRadius = 0
    },

    removeHoverState () {
      let hoverState = this.pieSeries.slices.template.states.getKey('hover')
      hoverState.properties.scale = 1
    },

    removeLabels () {
      this.pieSeries.labels.template.disabled = true
      this.pieSeries.ticks.template.disabled = true
    },

    setPieColours () {
    //must match $theme-chart in settings.scss
      this.pieSeries.colors.list = [
        am4core.color('#64BAD9'),
        am4core.color('#A54897'),
        am4core.color('#65C9B2'),
        am4core.color('#5F81CB'),
        am4core.color('#FAA51B'),
        am4core.color('#EF5F6C'),
        am4core.color('#151617'),
        am4core.color('#71A22B'),
        am4core.color('#F5F58A'),
        am4core.color('#EF266C'),
        am4core.color('#1A4D9F'),
        am4core.color('#E57133')
      ]
    },

    setTooltips () {
      this.pieSeries.slices.template.tooltipText = `{id}. [bold]{category}[/] {value.value}, {value.percent.formatNumber('#.#')}%`
  
      this.pieSeries.tooltip.getFillFromObject = false
      this.pieSeries.tooltip.background.fill = am4core.color('#000000')
      this.pieSeries.tooltip.background.stroke = am4core.color('#000000')
      this.pieSeries.tooltip.label.fontSize = 18
      this.pieSeries.tooltip.label.padding(0,6,6,6)
      this.pieSeries.tooltip.label.textAlign = 'middle'
    }
  }
}
</script>