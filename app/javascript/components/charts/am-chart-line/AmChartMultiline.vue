<template>
  <div class="am-chart--line">
    <div class="chart__wrapper-ie11">
      <div class="chart__scrollable">
        <div class="chart__chart">
          <div 
            class="chart__svg"
            id="chartdiv"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import * as am4core from "@amcharts/amcharts4/core"
import * as am4charts from "@amcharts/amcharts4/charts"
import am4themes_animated from "@amcharts/amcharts4/themes/animated"

export default {
  name: 'AmChartMultiline',

  props: {
    chartBackgroundColour: {
      default: '#ffffff',
      type: String
    },
    data: {
      required: true,
      type: Object // { title: String units: String, datapoints: { year: Number, value: Number }}
    },
    dots: {
      default: false,
      type: Boolean
    }
  },

  data () {
    return {
      chart: null,
      colours: ['#64BAD9','#A54897','#65C9B2'], // see $theme-chart in settings.scss
      totalSeries: 0,
      yAxis: null
    }
  },

  mounted() {
    this.chartInit()
  },

  methods: {
    chartInit() {
      this.totalSeries = Object.keys(this.data.datapoints[0]).length - 1

      this.createChart()
      this.createAxis()
      this.createSeries()
      this.createLegend()
    },

    createAxis () {
      let xAxis = this.chart.xAxes.push(new am4charts.DateAxis())
      xAxis.renderer.grid.template.disabled = true
      xAxis.renderer.line.strokeOpacity = 1
      xAxis.renderer.line.strokeWidth = 1
      xAxis.renderer.line.stroke = am4core.color("#c8c8c8")
      xAxis.renderer.minGridDistance = 50
      xAxis.renderer.ticks.template.disabled = false;
      xAxis.renderer.ticks.template.strokeOpacity = 1;
      xAxis.renderer.ticks.template.stroke = am4core.color("#c8c8c8");
      xAxis.renderer.ticks.template.length = 6;

      this.yAxis = this.chart.yAxes.push(new am4charts.ValueAxis())
      this.yAxis.title.text = `[bold]${this.data.units}[/]`
      this.yAxis.title.rotation = 0
      this.yAxis.title.valign = "top"
      this.yAxis.title.dy = -50
      this.yAxis.title.dx = 40
      this.yAxis.renderer.grid.template.disabled = true
      this.yAxis.renderer.line.strokeOpacity = 1
      this.yAxis.renderer.line.strokeWidth = 1
      this.yAxis.renderer.line.stroke = am4core.color("#c8c8c8")
    },

    createChart () {
      am4core.options.autoSetClassName = true
      
      this.chart = am4core.create("chartdiv", am4charts.XYChart)
      this.chart.data = this.data.datapoints
      this.chart.paddingTop = 70
      this.chart.paddingRight = 40
      this.chart.paddingLeft = -20
      this.chart.background.fill = this.chartBackgroundColour
    },

    createDots (series, i) {
      const bullet = series.bullets.push(new am4charts.CircleBullet());
      bullet.fill = am4core.color(this.colours[i])
    },

    createLegend () {
      const legend = this.chart.legend = new am4charts.Legend()
      legend.maxWidth = undefined
    },

    createSeries () {
      for(let i = 0; i < this.totalSeries; i++) {
        const series = this.chart.series.push(new am4charts.LineSeries())
        series.dataFields.valueY = i+1
        series.dataFields.dateX = "x"
        series.name = this.data.legend[i]
        series.stroke = am4core.color(this.colours[i])
        series.strokeWidth = 3
        series.yAxis = this.yAxis 

        if(this.dots) { this.createDots(series, i) }
      }
    }
  }
}
</script>