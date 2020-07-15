<template>
  <div :class="['chart--row-stacked', themeClass]">
    <h3 v-if="title" class="chart__title">{{ title }}</h3>

    <ul class="chart__chart ul-unstyled flex">
      <li v-for="(row, index) in rows" :key="`row-${index}`" class="chart__bar flex flex-v-center" :class="themeClass" :style="{ width: row.percent + '%' }">
        <span v-if="row.percent > 0" class="chart__percent">{{ row.percent}}%</span>
      </li>
    </ul>
    
    <!-- <chart-legend v-if="legend" :rows="legend" :theme="theme" class="chart__legend"></chart-legend> -->
  </div>
</template>

<script>
  // import ChartLegend from './ChartLegend'

  export default {
    name: 'chart-row-stacked',

    // components: { ChartLegend },

    props: {
      title: String,
      theme: String,
      rows: {
        type: Array, //[{ percent: Number }]
        required: true
      },
      legend: {
        type: Array
      }
    },

    computed: {
      themeClass () {
        return `theme--${this.theme}`
      }
    }
  }
</script>