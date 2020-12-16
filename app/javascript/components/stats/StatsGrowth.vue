<template>
  <div class="card--stats-growth-chart">
    <div class="card__chart-wrapper">
      <h2>{{ title }}</h2>

      <am-chart-line 
        :data="chart"
      >
      </am-chart-line>
      
      <p class="text--small">{{ smallprint }}</p>
    </div>
  </div>
</template>

<script>
import AmChartLine from '../charts/am-chart-line/AmChartLine'

export default {
  name: 'StatsGrowth',

  components: {
    AmChartLine
  },

  props: {
    chart: {
      required: true,
      type: Object
    },
    smallprint: {
      required: true,
      type: String
    },
    title: {
      required: true,
      type: String
    }
  }
}
</script>