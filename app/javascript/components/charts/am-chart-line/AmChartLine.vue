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
    data: {
      required: true,
      type: Array // [{ year: Number, count: Number, area: Number}]
    }
  },

  mounted() {
    this.createChart()
  },

  methods: {
    createChart () {
      am4core.options.autoSetClassName = true
      
      const chart = am4core.create("chartdiv", am4charts.XYChart)

      chart.data = this.data
      chart.paddingTop = 70
      chart.paddingRight = -70
      chart.paddingLeft = -40

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

      let countAxis = chart.yAxes.push(new am4charts.ValueAxis())
      countAxis.title.text = "[bold]Number[/]"
      countAxis.title.rotation = 0
      countAxis.title.valign = "top"
      countAxis.title.dy = -50
      countAxis.title.dx = 60
      countAxis.renderer.grid.template.disabled = true
      countAxis.renderer.line.strokeOpacity = 1
      countAxis.renderer.line.strokeWidth = 1
      countAxis.renderer.line.stroke = am4core.color("#c8c8c8")

      let areaAxis = chart.yAxes.push(new am4charts.ValueAxis())
      areaAxis.renderer.opposite = true
      areaAxis.title.text = "[bold]Area (km2)[/]"
      areaAxis.title.rotation = 0
      areaAxis.title.valign = "top"
      areaAxis.title.dy = -50
      areaAxis.title.dx = -78
      areaAxis.renderer.grid.template.disabled = true
      areaAxis.renderer.line.strokeOpacity = 1
      areaAxis.renderer.line.strokeWidth = 1
      areaAxis.renderer.line.stroke = am4core.color("#c8c8c8")

      var series = chart.series.push(new am4charts.LineSeries())
      series.dataFields.valueY = "count"
      series.dataFields.dateX = "year"
      series.name = "Number of Protected Areas"
      series.stroke = am4core.color("#65C9B2")
      series.strokeWidth = 3
      series.yAxis = countAxis
      
      var series2 = chart.series.push(new am4charts.LineSeries())
      series2.dataFields.valueY = "area"
      series2.dataFields.dateX = "year"
      series2.name = "Total Area in (km2)"
      series2.strokeWidth = 3
      series2.yAxis = areaAxis

      const legend = chart.legend = new am4charts.Legend()
      legend.maxWidth = undefined
    }
  }
}
</script>