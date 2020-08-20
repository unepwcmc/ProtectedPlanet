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
  name: 'AmChartLine',

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

  mounted() {
    this.createChart()
  },

  methods: {
    createChart () {
      am4core.options.autoSetClassName = true
      
      const chart = am4core.create("chartdiv", am4charts.XYChart)
      chart.data = this.data.datapoints
      chart.paddingTop = 70
      chart.paddingRight = 40
      chart.paddingLeft = -20
      chart.background.fill = this.chartBackgroundColour

      let yearAxis = chart.xAxes.push(new am4charts.DateAxis())
      yearAxis.renderer.grid.template.disabled = true
      yearAxis.renderer.line.strokeOpacity = 1
      yearAxis.renderer.line.strokeWidth = 1
      yearAxis.renderer.line.stroke = am4core.color("#c8c8c8")
      yearAxis.renderer.minGridDistance = 50
      yearAxis.renderer.ticks.template.disabled = false;
      yearAxis.renderer.ticks.template.strokeOpacity = 1;
      yearAxis.renderer.ticks.template.stroke = am4core.color("#c8c8c8");
      yearAxis.renderer.ticks.template.length = 6;

      let axis = chart.yAxes.push(new am4charts.ValueAxis())
      axis.title.text = `[bold]${this.data.units}[/]`
      axis.title.rotation = 0
      axis.title.valign = "top"
      axis.title.dy = -50
      axis.title.dx = 40
      axis.renderer.grid.template.disabled = true
      axis.renderer.line.strokeOpacity = 1
      axis.renderer.line.strokeWidth = 1
      axis.renderer.line.stroke = am4core.color("#c8c8c8")

      let series = chart.series.push(new am4charts.LineSeries())
      series.dataFields.valueY = "value"
      series.dataFields.dateX = "year"
      series.name = this.data.title
      series.stroke = am4core.color("#65C9B2")
      series.strokeWidth = 3
      series.yAxis = axis

      if(this.dots) {
        let bullet = series.bullets.push(new am4charts.CircleBullet());
        bullet.fill = am4core.color("#65C9B2")
      }

      const legend = chart.legend = new am4charts.Legend()
      legend.maxWidth = undefined
    }
  }
}
</script>