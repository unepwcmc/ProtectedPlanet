<template>
  <div class="card--stats-growth-chart">
    <div class="card__chart-wrapper">
      <h2>{{ data.title }}</h2>

      <am-chart-line 
        :data="data.chart"
      >
      </am-chart-line>
      
      <p class="text--small">{{ data.smallprint }}</p>
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
    data: {
      required: true,
      type: Object
    }
  }
}
</script>