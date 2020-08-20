

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

  mounted() {
    this.createChart()
  },

  methods: {
    createChart () {
      am4core.options.autoSetClassName = true
      
      let chart = AmCharts.makeChart("chartdiv", this.data)
    }
  }
}
</script>